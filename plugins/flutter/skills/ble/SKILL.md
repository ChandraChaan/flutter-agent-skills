---
name: ble
description: Add or debug Bluetooth Low Energy in a Flutter app - permissions on Android and iOS, scanning, connecting and reconnecting, MTU, notifications, parsing standard GATT characteristics such as heart rate or blood pressure, background use, and testing without hardware. Use for any BLE, wearable, fitness sensor or medical device integration.
---

# Bluetooth LE in Flutter

## 1. Check what's there

Find the BLE plugin in `pubspec.yaml` (`flutter_blue_plus`, `flutter_reactive_ble`, `universal_ble`) and keep using it. For a new project, `flutter_blue_plus` is the most widely used; `universal_ble` also covers web and desktop.

## 2. Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<!-- Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<!-- Android 11 and lower -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
```

Remove `neverForLocation` only if the app derives location from scan results (beacons).

**iOS** (`ios/Runner/Info.plist`): `NSBluetoothAlwaysUsageDescription` with a sentence a user understands. Add `bluetooth-central` to `UIBackgroundModes` only if the app must talk to the device in the background.

Request permissions at the moment the user starts pairing, after explaining why. Handle "denied" and "Bluetooth off" as normal states with a way forward.

## 3. Connection lifecycle

Put BLE behind a repository interface (`DeviceRepository`) so the UI and tests never touch the plugin directly. Inside it:

1. **Scan with a service filter** (for example the Heart Rate service `180D`), and a timeout. Never scan forever.
2. **Connect**, then on Android request a larger MTU (for example 247) before heavy transfers.
3. **Discover services**, then **subscribe to notifications** rather than polling reads.
4. **Listen to the connection state stream.** On an unexpected disconnect, reconnect with backoff; on a user disconnect, stop.
5. **Cancel every subscription** and disconnect in `dispose` or when the feature closes.
6. Serialise GATT operations: one read/write at a time per device. Many stacks fail silently on overlapping operations.

Remember the device ID after pairing and reconnect directly next time instead of scanning.

## 4. Parse data with a tested parser

Characteristic values arrive as `List<int>`. For standard Bluetooth SIG characteristics, don't hand-roll bit parsing; use [`ble_gatt_parser`](https://pub.dev/packages/ble_gatt_parser), which handles every flag, optional field, unit and SFLOAT value:

```dart
final value = GattParser.parse(characteristic.uuid.str, bytes);
switch (value) {
  case HeartRateMeasurement(:final bpm, :final rrIntervalsMs): ...
  case BloodPressureMeasurement(:final systolic, :final diastolic): ...
  default: ...
}
```

For vendor-specific characteristics, write a parser with unit tests built from captured packets (log raw bytes as hex in debug builds).

## 5. Test without hardware

- Unit-test parsers with byte fixtures.
- Test the repository and UI against a fake device. [`ble_device_simulator`](https://pub.dev/packages/ble_device_simulator) produces realistic heart-rate, blood pressure, SpO2 and cycling notifications as streams you can feed through your repository's interface.
- Cover: permission denied, Bluetooth off, device not found, disconnect mid-stream, reconnect, malformed packet.

## 6. Background and battery

- Don't keep scanning in the background. Reconnect to known devices instead.
- Connect, transfer, disconnect for periodic sync; keep the connection only during live sessions (workouts).
- Android needs a foreground service for continuous background connections; iOS restores BLE state if you opt in to state restoration.

## 7. Report

Say which platforms you configured, which permissions you added and why, how disconnects are handled, and what was tested with real hardware versus simulated.
