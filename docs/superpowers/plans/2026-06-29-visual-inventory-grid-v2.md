# Equipment Grid Visuals V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish equipment inventory grid cells so tier frames, locked/equipped/heritage/protected marks, hover/selected states, and information hierarchy read more like a weapon display case.

**Architecture:** Keep business behavior in `InventoryScreen` unchanged and route existing visual states into the shared `ItemSlot`. `ItemSlot` owns presentation-only drawing: tier frame, status strips, seals, hover/pressed feedback, and lock overlay. UI text remains centralized in `UiStrings`.

**Tech Stack:** Flutter Desktop, Riverpod, existing Wuxia UI tokens, widget tests.

---

### Task 1: Inspect Boundaries And Existing State Wiring

**Files:**
- Read: `AGENTS.md`
- Read: `CLAUDE.md`
- Read: `docs/spec/rejected_task_registry.md`
- Read: `lib/features/inventory/presentation/inventory_screen.dart`
- Read: `lib/shared/widgets/wuxia_ui/item_slot.dart`
- Read: `lib/shared/strings.dart`
- Read: `test/features/inventory/presentation/inventory_screen_test.dart`

- [x] **Step 1: Confirm worktree and branch**

Run: `pwd && git status --short --branch`
Expected: path ends in `.worktrees/visual-inventory-grid-v2`, branch is `codex/visual-inventory-grid-v2`, and no unrelated dirty files are present.

- [x] **Step 2: Read required project instructions**

Run: `sed -n '1,220p' AGENTS.md`, `sed -n '1,620p' CLAUDE.md`, `sed -n '1,260p' docs/spec/rejected_task_registry.md`
Expected: constraints noted: visual-only, no rejected task features, no business/schema/numbers changes, UI text in `UiStrings`.

- [x] **Step 3: Inspect inventory visual path**

Use CodeGraph and targeted file reads to identify that `_EquipmentGridTile` sends state to `ItemSlot`.
Expected: implementation target is `ItemSlot`, with `inventory_screen.dart` only passing current equipment state.

### Task 2: Add Presentation-Only Equipment Slot Visuals

**Files:**
- Modify: `lib/shared/widgets/wuxia_ui/item_slot.dart`
- Modify: `lib/features/inventory/presentation/inventory_screen.dart`
- Modify: `lib/shared/strings.dart`

- [x] **Step 1: Add optional visual metadata to `ItemSlot`**

Add optional `tierLabel`, `protected`, and semantic status label fields. Do not add callbacks or filtering inputs.

- [x] **Step 2: Replace flat frame with layered display case styling**

Render a tier-colored frame, inner paper panel, subdued rack line, hover/pressed overlay, high-tier glow, and tier label strip.

- [x] **Step 3: Strengthen visual marks**

Show heritage, locked, protected, and equipped states as clearer seals/strips using existing state values. Locked realm overlay remains purely visual and keeps the existing `lockText`.

- [x] **Step 4: Pass existing state from `_EquipmentGridTile`**

Use `EnumL10n.equipmentTier(eq.tier)` for the tier label, existing `eq.isLineageHeritage`, existing `eq.isLocked`, existing `equipped`, and existing protected semantics from those fields. Do not change `organizeInventoryEquipments`, `isEquipmentEquippedBySlot`, disposal protection, or navigation.

### Task 3: Add Focused Widget Assertions

**Files:**
- Modify: `test/features/inventory/presentation/inventory_screen_test.dart`

- [x] **Step 1: Add visual state assertions**

Assert that a tile can show tier label, equipped badge, locked label, and heritage/protection icons together without exceptions.

- [x] **Step 2: Add conventional viewport smoke**

Pump inventory at `1280x720` and `1440x900` with mixed equipment states and assert core labels/icons are visible.

### Task 4: Verify And Freeze

**Files:**
- Modify: `docs/superpowers/plans/2026-06-29-visual-inventory-grid-v2.md`

- [x] **Step 1: Run required verification**

Run:
`dart run build_runner build --delete-conflicting-outputs`
`flutter test test/features/inventory/presentation/inventory_screen_test.dart`
`flutter analyze`
`git diff --check`

- [x] **Step 2: Update this recovery point**

Record status, files changed, verification results, and risks below.

- [x] **Step 3: Commit and mark ready**

Commit with `feat(inventory): polish equipment grid visuals`, then add a ready tip marker if needed so the final branch tip starts with `[READY]`.

---

## Current Recovery Point

Status: complete and marked ready for review.
Last completed: feature commit `952e0764` and `[READY]` tip marker.
Next step: Claude/main-window review and merge gate.
Verification run:
- `dart run build_runner build --delete-conflicting-outputs` passed; generated 112 local outputs. Tool warned that `--delete-conflicting-outputs` is ignored by this build_runner version.
- Initial pre-generation `flutter test ...` failed because generated `.g.dart` files were absent in this worktree.
- `flutter test test/shared/widgets/wuxia_ui/item_slot_test.dart test/features/inventory/presentation/inventory_screen_test.dart` passed: 38/38.
- `flutter test test/features/inventory/presentation/inventory_screen_test.dart` passed: 29/29.
- Supplemental `flutter test test/features/inventory/presentation` failed in `bulk_disposal_dialog_test` setUpAll: `IsarError: Could not download IsarCore library`; unrelated tests in that run reached 55 passing before the suite failed.
- `flutter analyze` passed: no issues found.
- `git diff --check` passed.
Blocked: none.
