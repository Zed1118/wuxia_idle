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
- Runtime: 12 seconds warmup, 60 seconds sample, 30 seconds cooldown. The
  first real 10-second clear burst stays inside warmup so shader and render-path
  cold start cannot race the sampling boundary.

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
If only a 60Hz Retina display is available, omit coordinates and run with
`PROBE_GATE_DPR=2`; the manifest keeps this higher physical-pixel load distinct
from the preferred DPR 1 baseline.

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
nearest-rank percentiles, severe-frame streaks, RSS, VM-service GC events, pool
counters, collision workload, and file checksums. It only subscribes to the VM
GC event stream and never requests or triggers garbage collection. If the
Profile VM service is unavailable, the run emits `GC_TELEMETRY_MISSING` and
cannot pass.

The Windows minimum-spec evidence template is at
`config/windows_minimum_spec_manifest.template.json`. Windows results require
a physical i5-8250U/UHD 620/8GB-class device; a stronger discrete GPU cannot
sign the minimum-spec Gate.

Phase 0A uses a separate deterministic replay runner; the older
`run_windows_profile.ps1` only covers the Phase 0-minus benchmark and cannot
sign the ARPG greybox Gate. Follow
`docs/phase0/phase0a-windows-physical-gate.md` from the repository root and run
`scripts/run_phase0a_windows_matrix.ps1` for the required two-viewports by
three-runs matrix.

## Phase 0B isolated art reviews

The same nested package also hosts four explicitly non-production art modes:

- `phase0b_runtime`: 1+6+1 discrete pose-atlas review;
- `phase0b_joint_compare`: rejected automatic cutout hierarchy evidence;
- `phase0b_art_load`: fixed-camera 20+1 local peak observation, not the final
  battle interface;
- `phase0b_scroll_review`: 3600×720 continuous-map and follow-camera direction,
  with local encounter density 6 → 10 → 20+1.

Run the interactive product-direction review with:

```bash
PROBE_MODE=phase0b_scroll_review PROBE_VIEWPORT=desktop_1280x720 \
  build/macos/Build/Products/Profile/phase0minus_probe.app/Contents/MacOS/phase0minus_probe
```

The fixed-camera art-load runner writes only observation reports with
`gate_eligible=false`. Pin both viewports to the same 60Hz display before
comparing runs; mixed-display results are invalid even though this is not a
gameplay Gate.
