import 'package:expenses_example/features/expenses/data/in_memory_expense_repository.dart';
import 'package:expenses_example/features/expenses/domain/expense.dart';
import 'package:expenses_example/features/expenses/domain/expense_repository.dart';
import 'package:expenses_example/features/expenses/presentation/expenses_controller.dart';
import 'package:expenses_example/features/expenses/presentation/expenses_screen.dart';
import 'package:expenses_example/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository([List<Expense> initial = const []])
    : _items = [...initial];

  final List<Expense> _items;
  Object? failWith;

  @override
  Future<List<Expense>> fetchAll() async {
    if (failWith case final error?) throw error;
    return List.unmodifiable(_items.reversed);
  }

  @override
  Future<void> add(Expense expense) async {
    if (failWith case final error?) throw error;
    _items.add(expense);
  }
}

final lunch = Expense(
  id: '1',
  title: 'Lunch',
  amountPaise: 24050,
  spentAt: DateTime.utc(2026, 10, 27, 7),
);

Widget app(ExpenseRepository repository) => ProviderScope(
  // Riverpod 3 retries failed providers automatically; turn that off so
  // error states appear straight away in tests.
  retry: (retryCount, error) => null,
  overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ExpensesScreen(),
  ),
);

void main() {
  group('parseRupees', () {
    test('accepts rupees with up to two decimals', () {
      expect(parseRupees('240'), 24000);
      expect(parseRupees(' 240.5 '), 24050);
      expect(parseRupees('0.05'), 5);
    });

    test('rejects everything else', () {
      for (final bad in ['', '1,000', '₹10', '-5', '1.234', 'abc']) {
        expect(parseRupees(bad), isNull, reason: bad);
      }
    });
  });

  group('ExpensesController', () {
    test('loads expenses from the repository', () async {
      final container = ProviderContainer.test(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(
            FakeExpenseRepository([lunch]),
          ),
        ],
      );
      expect(await container.read(expensesControllerProvider.future), [lunch]);
    });

    test('add saves the expense and reloads the list', () async {
      final repository = FakeExpenseRepository();
      final container = ProviderContainer.test(
        overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
      );
      await container.read(expensesControllerProvider.future);

      final saved = await container
          .read(expensesControllerProvider.notifier)
          .add(title: '  Chai ', amountPaise: 2000);

      expect(saved, isTrue);
      final expenses = container.read(expensesControllerProvider).value!;
      expect(expenses.single.title, 'Chai');
      expect(expenses.single.amountPaise, 2000);
      expect(expenses.single.spentAt.isUtc, isTrue);
    });

    test('add reports failure without changing the list', () async {
      final repository = FakeExpenseRepository([lunch]);
      final container = ProviderContainer.test(
        overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
      );
      await container.read(expensesControllerProvider.future);
      repository.failWith = Exception('disk full');

      final saved = await container
          .read(expensesControllerProvider.notifier)
          .add(title: 'Chai', amountPaise: 2000);

      expect(saved, isFalse);
      expect(container.read(expensesControllerProvider).value, [lunch]);
    });
  });

  group('ExpensesScreen', () {
    testWidgets('shows a spinner while loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(
              InMemoryExpenseRepository(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ExpensesScreen(),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Let the repository's delay finish so no timers are left pending.
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('shows the empty state', (tester) async {
      await tester.pumpWidget(app(FakeExpenseRepository()));
      await tester.pump();
      expect(find.text('No expenses yet. Add your first one.'), findsOneWidget);
    });

    testWidgets('lists expenses with a total', (tester) async {
      await tester.pumpWidget(app(FakeExpenseRepository([lunch])));
      await tester.pump();
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Total: ₹240.50'), findsOneWidget);
    });

    testWidgets('shows an error with a working retry', (tester) async {
      final repository = FakeExpenseRepository([lunch])
        ..failWith = Exception('offline');
      await tester.pumpWidget(app(repository));
      await tester.pump();
      expect(find.text("Couldn't load your expenses."), findsOneWidget);

      repository.failWith = null;
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('adds an expense through the dialog', (tester) async {
      await tester.pumpWidget(app(FakeExpenseRepository()));
      await tester.pump();

      await tester.tap(find.text('Add expense'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Enter an amount like 240 or 240.50'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('expense-title')), 'Auto');
      await tester.enterText(find.byKey(const Key('expense-amount')), '85.5');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Total: ₹85.50'), findsOneWidget);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(FakeExpenseRepository([lunch])));
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('fits a small screen with 200% text', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(app(FakeExpenseRepository([lunch])));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Lunch'), findsOneWidget);
    });
  });
}
