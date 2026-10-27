# Example app

A small expenses app built by following [`rules/AGENTS.md`](../rules/AGENTS.md) and the [`feature`](../plugins/flutter/skills/feature/SKILL.md) skill.

- `lib/features/expenses/{domain,data,presentation}`: layers that only import inwards
- Riverpod 3 `AsyncNotifier`, with loading, data, empty and error states handled by `switch`
- Money in paise, times in UTC, strings in `lib/l10n/app_en.arb`
- `analysis_options.yaml` identical to [`rules/analysis_options.yaml`](../rules/analysis_options.yaml)

```bash
flutter test              # 12 tests: controller, every screen state, add flow, accessibility, small screen with large text
flutter run -d chrome
```
