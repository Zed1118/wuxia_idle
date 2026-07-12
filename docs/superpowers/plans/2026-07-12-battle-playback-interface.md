# Battle Playback Interface Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hide animation resources and overlay keys behind focused playback view widgets while preserving BattleScreen behavior and layout.

**Architecture:** `BattlePlaybackController` remains the sole owner of timers, animation controllers, VFX collections and disposal. A same-library part file renders motion, battlefield VFX and overlays using private resources. `BattleScreen` keeps business composition and only consumes playback state, intents and these focused widgets.

**Tech Stack:** Flutter 3.41.5, Dart library parts, Riverpod, flutter_test widget tests.

---

## Branch and acceptance

- Branch: `codex/battle-playback-interface`
- Worktree: `/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-playback-interface`
- Baseline: `main` at `62164693`
- Rejected-task registry: read; no conflict.

- [ ] Production wiring: BattleScreen uses all three new playback view widgets.
- [ ] Interface: BattleScreen no longer accesses controller lists/maps/controllers/GlobalKeys.
- [ ] Ownership: timer, animation creation and dispose stay in BattlePlaybackController.
- [ ] Targeted tests: controller plus relevant BattleScreen interaction/layout suites pass.
- [ ] Viewports: 1280×720 and 1440×900 smoke tests have no exceptions/overflow.
- [ ] Static/full: analyze, formatting, diff and one full suite pass.
- [ ] Redlines: no data, numbers, schema, persistence, battle formula, text or asset changes.
- [ ] Residual risk and real-window/Windows validation are recorded.
- [ ] Worktree is clean and final tip begins with `[READY]`.

### Task 1: RED architecture contract

**Files:**
- Create: `test/features/battle/presentation/battle_playback_interface_test.dart`

- [ ] Add a source contract that reads `battle_screen.dart` and rejects resource access tokens:
  `.attackControllers`, `.hitFlashControllers`, `.hitFlashColors`, `.activeTrails`,
  `.activeEffects`, `.popups`, `.closeupCtrl`, `.shakeCtrl`, `.screenFlashKey`,
  `.ultimateCaptionKey`, `.impactGlyphKey`.
- [ ] Assert the source contains `BattlePlaybackMotion`, `BattlePlaybackField`, and
  `BattlePlaybackOverlays`.
- [ ] Run the test and observe RED against the current page.
- [ ] Commit the failing contract as `定义战斗播放边界契约`.

### Task 2: Add same-library view components

**Files:**
- Modify: `lib/features/battle/presentation/battle_playback_controller.dart`
- Create: `lib/features/battle/presentation/battle_playback_view.dart`
- Modify: `test/features/battle/battle_playback_controller_test.dart`

- [ ] Add `part 'battle_playback_view.dart';` and imports for screen shake, BattleField and
  VFX layers to the controller library.
- [ ] Rename `impactShakeAmplitude` to `_impactShakeAmplitude`; remove public resource getters;
  expose only `Animation<double> get beat => _beatCtrl`.
- [ ] Add test-only queries: popup list for a slot, active trail/effect counts and beat animation
  state, all annotated `@visibleForTesting`.
- [ ] Implement `BattlePlaybackMotion` with the exact existing closeup/shake AnimatedBuilders.
- [ ] Implement `BattlePlaybackField` with existing BattleField + VFX Stack order and callbacks.
- [ ] Implement `BattlePlaybackOverlays` with the existing three overlay keys/order.
- [ ] Migrate controller tests to the test-only queries and run them GREEN.
- [ ] Commit as `封装战斗播放动画资源`.

### Task 3: Rewire BattleScreen and viewport characterization

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`
- Modify: `test/features/battle/presentation/battle_playback_interface_test.dart`

- [ ] Replace nested closeup/shake builders with `BattlePlaybackMotion`.
- [ ] Replace BattleField/projectile/effect Stack with `BattlePlaybackField`.
- [ ] Replace three direct overlay widgets with one positioned `BattlePlaybackOverlays`.
- [ ] Rename remaining `_playback.beatCtrl` reads to `_playback.beat`.
- [ ] Remove imports no longer owned by BattleScreen.
- [ ] Add a full BattleScreen smoke loop for `Size(1280, 720)` and `Size(1440, 900)`, using
  short injected animation numbers and asserting `tester.takeException()` is null.
- [ ] Run the architecture + viewport tests GREEN.
- [ ] Commit as `收紧战斗屏播放消费接口`.

### Task 4: Verification and freeze

**Files:**
- Modify: `docs/superpowers/plans/2026-07-12-battle-playback-interface.md`

- [ ] Run controller, interface, pause, start-paused, log, target-chip and command-console tests.
- [ ] Run `flutter analyze --no-pub` and touched-file format check.
- [ ] Run full `flutter test --no-pub` with filtered failure output.
- [ ] Run `git diff --check` and confirm no capture/generated artifacts.
- [ ] Record commands, counts, viewports, redline impact and real-window/Windows residual risk.
- [ ] Commit recovery point and append `[READY] 完成战斗播放 Interface 收口`.

## Current recovery point

- Status: design and plan complete; implementation not started.
- Last completed: codegraph/context and literal consumer audit identified 11 public resource
  access families in BattleScreen; baseline build_runner wrote 114 ignored outputs and analyze
  returned 0 issues.
- Next: Task 1, create the failing architecture contract and observe RED.
- Blockers: none.

