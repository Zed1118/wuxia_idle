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

- [x] Production wiring: BattleScreen uses all three new playback view widgets.
- [x] Interface: BattleScreen no longer accesses controller lists/maps/controllers/GlobalKeys.
- [x] Ownership: timer, animation creation and dispose stay in BattlePlaybackController.
- [x] Targeted tests: controller plus relevant BattleScreen interaction/layout suites pass.
- [x] Viewports: 1280×720 and 1440×900 smoke tests have no exceptions/overflow.
- [x] Static/full: analyze, formatting, diff and one full suite pass.
- [x] Redlines: no data, numbers, schema, persistence, battle formula, text or asset changes.
- [x] Residual risk and real-window/Windows validation are recorded.
- [x] Worktree is clean and final tip begins with `[READY]`.

### Task 1: RED architecture contract

**Files:**
- Create: `test/features/battle/presentation/battle_playback_interface_test.dart`

- [x] Add a source contract that reads `battle_screen.dart` and rejects resource access tokens:
  `.attackControllers`, `.hitFlashControllers`, `.hitFlashColors`, `.activeTrails`,
  `.activeEffects`, `.popups`, `.closeupCtrl`, `.shakeCtrl`, `.screenFlashKey`,
  `.ultimateCaptionKey`, `.impactGlyphKey`.
- [x] Assert the source contains `BattlePlaybackMotion`, `BattlePlaybackField`, and
  `BattlePlaybackOverlays`.
- [x] Run the test and observe RED against the current page.
- [x] Commit the failing contract as `定义战斗播放边界契约`.

### Task 2: Add same-library view components

**Files:**
- Modify: `lib/features/battle/presentation/battle_playback_controller.dart`
- Create: `lib/features/battle/presentation/battle_playback_view.dart`
- Modify: `test/features/battle/battle_playback_controller_test.dart`

- [x] Add `part 'battle_playback_view.dart';` and imports for screen shake, BattleField and
  VFX layers to the controller library.
- [x] Rename `impactShakeAmplitude` to `_impactShakeAmplitude`; remove public resource getters;
  expose only `Animation<double> get beat => _beatCtrl`.
- [x] Add test-only queries: popup list for a slot, active trail/effect counts and beat animation
  state, all annotated `@visibleForTesting`.
- [x] Implement `BattlePlaybackMotion` with the exact existing closeup/shake AnimatedBuilders.
- [x] Implement `BattlePlaybackField` with existing BattleField + VFX Stack order and callbacks.
- [x] Implement `BattlePlaybackOverlays` with the existing three overlay keys/order.
- [x] Migrate controller tests to the test-only queries and run them GREEN.
- [x] Commit as `封装战斗播放动画资源`.

### Task 3: Rewire BattleScreen and viewport characterization

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`
- Modify: `test/features/battle/presentation/battle_playback_interface_test.dart`

- [x] Replace nested closeup/shake builders with `BattlePlaybackMotion`.
- [x] Replace BattleField/projectile/effect Stack with `BattlePlaybackField`.
- [x] Replace three direct overlay widgets with one positioned `BattlePlaybackOverlays`.
- [x] Rename remaining `_playback.beatCtrl` reads to `_playback.beat`.
- [x] Remove imports no longer owned by BattleScreen.
- [x] Add a full BattleScreen smoke loop for `Size(1280, 720)` and `Size(1440, 900)`, using
  short injected animation numbers and asserting `tester.takeException()` is null.
- [x] Run the architecture + viewport tests GREEN.
- [x] Commit as `收紧战斗屏播放消费接口`.

### Task 4: Verification and freeze

**Files:**
- Modify: `docs/superpowers/plans/2026-07-12-battle-playback-interface.md`

- [x] Run controller, interface, pause, start-paused, log, target-chip and command-console tests.
- [x] Run `flutter analyze --no-pub` and touched-file format check.
- [x] Run full `flutter test --no-pub` with filtered failure output.
- [x] Run `git diff --check` and confirm no capture/generated artifacts.
- [x] Record commands, counts, viewports, redline impact and real-window/Windows residual risk.
- [x] Commit recovery point and append `[READY] 完成战斗播放 Interface 收口`.

## Current recovery point

- Status: implementation and verification complete; branch is ready to freeze.
- Last completed: controller animation/VFX resources are private, BattleScreen consumes the
  three playback view widgets, and tests use only explicitly annotated debug queries.
- Verification:
  - Architecture contract first failed RED on direct `.attackControllers` access, then passed.
  - Targeted controller/interface/screen regression set: 44 tests passed.
  - `flutter analyze --no-pub`: 0 issues; touched-file format check: 0 changes.
  - Full suite rerun: success in 290,971 ms. The first full run exposed a one-time parallel
    Isar dylib download race; the completed local file was verified as a valid universal binary
    with the same SHA-256 as the other worktrees before the clean rerun.
  - BattleScreen widget smoke passed at 1280x720 and 1440x900 with no exceptions.
  - macOS visual route `battle_charge_break` was inspected at both viewports with no overflow,
    blank layer, or overlay obstruction; the 1440x900 capture needed one explicit Raise after
    the runner failed to foreground the window.
  - `git diff --check` passed and no capture/generated artifacts were added.
- Redline impact: no combat values, progression rules, narrative data, save schema, or online /
  offline behavior changed.
- Residual risk: static paused visual-route inspection does not fully characterize live animation
  feel or frame pacing; Windows performance/audio remain external-platform acceptance work.
- Next: commit this recovery point and append `[READY] 完成战斗播放 Interface 收口`.
- Blockers: none for the local scope.
