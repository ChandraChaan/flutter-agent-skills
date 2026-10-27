import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/expense.dart';
import '../domain/expense_repository.dart';

/// Keeps expenses in memory, with a short delay so loading states show.
/// A real app would put a database or an API client here.
class InMemoryExpenseRepository implements ExpenseRepository {
  InMemoryExpenseRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;
  final List<Expense> _expenses = [];

  @override
  Future<List<Expense>> fetchAll() async {
    await Future<void>.delayed(latency);
    final sorted = [..._expenses]
      ..sort((a, b) => b.spentAt.compareTo(a.spentAt));
    return List.unmodifiable(sorted);
  }

  @override
  Future<void> add(Expense expense) async {
    await Future<void>.delayed(latency);
    _expenses.add(expense);
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => InMemoryExpenseRepository(),
);
