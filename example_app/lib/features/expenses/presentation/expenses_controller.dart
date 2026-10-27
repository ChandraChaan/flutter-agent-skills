import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_memory_expense_repository.dart';
import '../domain/expense.dart';

class ExpensesController extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() =>
      ref.watch(expenseRepositoryProvider).fetchAll();

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is in `state`; the screen shows it with a retry button.
    }
  }

  /// Adds an expense and reloads the list. Returns false if saving failed.
  Future<bool> add({required String title, required int amountPaise}) async {
    final repository = ref.read(expenseRepositoryProvider);
    final expense = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      amountPaise: amountPaise,
      spentAt: DateTime.now().toUtc(),
    );
    try {
      await repository.add(expense);
    } catch (_) {
      return false;
    }
    final expenses = await repository.fetchAll();
    if (!ref.mounted) return true;
    state = AsyncData(expenses);
    return true;
  }
}

final expensesControllerProvider =
    AsyncNotifierProvider<ExpensesController, List<Expense>>(
      ExpensesController.new,
    );
