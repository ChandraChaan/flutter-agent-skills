---
name: tests
description: Write or fix Flutter and Dart tests - unit tests for controllers and repositories, widget tests for every screen state, golden tests, and fixes for flaky tests. Use when the user asks for tests, test coverage, or when a test fails or hangs.
---

# Write Flutter tests that catch real bugs

## Decide what to test

| Code | Test type | Cover |
|---|---|---|
| Controllers / notifiers / blocs | Unit | Initial state, each public method, each failure path |
| Repositories and parsers | Unit | Mapping, error mapping (timeouts, 4xx, 5xx, bad JSON) |
| Screens | Widget | Loading, data, empty, error, and the main interaction |
| Layout-critical widgets | Golden | Light and dark, large text |
| Full critical flow (login, checkout) | Integration (`integration_test`) | Happy path only |

Test behaviour the user or caller can observe, not private implementation details.

## Fakes over mocks

For small interfaces, write a fake. It's shorter than mock setup and survives refactors:

```dart
class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository([List<Expense> initial = const []])
      : _items = [...initial];

  final List<Expense> _items;
  Object? failWith;

  @override
  Future<List<Expense>> fetchAll() async {
    if (failWith case final error?) throw error;
    return List.unmodifiable(_items);
  }

  @override
  Future<void> add(Expense expense) async => _items.add(expense);
}
```

Use `mocktail` when you must verify that a call happened (analytics, a payment request sent exactly once).

## Riverpod

```dart
test('loads expenses', () async {
  final container = ProviderContainer.test(
    overrides: [expenseRepositoryProvider.overrideWithValue(FakeExpenseRepository([lunch]))],
  );
  expect(await container.read(expensesControllerProvider.future), [lunch]);
});
```

Riverpod 3 **retries failed providers automatically**, so an error state may not appear on the next frame. In tests that check errors, turn it off: `ProviderContainer.test(retry: (_, _) => null, ...)` or `ProviderScope(retry: (_, _) => null, ...)`.

In widget tests wrap the screen: `ProviderScope(overrides: [...], child: MaterialApp(home: ExpensesScreen()))`, with the app's theme and localisation delegates if the screen uses them.

## Widget test rules

- Find by user-visible text, `Key`, or semantics label. `find.byType` only when there's exactly one.
- After a tap: `await tester.pump()` for one frame, `await tester.pumpAndSettle()` only when no infinite animation is running. **A visible `CircularProgressIndicator` makes `pumpAndSettle` time out**; use `pump(const Duration(milliseconds: 100))` instead.
- Futures that complete instantly in fakes still need a `pump()` to rebuild.
- Test large text: `tester.platformDispatcher.textScaleFactorTestValue = 2.0;` (reset in `addTearDown`).
- Test a narrow screen: `tester.view.physicalSize = const Size(320, 640); tester.view.devicePixelRatio = 1;` (reset with `addTearDown(tester.view.reset)`).

## Flaky or hanging tests

1. **Timeout in `pumpAndSettle`:** an infinite animation. Pump a fixed duration.
2. **Passes alone, fails in the suite:** shared state. Look for singletons, static fields, or a provider container that isn't disposed.
3. **Depends on time:** inject a clock (`package:clock`, `withClock`) instead of calling `DateTime.now()`.
4. **Real network or plugins:** `MissingPluginException` or real HTTP. Inject a fake; never let tests reach the network.
5. **Error state never shows (Riverpod 3):** automatic retry. Pass `retry: (_, _) => null` to the container or scope.
6. **Golden differences between machines:** fonts. Load the app's fonts in `flutter_test_config.dart` and generate goldens on CI's platform.

## Bug fixes

Write the test first, run it, and confirm it **fails for the reason the bug describes**. Then fix the code and confirm it passes.

## Finish

Run `flutter test` (and `flutter test --coverage` if the project tracks coverage). Report which behaviours are now covered and anything you couldn't test and why.
