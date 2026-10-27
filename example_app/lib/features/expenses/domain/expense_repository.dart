import 'expense.dart';

/// What the expenses feature needs from storage. Screens and controllers
/// depend on this interface; tests replace it with a fake.
abstract interface class ExpenseRepository {
  /// All expenses, newest first.
  Future<List<Expense>> fetchAll();

  Future<void> add(Expense expense);
}
