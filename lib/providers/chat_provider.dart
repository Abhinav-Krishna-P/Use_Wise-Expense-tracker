import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_message_model.dart';
import '../models/expense_model.dart';
import '../models/spending_limit_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

enum ChatSpendingLimitIntentType {
  createOrUpdate,
  show,
  delete,
}

class ChatSpendingLimitIntent {
  final ChatSpendingLimitIntentType type;
  final String? category;
  final double? amount;
  final String? period;
  final bool deleteAll;
  final bool unsupportedPeriod;

  const ChatSpendingLimitIntent({
    required this.type,
    this.category,
    this.amount,
    this.period,
    this.deleteAll = false,
    this.unsupportedPeriod = false,
  });

  bool get needsCategory =>
      type != ChatSpendingLimitIntentType.show && !deleteAll && category == null;
  bool get needsAmount =>
      type == ChatSpendingLimitIntentType.createOrUpdate && amount == null;
  bool get needsPeriod =>
      type == ChatSpendingLimitIntentType.createOrUpdate && period == null;

  ChatSpendingLimitIntent copyWith({
    ChatSpendingLimitIntentType? type,
    String? category,
    double? amount,
    String? period,
    bool? deleteAll,
    bool? unsupportedPeriod,
  }) {
    return ChatSpendingLimitIntent(
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      deleteAll: deleteAll ?? this.deleteAll,
      unsupportedPeriod: unsupportedPeriod ?? this.unsupportedPeriod,
    );
  }
}

class ChatSpendingLimitResult {
  final String reply;
  final String action;
  final SpendingLimitConfig? config;

  const ChatSpendingLimitResult({
    required this.reply,
    this.action = 'spending_limits_show',
    this.config,
  });
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessageModel> _messages = [];
  bool _isLoading = false;

  String? _lastUid;
  ChatSpendingLimitIntent? _pendingSpendingLimitIntent;

  static final Map<String, String> _categoryAliases = {
    for (final category in AppTheme.categoryEmojis.keys) category.toLowerCase(): category,
    'bill': 'Bills',
    'bills': 'Bills',
    'grocery': 'Shopping',
    'groceries': 'Shopping',
    'medicine': 'Health',
    'medical': 'Health',
    'movie': 'Entertainment',
    'movies': 'Entertainment',
    'travel': 'Transport',
    'uber': 'Transport',
    'ola': 'Transport',
  };

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  /// Callbacks wired by ChatScreen to forward CRUD results to ExpenseProvider.
  Function(ExpenseModel)? onExpenseAdded;
  Function(ExpenseModel)? onExpenseUpdated;
  Function(String)? onExpenseDeleted;
  Future<ChatSpendingLimitResult> Function(ChatSpendingLimitIntent intent)?
      onSpendingLimitIntent;

  ChatProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final newUid = user?.uid;
      if (newUid != _lastUid) {
        _messages.clear();
        _isLoading = false;
        _lastUid = newUid;
        _pendingSpendingLimitIntent = null;
        notifyListeners();
      }
    });
  }

  // ── Text message ───────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    await _sendTextMessage(text.trim());
  }

  Future<void> updateExpenseCard(
    ExpenseModel expense, {
    required String description,
    required double amount,
  }) async {
    final trimmedDescription = description.trim();
    if (trimmedDescription.isEmpty || amount <= 0) return;

    try {
      final data = await ApiService.patch('/expenses/${expense.id}', {
        'description': trimmedDescription,
        'amount': amount,
      });
      final updated = ExpenseModel.fromJson(data['expense'] as Map<String, dynamic>);
      onExpenseUpdated?.call(updated);
      _syncExpenseMessage(updated, 'update');
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatProvider] updateExpenseCard error: $e');
      _insertError();
      notifyListeners();
    }
  }

  Future<void> _sendTextMessage(String text, {String? visibleText}) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: (visibleText ?? text).trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.insert(0, userMsg);
    _isLoading = true;
    notifyListeners();

    try {
      final handledLocally = await _tryHandleSpendingLimitMessage(text.trim());
      if (handledLocally) return;

      final data = await ApiService.post('/chat/message', {'message': text.trim()});
      _handleAiResponse(data);
    } catch (e) {
      debugPrint('[ChatProvider] sendMessage error: $e');
      _insertError();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Image message ──────────────────────────────────────────────────────────

  Future<void> sendImageMessage(XFile image, String? caption) async {
    final Uint8List bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? 'image/jpeg';

    final userMsg = ChatMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: caption ?? '',
      isUser: true,
      timestamp: DateTime.now(),
      imageBytes: bytes,
    );
    _messages.insert(0, userMsg);
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.postMultipart(
        '/chat/image',
        imageBytes: bytes,
        mimeType: mimeType,
        caption: caption,
      );
      _handleAiResponse(data);
    } catch (e) {
      debugPrint('[ChatProvider] sendImageMessage error: $e');
      _insertError();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<bool> _tryHandleSpendingLimitMessage(String text) async {
    final lower = text.toLowerCase().trim();

    if (_pendingSpendingLimitIntent != null &&
        RegExp(r'\b(cancel|stop|never mind|nevermind)\b').hasMatch(lower)) {
      _pendingSpendingLimitIntent = null;
      _insertAiReply('Okay, I cancelled that spending limit request.');
      return true;
    }

    final parsedIntent = _parseSpendingLimitIntent(text);
    if (parsedIntent == null && _pendingSpendingLimitIntent == null) {
      return false;
    }

    final intent = _mergeSpendingLimitIntent(
      _pendingSpendingLimitIntent,
      parsedIntent,
      text,
    );

    if (intent == null) return false;

    if (intent.unsupportedPeriod) {
      _pendingSpendingLimitIntent = null;
      _insertAiReply(
        'Spending limits currently support daily, weekly, or monthly periods.',
      );
      return true;
    }

    if (intent.needsCategory) {
      _pendingSpendingLimitIntent = intent;
      _insertAiReply('Which category should I use for this spending limit?');
      return true;
    }

    if (intent.needsAmount) {
      _pendingSpendingLimitIntent = intent;
      _insertAiReply('What amount should I set for this spending limit?');
      return true;
    }

    if (intent.needsPeriod) {
      _pendingSpendingLimitIntent = intent;
      _insertAiReply(
        'What time span should I use for this spending limit: daily, weekly, or monthly?',
      );
      return true;
    }

    if (onSpendingLimitIntent == null) {
      _pendingSpendingLimitIntent = null;
      _insertAiReply('Spending limit actions are not available right now.');
      return true;
    }

    _pendingSpendingLimitIntent = null;

    try {
      final result = await onSpendingLimitIntent!.call(intent);
      _insertAiReply(
        result.reply,
        action: result.action,
        spendingLimitConfig: result.config,
      );
    } catch (e) {
      debugPrint('[ChatProvider] spending limit intent error: $e');
      _insertAiReply(
        'Sorry, I could not update your spending limits right now. Please try again.',
      );
    }

    return true;
  }

  ChatSpendingLimitIntent? _parseSpendingLimitIntent(String text) {
    final lower = text.toLowerCase();
    final hasLimitKeyword = lower.contains('limit') || lower.contains('limits');

    if (!hasLimitKeyword) return null;

    final type = _detectSpendingLimitIntentType(lower);
    if (type == null) return null;

    return ChatSpendingLimitIntent(
      type: type,
      category: _extractCategory(lower),
      amount: _extractAmount(lower),
      period: _extractPeriod(lower),
      deleteAll: _extractDeleteAll(lower),
      unsupportedPeriod: _hasUnsupportedPeriod(lower),
    );
  }

  ChatSpendingLimitIntent? _mergeSpendingLimitIntent(
    ChatSpendingLimitIntent? pending,
    ChatSpendingLimitIntent? parsed,
    String text,
  ) {
    if (pending == null) return parsed;
    if (parsed != null && parsed.type != pending.type) return parsed;

    final lower = text.toLowerCase();
    return pending.copyWith(
      category: parsed?.category ?? _extractCategory(lower),
      amount: parsed?.amount ?? _extractAmount(lower),
      period: parsed?.period ?? _extractPeriod(lower),
      deleteAll: parsed?.deleteAll ?? _extractDeleteAll(lower),
      unsupportedPeriod:
          pending.unsupportedPeriod ||
          (parsed?.unsupportedPeriod ?? _hasUnsupportedPeriod(lower)),
    );
  }

  ChatSpendingLimitIntentType? _detectSpendingLimitIntentType(String lower) {
    if (RegExp(r'\b(show|list|view|display|what)\b').hasMatch(lower)) {
      return ChatSpendingLimitIntentType.show;
    }

    if (RegExp(r'\b(delete|remove|clear)\b').hasMatch(lower)) {
      return ChatSpendingLimitIntentType.delete;
    }

    if (RegExp(r'\b(create|set|add|update|edit|change|modify)\b').hasMatch(lower) ||
        RegExp(r'\b(limit of|limit for|cap of|cap for)\b').hasMatch(lower)) {
      return ChatSpendingLimitIntentType.createOrUpdate;
    }

    return null;
  }

  String? _extractCategory(String lower) {
    for (final entry in _categoryAliases.entries) {
      if (RegExp('\\b${RegExp.escape(entry.key)}\\b').hasMatch(lower)) {
        return entry.value;
      }
    }
    return null;
  }

  double? _extractAmount(String lower) {
    final directCurrencyMatch = RegExp(
      r'(?:₹|rs\.?|inr)\s*(\d+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (directCurrencyMatch != null) {
      return double.tryParse(directCurrencyMatch.group(1)!);
    }

    final reverseCurrencyMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:₹|rs\.?|inr)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (reverseCurrencyMatch != null) {
      return double.tryParse(reverseCurrencyMatch.group(1)!);
    }

    final genericAmountMatch = RegExp(r'\b(\d+(?:\.\d+)?)\b').firstMatch(lower);
    if (genericAmountMatch != null) {
      return double.tryParse(genericAmountMatch.group(1)!);
    }

    return null;
  }

  String? _extractPeriod(String lower) {
    if (RegExp(r'\b(today|daily|day)\b').hasMatch(lower)) {
      return 'daily';
    }
    if (RegExp(r'\b(week|weekly)\b').hasMatch(lower)) {
      return 'weekly';
    }
    if (RegExp(r'\b(month|monthly)\b').hasMatch(lower)) {
      return 'monthly';
    }
    return null;
  }

  bool _hasUnsupportedPeriod(String lower) {
    return RegExp(r'\b(year|yearly|annual|annually)\b').hasMatch(lower);
  }

  bool _extractDeleteAll(String lower) {
    return RegExp(r'\b(all|everything)\b').hasMatch(lower);
  }

  void _insertAiReply(
    String reply, {
    String action = 'none',
    SpendingLimitConfig? spendingLimitConfig,
  }) {
    final aiMsg = ChatMessageModel(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
      action: action,
      spendingLimitConfig: spendingLimitConfig,
    );
    _messages.insert(0, aiMsg);
  }

  void syncSpendingLimitMessages(
    SpendingLimitConfig? config, {
    String? text,
    String action = 'spending_limits_show',
  }) {
    final matches = <int>[];
    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final isSpendingLimitMessage =
          message.spendingLimitConfig != null || message.action.startsWith('spending_limits');
      if (isSpendingLimitMessage) {
        matches.add(i);
      }
    }

    if (matches.isEmpty) {
      if (text != null) {
        _insertAiReply(
          text,
          action: action,
          spendingLimitConfig: config,
        );
        notifyListeners();
      }
      return;
    }

    for (final index in matches) {
      _messages[index] = _messages[index].copyWith(
        text: text ?? _messages[index].text,
        action: action,
        spendingLimitConfig: config,
        clearSpendingLimitConfig: config == null,
      );
    }
    notifyListeners();
  }

  void _handleAiResponse(dynamic data) {
    final rawAction = data['action'] as String? ?? 'none';
    final rawExpense = data['expense'];
    final rawExpenses = data['expenses'];
    final expenses = rawExpenses is List
        ? rawExpenses
            .whereType<Map<String, dynamic>>()
            .map(ExpenseModel.fromJson)
            .toList()
        : <ExpenseModel>[];
    final expense = rawExpense != null && rawExpense is Map<String, dynamic>
        ? ExpenseModel.fromJson(rawExpense)
        : null;
    final hasExpensePayload = expense != null || expenses.isNotEmpty;
    final action = rawAction == 'none' && hasExpensePayload ? 'create' : rawAction;
    final reply = data['reply'] as String;
    final aiMsg = ChatMessageModel(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
      action: action,
      expense: expense ?? (expenses.isNotEmpty ? expenses.first : null),
      expenses: expenses,
    );
    _messages.insert(0, aiMsg);

    switch (action) {
      case 'create':
        final createdExpenses = expenses.isNotEmpty
            ? expenses
            : (expense != null ? [expense] : <ExpenseModel>[]);
        for (final item in createdExpenses) {
          onExpenseAdded?.call(item);
        }
        break;
      case 'update':
        if (expense != null) {
          onExpenseUpdated?.call(expense);
          _syncExpenseMessage(expense, action);
        }
        break;
      case 'delete':
        final deletedId = data['deletedExpenseId'] as String?;
        if (deletedId != null) {
          onExpenseDeleted?.call(deletedId);
          _removeExpenseMessage(deletedId);
        }
        break;
    }
  }

  Future<void> deleteExpenseCard(ExpenseModel expense) async {
    final aiMsg = ChatMessageModel(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: 'Deleted ${expense.description}.',
      isUser: false,
      timestamp: DateTime.now(),
    );

    try {
      await ApiService.delete('/expenses/${expense.id}');
      onExpenseDeleted?.call(expense.id);
      _removeExpenseMessage(expense.id);
      _messages.insert(0, aiMsg);
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatProvider] deleteExpenseCard error: $e');
      _insertError();
      notifyListeners();
    }
  }

  void _syncExpenseMessage(ExpenseModel expense, String action) {
    final matchingIndexes = <int>[];
    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final containsExpense = message.expense?.id == expense.id ||
          message.expenses.any((item) => item.id == expense.id);
      if (containsExpense) {
        matchingIndexes.add(i);
      }
    }

    if (matchingIndexes.isEmpty) return;

    final firstIndex = matchingIndexes.first;
    final currentMessage = _messages[firstIndex];
    final updatedExpenses = currentMessage.expenses.isNotEmpty
        ? currentMessage.expenses
            .map((item) => item.id == expense.id ? expense : item)
            .toList()
        : <ExpenseModel>[expense];

    _messages[firstIndex] = _messages[firstIndex].copyWith(
      expense: updatedExpenses.first,
      expenses: updatedExpenses,
      action: action,
      text: '',
    );

    for (final index in matchingIndexes.skip(1).toList().reversed) {
      _messages.removeAt(index);
    }
  }

  void _removeExpenseMessage(String expenseId) {
    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final filteredExpenses =
          message.expenses.where((item) => item.id != expenseId).toList();

      if (message.expense?.id == expenseId && filteredExpenses.isEmpty) {
        _messages.removeAt(i);
        i--;
        continue;
      }

      if (filteredExpenses.length != message.expenses.length) {
        _messages[i] = message.copyWith(
          expenses: filteredExpenses,
          expense: filteredExpenses.isNotEmpty ? filteredExpenses.first : null,
          clearExpense: filteredExpenses.isEmpty,
        );
      }
    }
  }

  void _insertError() {
    _insertAiReply('Sorry, I could not process your request. Please try again.');
  }
}
