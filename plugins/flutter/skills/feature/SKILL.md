---
name: feature
description: Build a new Flutter feature end to end in a feature-first, layered structure (domain, data, presentation) with Riverpod 3, loading/error/empty states and tests. Use when the user asks to add a screen, flow or feature to a Flutter app.
---

# Build a Flutter feature

Build the feature in small, verified steps. Follow the project's `AGENTS.md` and existing code first; this skill fills the gaps.

## 1. Understand before writing

1. Read `pubspec.yaml` (state management, routing, codegen), `analysis_options.yaml`, and one existing feature folder end to end. Copy its patterns.
2. Restate the feature in 3–5 bullet points: what the user sees, what data it needs, where it comes from, and what happens offline or on error. Ask the user only if something can't be inferred.

## 2. Domain first

Create `lib/features/<feature>/domain/`:

- **Model:** immutable, `const` constructor, `copyWith`, `==`/`hashCode` (or freezed if the project uses it). Money as `int` minor units, times as UTC `DateTime`.
- **Repository interface:** `abstract interface class <Thing>Repository` with only the methods the screen needs.

No Flutter imports in `domain/`.

## 3. Data layer

Create `lib/features/<feature>/data/`:

- An implementation of the repository (HTTP, database or both). Timeouts on every call; map failures to the project's typed exceptions.
- A provider for it: `final thingRepositoryProvider = Provider<ThingRepository>((ref) => HttpThingRepository(ref.watch(apiClientProvider)));`
- If the backend isn't ready, write an in-memory implementation with realistic delays and data, and say so.

## 4. Presentation

Create `lib/features/<feature>/presentation/`:

- **Controller:** `AsyncNotifier<State>` (or the project's equivalent). Public methods for each user action. After every `await`, check `ref.mounted` before setting `state`.
- **Screen:** `ConsumerWidget` that `switch`es on `AsyncValue`:

```dart
return switch (ref.watch(expensesControllerProvider)) {
  AsyncData(:final value) when value.isEmpty => const _EmptyState(),
  AsyncData(:final value) => _ExpenseList(expenses: value),
  AsyncError(:final error) => ErrorView(error: error, onRetry: controller.refresh),
  _ => const Center(child: CircularProgressIndicator()),
};
```

- Small private widgets for each part. Strings from localisations, colours and text styles from the theme, tap targets ≥ 48 dp with labels.
- Register the route with the router the project uses.

## 5. Tests

Add tests next to the existing ones (`test/features/<feature>/...`):

- **Controller unit test** with a fake repository: initial load, each action, and the error path.
- **Widget test** for loading, data, empty and error states, using `ProviderScope(overrides: [...])`.
- An accessibility check on the main screen:

```dart
final handle = tester.ensureSemantics();
await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
await expectLater(tester, meetsGuideline(textContrastGuideline));
handle.dispose();
```

## 6. Verify and report

Run `dart format .`, `flutter analyze` and `flutter test`, and fix everything. Then report:

- the files you added or changed, grouped by layer
- anything stubbed or assumed (for example, an in-memory repository)
- how to try it (route, test command)

See [checklist.md](checklist.md) for a review checklist to run before reporting.
