import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Dates from Gemini/backend are UTC ISO strings. Convert to local before
  /// comparing with DateTime.now() (which is always local).
  static bool _isToday(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  // ── Computed getters ─────────────────────────────────────────────────────────

  double get totalToday =>
      _expenses.where((e) => _isToday(e.date)).fold(0.0, (s, e) => s + e.amount);

  int get todayCount => _expenses.where((e) => _isToday(e.date)).length;

  Set<String> get todayCategories =>
      _expenses.where((e) => _isToday(e.date)).map((e) => e.category).toSet();

  // ── Init ─────────────────────────────────────────────────────────────────────

  ExpenseProvider() {
    // Subscribe to Firebase auth state changes so data is always scoped to the
    // currently signed-in user. Clears local state on sign-out and reloads on
    // sign-in (including switching between accounts).
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        loadExpenses();
      } else {
        _expenses.clear();
        _isLoading = false;
        _error = null;
        notifyListeners();
      }
    });
  }

  // ── Remote operations ────────────────────────────────────────────────────────

  /// Fetches all expenses for the authenticated user from the backend.
  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.get('/expenses');
      final List<dynamic> raw = data['expenses'] as List<dynamic>;
      _expenses
        ..clear()
        ..addAll(raw.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      _error = e.toString();
      debugPrint('[ExpenseProvider] loadExpenses error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persists a new expense via the backend and adds it to the local list.
  /// Use this when the expense originates from the manual expense form.
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      final data = await ApiService.post('/expenses', {
        'description': expense.description,
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
      });
      final created = ExpenseModel.fromJson(data['expense'] as Map<String, dynamic>);
      _expenses.insert(0, created);
      notifyListeners();
    } catch (e) {
      debugPrint('[ExpenseProvider] addExpense error: $e');
    }
  }

  /// Adds an expense that was already saved to Firestore by the backend
  /// (e.g. auto-saved by the chat controller after Gemini parsing).
  /// Does NOT make another API call — just inserts into the local list.
  void addExpenseLocally(ExpenseModel expense) {
    if (_expenses.any((e) => e.id == expense.id)) return;
    _expenses.insert(0, expense);
    notifyListeners();
  }

  /// Replaces an expense in the local list with an updated version.
  /// Called after the chat backend has already persisted the update.
  void updateExpenseLocally(ExpenseModel updated) {
    final index = _expenses.indexWhere((e) => e.id == updated.id);
    if (index == -1) return;
    _expenses[index] = updated;
    notifyListeners();
  }

  /// Removes an expense from the local list by id.
  /// Called after the chat backend has already deleted it from Firestore.
  void removeExpenseLocally(String id) {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Deletes an expense from the backend and removes it from the local list.
  Future<void> removeExpense(String id) async {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final removed = _expenses[index];
    _expenses.removeAt(index);
    notifyListeners();

    try {
      await ApiService.delete('/expenses/$id');
    } catch (e) {
      _expenses.insert(index, removed);
      notifyListeners();
      debugPrint('[ExpenseProvider] removeExpense error: $e');
    }
  }

  /// Computes the total spending for a given period from the local expense list.
  double totalForPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Today':
        return totalToday;
      case 'This Week':
        final weekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return _expenses
            .where((e) => !e.date.toLocal().isBefore(weekStart))
            .fold(0.0, (sum, e) => sum + e.amount);
      case 'This Month':
        return _expenses
            .where((e) {
              final local = e.date.toLocal();
              return local.year == now.year && local.month == now.month;
            })
            .fold(0.0, (sum, e) => sum + e.amount);
      default:
        return totalToday;
    }
  }
}
