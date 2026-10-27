---
name: security
description: Review a Flutter app for security problems - hard-coded secrets, insecure token storage, logging of personal data, missing certificate pinning, unvalidated deep links, debug flags in release, and platform configuration - and fix them. Use before a release, for apps handling money, health or personal data, or when the user asks for a security review.
---

# Flutter security review

Work through each area, record findings with file and line, and fix what's safe to fix. Don't paste any secret you find into chat or commit messages: refer to it by file and line.

## 1. Secrets in the code

```bash
git grep -nIE "(api[_-]?key|secret|token|password|BEGIN (RSA|EC|PRIVATE)|AIza[0-9A-Za-z_-]{35}|sk_live_|AKIA[0-9A-Z]{16})" -- . ':!*.lock'
```

- Anything compiled into the app can be extracted. Keys for paid or privileged APIs must move to a backend.
- Firebase config (`google-services.json`, `GoogleService-Info.plist`) isn't secret, but it must be protected by security rules and App Check.
- Build-time config: `--dart-define-from-file=config/prod.json`, with that file outside git.
- If a real secret was ever committed, it must be **rotated**: removing it from history isn't enough. Tell the user.

## 2. Storage

| Data | Where |
|---|---|
| Access and refresh tokens, credentials | `flutter_secure_storage` (Keychain / Keystore) |
| Personal or financial data cached offline | Encrypted database (SQLCipher / drift with encryption) or encrypted files |
| Preferences, flags | `SharedPreferences` is fine |

Check that logout deletes tokens and cached personal data.

## 3. Network

- HTTPS only. Android: no `usesCleartextTraffic="true"` in release; iOS: no broad `NSAllowsArbitraryLoads`.
- For money or health apps, **certificate (public key) pinning** with at least one backup pin and a plan for rotation.
- No disabled certificate checks (`badCertificateCallback` returning `true`) outside debug.
- Timeouts on every request; don't put tokens or personal data in URLs (they end up in logs).

## 4. Logging and analytics

Search for `print(`, `debugPrint(`, `log(` and the logger: no tokens, OTPs, passwords, card or ID numbers (Aadhaar, PAN), health values, or full request/response bodies. Crash reports and analytics events follow the same rule.

## 5. Input from outside

- **Deep links and app links:** validate host, path and parameters; never navigate to an arbitrary URL or perform an action (payment, account change) straight from a link without confirmation.
- **Push payloads:** treat as untrusted hints; fetch real data from the API.
- **WebViews:** restrict navigation to allowed origins; don't expose JavaScript channels to arbitrary pages.
- Android: `exported` components only where needed; check `intent-filter`s.

## 6. Release configuration

- Release builds: `--obfuscate --split-debug-info=build/symbols` (upload symbols to the crash reporter).
- No debug banners, test endpoints, verbose logging or developer menus reachable in release (`kReleaseMode` checks).
- Android: `android:allowBackup="false"` (or backup rules excluding sensitive files) for sensitive apps; `FLAG_SECURE` on screens with secrets.
- iOS: hide sensitive content in the app switcher snapshot.

## 7. Device integrity (money and health apps)

Consider Play Integrity / App Attest checks on the server for sensitive operations, and limiting features on rooted or jailbroken devices. These raise the bar; they're not a guarantee.

## Report

A table: **severity** (high, medium, low) → **finding** (file:line) → **fix made or recommended**. High: exposed secrets, tokens in plain storage, disabled TLS checks, unvalidated actions from links. Say clearly what still needs a human or backend change.
