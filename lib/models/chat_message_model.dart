import 'dart:typed_data';
import 'expense_model.dart';
import 'spending_limit_model.dart';

class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageBytes;
  final String action;
  final ExpenseModel? expense;
  final List<ExpenseModel> expenses;
  final SpendingLimitConfig? spendingLimitConfig;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageBytes,
    this.action = 'none',
    this.expense,
    this.expenses = const [],
    this.spendingLimitConfig,
  });

  ChatMessageModel copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    Uint8List? imageBytes,
    String? action,
    ExpenseModel? expense,
    List<ExpenseModel>? expenses,
    SpendingLimitConfig? spendingLimitConfig,
    bool clearExpense = false,
    bool clearSpendingLimitConfig = false,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      imageBytes: imageBytes ?? this.imageBytes,
      action: action ?? this.action,
      expense: clearExpense ? null : (expense ?? this.expense),
      expenses: expenses ?? this.expenses,
      spendingLimitConfig: clearSpendingLimitConfig
          ? null
          : (spendingLimitConfig ?? this.spendingLimitConfig),
    );
  }
}
