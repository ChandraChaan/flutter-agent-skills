# Feature review checklist

Go through this before saying a feature is done. Fix what you can; list the rest in your report.

## Structure

- [ ] `domain/` has no Flutter or `data/` imports
- [ ] Widgets don't import anything from `data/`
- [ ] The repository is an interface with a provider, and tests override it
- [ ] Models are immutable with value equality

## States

- [ ] Loading state is visible and doesn't flash for fast responses
- [ ] Error state shows a human message and a Retry action
- [ ] Empty state explains what to do next
- [ ] Pull to refresh (or another refresh path) if the data changes
- [ ] Double taps on actions can't submit twice

## UI

- [ ] No hard-coded strings, colours or text styles
- [ ] Works at 320 px wide and with text scaled to 200%
- [ ] Tap targets ≥ 48 dp, all with labels
- [ ] Controllers, focus nodes and subscriptions are disposed
- [ ] `context.mounted` checked after every `await` that uses `context`

## Tests

- [ ] Controller: success, each action, failure
- [ ] Widget: loading, data, empty, error
- [ ] Accessibility guidelines pass
- [ ] `dart format .`, `flutter analyze` and `flutter test` all clean
