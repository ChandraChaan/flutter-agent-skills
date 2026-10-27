---
name: accessibility
description: Audit and fix Flutter accessibility - screen reader labels and semantics, tap target sizes, text scaling, contrast, focus order and keyboard navigation - and add automated accessibility tests. Use when the user asks about accessibility, TalkBack, VoiceOver, large text, or an accessibility review.
---

# Flutter accessibility audit

## 1. Automated checks first

Add (or run) a widget test for each main screen:

```dart
testWidgets('meets accessibility guidelines', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(const MyApp());
  await tester.pump();

  await expectLater(tester, meetsGuideline(androidTapTargetGuideline)); // 48x48 dp
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));     // 44x44 pt
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));     // 4.5:1
  handle.dispose();
});
```

Fix every failure before the manual review.

## 2. Manual review of the code

Go through each screen's widgets:

| Check | Fix |
|---|---|
| `IconButton` without `tooltip` | Add a `tooltip` (it's also the screen reader label) |
| `GestureDetector` / `InkWell` on custom content | Prefer a real button; otherwise wrap in `Semantics(button: true, label: ...)` |
| Meaningful `Image` / `Icon` without a label | `semanticLabel:` |
| Decorative images | `excludeFromSemantics: true` |
| A card read as many separate fragments | `MergeSemantics`, or `Semantics(label: 'Lunch, ₹240, yesterday')` with `ExcludeSemantics` inside |
| State only shown by colour (red = error) | Add text or an icon, and `Semantics(liveRegion: true)` for messages that appear |
| Custom toggle or slider | `Semantics(toggled:, value:, increasedValue:, onIncrease:)` |
| Fixed heights around text | Let text wrap; test at 200% text scale |
| Text in images | Real text instead |
| Focus order wrong for keyboard / switch access | Reorder widgets, or `FocusTraversalGroup` with `OrderedTraversalPolicy` |
| Error shown in a `SnackBar` only | Also show it next to the field (`InputDecoration.errorText`) |

## 3. Large text and small screens

- Test with `textScaler` at 2.0 and a 320 px wide screen (see the `tests` skill for how). Nothing should overflow or be cut off.
- Don't clamp text scaling app-wide to avoid layout work. If one specific widget can't grow, limit that widget and explain why.

## 4. Try it with a screen reader

If a device or simulator is available, turn on TalkBack (Android) or VoiceOver (iOS) and:

1. Swipe through each screen: is every element announced once, in a sensible order, with a useful label?
2. Activate each control with a double tap.
3. Check that dialogs and bottom sheets trap focus and announce their title.

Use the Flutter Inspector's **Show semantics** (or `showSemanticsDebugger: true` on `MaterialApp`) to see what assistive technology sees.

## 5. Report

List each issue as: screen → problem → fix made (or recommended), and which automated checks now pass.
