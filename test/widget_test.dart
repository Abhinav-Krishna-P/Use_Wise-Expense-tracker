import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/chat_provider.dart';
import 'package:expense_tracker/models/expense_model.dart';

void main() {
  test('ExpenseProvider initializes with seed data', () {
    final provider = ExpenseProvider();
    expect(provider.expenses.isNotEmpty, true);
    expect(provider.expenses.length, 8);
  });

  test('ChatProvider starts with empty messages', () {
    final provider = ChatProvider();
    expect(provider.messages.isEmpty, true);
    expect(provider.isLoading, false);
  });

  test('ExpenseProvider adds and removes expenses', () {
    final provider = ExpenseProvider();
    final initialCount = provider.expenses.length;

    final expense = ExpenseModel(
      id: 'test_1',
      description: 'Test Expense',
      amount: 100,
      category: 'Food',
      date: DateTime.now(),
    );

    provider.addExpense(expense);
    expect(provider.expenses.length, initialCount + 1);

    provider.removeExpense('test_1');
    expect(provider.expenses.length, initialCount);
  });
}
