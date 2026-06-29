# 2026-06-29 night-ui-b4-qa-safety

## Scope

- Branch: `codex/night-ui-b4-qa-safety`
- Worktree: `.worktrees/night-ui-b4-qa-safety`
- Baseline: `ec55031feffeb0d3aed705549ecfbc096ca01922`
- Boundary: presentation/test/tooling/docs only. No `numbers.yaml`, save schema, settlement logic, `GDD.md`, or `CLAUDE.md` changes.

## Tasks

1. `responsive-pass`: Fixed smoke checklist now records `1280x720`, `1440x900`, `1920x1080`, `2560x1080`.
2. `text-overflow-pass`: Added shared button/tab/dialog tests for hitbox and wrapping; smoke checklist calls out title/button/chip overflow on key routes.
3. `shadow-policy`: Recorded policy below; no broad page restyle in this batch.
4. `hover-focus-pass`: Hardened shared controls with cursor/semantics/keyboard checks.
5. `hitbox-debug-overlay`: Added debug-only `HITBOX_DEBUG=true` overlay for visual routes.
6. `compact-control-audit`: Ran literal audit for `minimumSize: Size.zero`, `shrinkWrap`, `VisualDensity.compact`, and small fixed controls.
7. `paper-dark-contrast-pass`: Ran color token audit for shallow paper vs deep battle text candidates.
8. `route-host-coverage`: Smoke suite now covers main menu, inventory, battle, technique, shop, seclusion, tower, and encyclopedia/codex routes.
9. `screenshot-capture-script`: Added `tools/visual_capture/visual_capture.sh`, fixed output under `build/visual_acceptance`.
10. `widget-test-hardening`: Extended shared button, dialog, tab, and icon-entry button tests.
11. `performance-smoke`: Recorded below; this batch adds no production animation/image decode path.
12. `claude-merge-handoff`: Added `docs/handoff/2026-06-29-night-ui-claude-merge-handoff.md`.

## Changes

- `lib/features/debug/presentation/hitbox_debug_overlay.dart`
  - Debug-only overlay, gated by both `kDebugMode` and `--dart-define=HITBOX_DEBUG=true`.
  - Paints translucent rectangles over likely interactive render boxes and shows a count.
- `lib/features/debug/presentation/visual_route_host.dart`
  - Wraps visual route home with hitbox overlay only when enabled.
- `lib/features/debug/application/visual_acceptance_plan.dart`
  - Smoke route list expanded to key acceptance pages.
  - Checklist defaults to four desktop/wide resolutions.
- `tools/visual_capture/visual_capture.sh`
  - Local macOS screenshot helper with `--dry-run`, `--hitbox`, route/suite, output dir, and resolution options.
- `lib/shared/widgets/wuxia_ui/paper_dialog.dart`
  - Dialog action area uses `Wrap` to avoid narrow-width button overflow.
- `lib/shared/widgets/wuxia_ui/plaque_tab.dart`
  - Adds `Semantics`, selected/enabled state, cursor policy, autofocus, and single-line ellipsis.
- `lib/shared/widgets/wuxia_ink_button.dart`
  - Adds explicit `Semantics(button)` and cursor policy for main/icon entry buttons.
- Tests updated under `test/shared/widgets/` and `test/features/debug/`.

## Acceptance Routes

Smoke suite routes:

- `main_menu`
- `inventory`
- `battle_scene`
- `technique_panel_tier_all`
- `shop`
- `seclusion_map_list`
- `tower_floor_list`
- `zangjuange`
- `encounter_codex`
- `skill_codex`
- `battle_charge_break`

Full suite remains every `VisualRoute` except `hub`.

## Audit Notes

### Responsive Pass

Primary sizes to capture tomorrow:

- `1280x720`: minimum accepted desktop surface; watch vertical crowding in battle and technique.
- `1440x900`: Mac laptop common path; main human review target.
- `1920x1080`: Windows target baseline.
- `2560x1080`: ultrawide risk pass; watch over-stretched map/card rows.

### Text Overflow Pass

Covered by tests:

- `PlaqueButton` hitbox height >= 36.
- `PlaqueTab` hitbox height >= 36, ellipsis enabled.
- `PaperDialog` action row wraps under narrow width.
- `WuxiaInkButton` icon-entry hitbox height >= 76.

Manual screenshot watch points:

- `inventory`: item/card titles, material action buttons.
- `shop`: price/status chips and disabled purchase labels.
- `zangjuange`, `encounter_codex`, `skill_codex`: dense card titles and group headers.

### Shadow Policy

Policy for morning merge review:

- Dialogs: `elevation: 0`; use paper panel border/texture for depth.
- Shared cards/buttons: one restrained shadow at most, low blur and short offset.
- High-energy shadows are only acceptable for treasure glow, boss/current-floor emphasis, or battle FX.
- Avoid adding big dark shadows to small buttons; small controls should read through border/fill/focus ring.

Audit command:

```bash
rg -n "boxShadow|elevation:|shadowColor" lib/shared lib/features
```

### Hover / Focus Pass

- `PlaqueButton`: already had semantics, click cursor, Enter/Space activation, focus ring.
- `PlaqueTab`: now has semantics, selected state, click/basic cursor, Enter activation through `InkWell` focus.
- `WuxiaInkButton`: now has explicit button semantics and cursor policy.

### Compact Control Audit

Command:

```bash
rg -n "minimumSize:\s*Size\.zero|VisualDensity\.compact|shrinkWrap:\s*true" lib
```

Findings to watch:

- `lib/features/tower/presentation/tower_floor_list_screen.dart`: one `minimumSize: Size.zero`.
- `lib/features/mainline/presentation/stage_victory_dialog.dart`: `VisualDensity.compact`.
- `lib/features/character_panel/presentation/equip_slot_dialog.dart`: compact density + `shrinkWrap`.
- `lib/features/sect/presentation/sect_screen.dart`: compact density on dense controls.
- `shrinkWrap` also appears in character panel and cangjingge picker. No behavior changes made in this batch.

### Paper / Dark Contrast Pass

Command:

```bash
rg -n "WuxiaColors\.text(Primary|Secondary|Muted)|Colors\.white" lib/features lib/shared
```

Notes:

- Existing token comments already mark `WuxiaColors.text*` as deep-background-only.
- Paper UI kit uses `WuxiaUi.ink` / `WuxiaUi.muted`.
- Some feature pages still use deep text tokens; morning screenshot pass should check whether those are on dark surfaces before merging visual page branches.

### Performance Smoke

This batch adds:

- A debug-only overlay gated by `kDebugMode` + `HITBOX_DEBUG=true`.
- Test/tooling changes.
- Semantics/cursor wrappers on shared controls.

No production image decode path, continuous animation, or repaint-heavy route was added. For manual smoke:

```bash
tools/visual_capture/visual_capture.sh --dry-run --route battle_scene --resolutions 1920x1080
tools/visual_capture/visual_capture.sh --dry-run --route main_menu --resolutions 1280x720 --hitbox
```

## Verification

Passed:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter test test/shared/widgets/wuxia_ui/plaque_button_test.dart test/shared/widgets/wuxia_ui/paper_dialog_test.dart test/shared/widgets/wuxia_ui/plaque_tab_test.dart test/shared/widgets/wuxia_ink_button_test.dart test/features/debug/hitbox_debug_overlay_test.dart
flutter pub run tool/visual_acceptance.dart checklist --suite smoke
tools/visual_capture/visual_capture.sh --help
tools/visual_capture/visual_capture.sh --dry-run --route main_menu --resolutions 1280x720 --hitbox
flutter test test/features/debug/application/visual_acceptance_plan_test.dart
flutter analyze
```

Known non-blocking verification note:

- `flutter test test/features/debug/visual_route_test.dart` still attempts `Isar.initializeIsarCore(download: true)` and failed with `IsarError: Could not download IsarCore library` in this worktree. The failure is external to this batch's route list parsing/checklist changes; the directly changed `visual_acceptance_plan_test` passes.

## Risks

- `HitboxDebugOverlay` identifies interactive render boxes by render-object type name. It is intentionally debug-only and suitable for visual audit, not a production contract.
- Screenshot script relies on macOS `osascript` and `screencapture`; it is local-only and should be run from an interactive desktop session.
- Compact-control and contrast audits are recorded, not fully remediated, to avoid colliding with batches 1-3 page work.
