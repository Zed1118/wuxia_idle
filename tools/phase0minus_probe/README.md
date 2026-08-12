# Phase 0-minus performance probe

This nested Flutter application is a disposable Flame 1.38.0 performance
probe. It is deliberately disconnected from the production application,
routes, YAML, rewards, repositories, and save storage.

## Fixed workload

- Viewports: `desktop_1280x720`, `desktop_1440x900`.
- Tiers: `baseline_10`, `target_20_plus_1`, `stress_30`.
- Seed: `20260812`.
- Clear burst: every 10 seconds.
- Collision backend: Flame `StandardCollisionDetection` with its default
  `Sweep` broadphase.
- Runtime: 10 seconds warmup, 60 seconds sample, 30 seconds cooldown.

All workload values are in `assets/probe_scenarios.yaml`. A SHA-256 of that
exact file is written to every manifest.

## Commands

```bash
flutter pub get
flutter analyze
flutter test
scripts/run_macos_profile.sh desktop_1280x720 stress_30 1 1.0
scripts/run_macos_matrix.sh 3 1.0
```

On a multi-display Mac, optional trailing `x y` coordinates pin the window to
a known display. For the current 60Hz LG display (frame origin `2560,0`), use:

```bash
scripts/run_macos_matrix.sh 3 1.0 2800 200
```

Every manifest records the actual Flutter display ID, refresh rate, DPR, and
physical viewport; coordinates are only a placement request, not evidence.

The last argument is a duration scale. Values below `1.0` are smoke-only and
are recorded as ineligible for the Gate. Windows uses the same parameter set:

```powershell
.\scripts\run_windows_profile.ps1 -Viewport desktop_1280x720 `
  -Tier stress_30 -Repeat 1 -DurationScale 1.0
```

Raw JSONL and generated manifests are written below `build/results/` and are
ignored by Git.

The scripts build one Profile executable and pass scenario values through the
child process environment. The matrix therefore does not recompile for every
tier, viewport, or repeat; compile-time `--dart-define` values remain supported
only as a manual fallback.

## Current evidence limit

The application records raw `FrameTiming.totalSpan`, build and raster samples,
nearest-rank percentiles, severe-frame streaks, RSS, pool counters, collision
workload, and file checksums. It does not trigger garbage collection.

Automated VM-service GC collection is not yet available in Slice 1-3. Every
run therefore emits `GC_TELEMETRY_MISSING`: the timing sub-gate can be inspected,
but the overall Phase 0-minus verdict remains `BLOCKED` and can never be
reported as `PASS`.

The Windows minimum-spec evidence template is at
`config/windows_minimum_spec_manifest.template.json`. Windows results require
a physical i5-8250U/UHD 620/8GB-class device; a stronger discrete GPU cannot
sign the minimum-spec Gate.
