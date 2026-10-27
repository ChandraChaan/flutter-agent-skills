---
name: release
description: Prepare a Flutter app release - version bump, changelog, flavors and environment config, obfuscated release builds for Android (AAB) and iOS (IPA), symbol upload, and a store submission checklist. Use when the user wants to ship, build for the Play Store or App Store, or set up release builds.
---

# Prepare a Flutter release

Never upload to a store, sign with production keys, or push tags without the user's explicit go-ahead. Prepare everything and hand over the final commands.

## 1. Pre-flight

```bash
git status                      # clean working tree
flutter --version               # matches the version CI uses
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

All must pass. Then check:

- [ ] No debug-only flags, test endpoints or verbose logging enabled for release
- [ ] Remote config defaults and feature flags set as intended for this release
- [ ] Translations complete for every supported locale
- [ ] Migrations for local databases tested from the previous release's schema

## 2. Version

`pubspec.yaml`: `version: <name>+<build>`, for example `2.4.0+57`.

- **Name** follows semantic versioning (what users see).
- **Build number** must increase for every store upload, on both stores.

Update `CHANGELOG.md` and draft short store release notes in plain language (what changed for users, not commit messages).

## 3. Environments

If the project has flavors or entry points per environment, build **prod** explicitly:

```bash
flutter build appbundle --release --flavor prod -t lib/main_prod.dart \
  --dart-define-from-file=config/prod.json \
  --obfuscate --split-debug-info=build/symbols/android

flutter build ipa --release --flavor prod -t lib/main_prod.dart \
  --dart-define-from-file=config/prod.json \
  --obfuscate --split-debug-info=build/symbols/ios
```

Drop `--flavor`/`-t` if the project doesn't use them. Keep `build/symbols/` for crash symbolication (upload to Crashlytics or Sentry) and never commit it.

## 4. Android checks

- Signed with the upload key via `key.properties` (not committed). Play App Signing enabled.
- `targetSdkVersion` meets Google Play's current requirement.
- R8/minify on, with keep rules for reflection-based libraries.
- New permissions justified, with a Data safety form update if data collection changed.

## 5. iOS checks

- Bundle version and build number come from `pubspec.yaml` (`FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER`).
- Every permission has a clear `NS…UsageDescription`.
- Privacy manifest (`PrivacyInfo.xcprivacy`) covers required-reason APIs used by the app and its plugins.
- Export compliance (encryption) answered.

## 6. Rollout

- Upload to internal testing / TestFlight first and smoke-test the critical flows on real devices.
- Use a **staged rollout** (Play) or **phased release** (App Store), starting small.
- Risky features ship behind a remote flag that is off, then turned on gradually.
- Watch crash-free users and key funnels by app version before increasing the rollout.

## 7. Hand over

Give the user: the version, the artifacts' paths, the exact upload commands or console steps, the release notes, and what to watch after release. Tag the release (`git tag v2.4.0`) only when they confirm it's shipped.
