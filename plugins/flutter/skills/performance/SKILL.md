---
name: performance
description: Find and fix Flutter performance problems - janky scrolling, slow startup, excessive rebuilds, memory growth, battery drain from idle animations, and large app size. Use when the user reports lag, dropped frames, slow screens, high memory or battery use, or asks for a performance review.
---

# Flutter performance audit

Measure first, change one thing at a time, measure again. Never judge performance in debug mode.

## 1. Reproduce in profile mode

```bash
flutter run --profile            # on a real, preferably low-end, device
```

Open DevTools (the URL is printed) and use:

- **Performance:** frame chart. Red bars are frames over budget (16 ms at 60 Hz, 8 ms at 120 Hz). Check whether the **UI** thread (your Dart code: build, layout) or the **raster** thread (painting, shaders, layers) is slow.
- **CPU profiler:** record while reproducing; sort by self time.
- **Memory:** take snapshots before and after repeating an action; growth that never comes back is a leak.
- **Rebuild stats** (Flutter Inspector): which widgets rebuild on each frame.

On the web, use the browser's Performance panel as well.

## 2. Common causes and fixes

### UI thread slow (build/layout)

| Symptom | Fix |
|---|---|
| Whole screen rebuilds on every change | Split into smaller widgets; `ref.watch(provider.select((s) => s.field))`; move state down |
| Missing `const` | Add `const` constructors and call sites |
| Work in `build` (sorting, parsing, formatting) | Compute once in the controller or memoise |
| Big JSON or image processing | `Isolate.run` / `compute` |
| `ListView(children: [...])` with many items | `ListView.builder` / slivers; set `itemExtent` or `prototypeItem` for fixed heights |
| `IntrinsicHeight`, `IntrinsicWidth`, nested `shrinkWrap` lists | Restructure the layout; they force extra layout passes |

### Raster thread slow (painting)

| Symptom | Fix |
|---|---|
| `Opacity` / `ShaderMask` / `ClipPath` on animated content | `FadeTransition`, `AnimatedOpacity`, colour alpha, `ClipRRect` with simpler shapes |
| Large `BackdropFilter` blurs | Smaller area, or a static blurred image |
| A complex static subtree repainting with a small animation | Wrap the animated part (or the static part) in `RepaintBoundary` |
| Huge images decoded at full size | `cacheWidth` / `cacheHeight` matching display size × device pixel ratio |

### Idle cost and battery

- An animation that loops forever (`repeat()`, an animated placeholder, a Lottie or Rive loop) redraws **every frame even when nothing changes**. Stop it after a few repeats, when off screen (`VisibilityDetector` or `TickerMode`), or when the app is paused.
- Check: with the app idle, the DevTools frame chart should go quiet. If frames keep coming, find the ticker.
- Timers and stream subscriptions not cancelled in `dispose` keep work running.

### Startup

- Measure: `flutter run --profile --trace-startup` (writes `build/start_up_info.json`).
- Defer non-essential initialisation (analytics, remote config fetch, large caches) until after the first frame.
- Keep `main()` and the first screen's dependencies small; lazy-load heavy features with deferred imports on the web.

### App size

```bash
flutter build apk --analyze-size --target-platform android-arm64
flutter build ios --analyze-size
```

Look for large assets (compress images, use WebP, subset fonts), unused packages, and debug-only dependencies leaking into release.

## 3. Report

For each change: the symptom, the measured before/after (frame times, memory, size), and the code change. If something couldn't be measured (no device), say so rather than guessing.
