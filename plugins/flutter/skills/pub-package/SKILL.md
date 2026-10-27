---
name: pub-package
description: Prepare a Dart or Flutter package for pub.dev with full pub points - pubspec metadata, README, example, CHANGELOG, documentation comments, analysis, platform support, screenshots and a clean publish dry run. Use when the user is creating, polishing or releasing a package for pub.dev.
---

# Get a package ready for pub.dev

Never run `dart pub publish` (or `flutter pub publish`) yourself: it publishes permanently under the user's Google account. Get everything ready, run the dry run, and hand over the command.

## 1. Name

Check the name is free: `curl -s -o /dev/null -w '%{http_code}' https://pub.dev/api/packages/<name>` should print `404`. Names are lowercase with underscores, and can't be renamed later.

## 2. pubspec.yaml

```yaml
name: my_package
description: >-
  One or two sentences saying what it does and for whom, between 60 and 180
  characters in total.
version: 0.1.0
repository: https://github.com/<user>/<repo>
issue_tracker: https://github.com/<user>/<repo>/issues
topics: [up-to-five, lowercase, topics]
screenshots:
  - description: What the screenshot shows.
    path: doc/screenshot.png
environment:
  sdk: ^3.5.0
```

- **The description must be 60–180 characters.** The dry run doesn't check this, but pub.dev deducts points for it. Count it.
- Use the lowest SDK constraint you actually test with, and dependency ranges, not exact pins.
- `topics`: at most five, lowercase, hyphens allowed.

## 3. Files pub.dev scores

| File | Needs |
|---|---|
| `README.md` | What it does, a code example near the top, install command, usage, limitations. Images by absolute `https://` URL so they render on pub.dev |
| `CHANGELOG.md` | A `## <version>` heading for the current version |
| `LICENSE` | An OSI licence (MIT, BSD-3, Apache-2.0) |
| `example/` | `example/main.dart` or `example/lib/main.dart` that runs |
| Doc comments | `///` on every public API element; at least 20% must be documented, aim for all |

Use a `.pubignore` to keep demos, CI files and large assets out of the archive (but keep files that `screenshots` or the README reference). A `.pubignore` replaces `.gitignore` for that directory, so repeat build folders in it.

## 4. Code quality checks

```bash
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos          # or flutter analyze
dart test                           # and dart test -p chrome for web support
dart doc --dry-run                  # no warnings
```

Platform support is detected from imports: avoid `dart:io` in code that should work on the web (use conditional imports), and avoid Flutter imports in pure Dart packages.

## 5. Dry run until clean

```bash
dart pub publish --dry-run
```

Repeat until it reports **0 warnings**. Then check the archive file list it prints: nothing secret, nothing huge.

Optionally score locally: `dart pub global activate pana && pana --no-warning .`

## 6. Hand over

Tell the user:

- the final version and description length
- that the dry run shows 0 warnings
- the command to run themselves, from the package directory:

```bash
dart pub publish
```

After publishing: add the pub.dev badge to the README, tag the release (`git tag v0.1.0`), and check the score page on pub.dev after it finishes analysing (a few minutes).
