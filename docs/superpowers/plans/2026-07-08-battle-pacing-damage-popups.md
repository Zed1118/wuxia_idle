# Battle Pacing And Damage Popup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make first-clear mainline fights readable and make critical damage visually distinct from normal damage.

**Architecture:** Keep combat math deterministic and unchanged for this batch. Add a presentation-only readable pacing flag to `BattleScreen`/`BattlePlaybackController`, wired only from mainline first-clear battles. Add richer `DamagePopupData` display logic so normal hits stay black numeric values while critical hits render as vermilion brush-stroke callouts with explicit “暴击 … 伤害” text.

**Tech Stack:** Flutter, Riverpod, existing `AnimationNumbers`, existing `DamagePopup` widget tests and battle playback controller tests.

---

### Task 1: Damage Popup Text And Style

**Files:**
- Modify: `lib/shared/strings.dart`
- Modify: `lib/features/battle/presentation/battle_playback_controller.dart`
- Modify: `lib/features/battle/presentation/damage_popup.dart`
- Test: `test/features/battle/presentation/damage_popup_test.dart`
- Test: `test/features/battle/battle_playback_controller_test.dart`

- [ ] Add `UiStrings.criticalDamagePopup(int damage) => '暴击 $damage 伤害'`.
- [ ] Change `_buildPopupData` so critical hits use `UiStrings.criticalDamagePopup(result.finalDamage)` and normal hits keep `result.finalDamage.toString()`.
- [ ] In `DamagePopup`, render `PopupType.critical` with a compact vermilion brush-style backing and stronger text shadow; keep `PopupType.normal` as plain black numeric text.
- [ ] Update widget/controller tests to assert critical text and normal text.

### Task 2: First-Clear Readable Battle Pacing

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`
- Modify: `lib/features/battle/presentation/battle_playback_controller.dart`
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart`
- Test: `test/features/battle/battle_playback_controller_test.dart`
- Test: `test/features/battle/presentation/battle_screen_defer_victory_test.dart`

- [ ] Add `readablePacing` to `BattleScreen`, default false.
- [ ] Add `readablePacing` to `BattlePlaybackController`, default false, and use it only for non-fast-forward playback.
- [ ] For readable pacing, use at least `1800ms` per normal action and a minimum victory handoff delay around `1200ms`, so very short first-clear fights still leave a readable final beat.
- [ ] Wire `_StageBattleHost` to pass `readablePacing: firstClear` for mainline battles.
- [ ] Keep `startFastForward`/sweep untouched.

### Task 3: Verification

**Files:**
- Existing tests only.

- [ ] Run `dart format` on modified files.
- [ ] Run `flutter analyze`.
- [ ] Run targeted tests:
  `flutter test --no-pub -j1 test/features/battle/presentation/damage_popup_test.dart test/features/battle/battle_playback_controller_test.dart test/features/battle/presentation/battle_screen_defer_victory_test.dart`
- [ ] Run `git diff --check`.
