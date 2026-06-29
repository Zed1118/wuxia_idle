# 2026-06-29 Night UI Batch 2: Main Flow

## Scope

- Branch: `codex/night-ui-b2-main-flow`
- Worktree: `.worktrees/night-ui-b2-main-flow`
- Baseline: `ec55031feffeb0d3aed705549ecfbc096ca01922`
- Constraint: UI/presentation, widget tests, and this plan only. No `numbers.yaml`, save schema, settlement logic, `GDD.md`, or `CLAUDE.md` changes.

## Checklist

1. `main-menu`: adjusted page-level section spacing, max width, and softened section shadows so the entry matrix reads as grouped desktop controls.
2. `battle-command-bar`: replaced top bar default 48px `IconButton` usage with 36px fixed visual/hitbox buttons; widened focus chips and skill command cards.
3. `stage-list`: added a stable minimum height and restrained shadow to stage cards; changed the intel icon to a visible 36px action target.
4. `victory-dialog`: fixed continue/confirm buttons to wood-plaque actions; increased small reward action buttons to a 36px minimum.
5. `character-panel`: aligned equipment slot click feedback with the visible slot shell through page-local transparent `Material` + matching radius.
6. `inventory-grid`: raised filter chips to 36px, widened equipment summary cards, and gave batch/shop/view actions stable minimum widths.
7. `equipment-detail`: fixed primary/secondary action rows to 42px high buttons while keeping strengthen/forge/lock above sell/disassemble.
8. `technique-panel`: made set-main/refine actions explicit 38px bordered action areas; no logic changes to dispel/refine.
9. `shop-screen`: gave each shelf item a subtle card boundary; fixed buy buttons to 96x42 and expanded shelf filter chip padding.
10. `batch2-visual-smoke`: no new route required. Existing visual host covers `StageListScreen`, `BattleScreen(startPaused/debugDragPreview)`, `CharacterPanelScreen`, `InventoryScreen`, `TechniquePanelScreen`, and `ShopScreen`.

## Files Changed

- `lib/features/main_menu/presentation/main_menu.dart`
- `lib/features/battle/presentation/battle_screen.dart`
- `lib/features/battle/presentation/victory_overlay.dart`
- `lib/features/mainline/presentation/stage_list_screen.dart`
- `lib/features/mainline/presentation/stage_victory_dialog.dart`
- `lib/features/character_panel/presentation/character_panel_screen.dart`
- `lib/features/inventory/presentation/inventory_screen.dart`
- `lib/features/inventory/presentation/equipment_detail_screen.dart`
- `lib/features/technique_panel/presentation/technique_panel_screen.dart`
- `lib/features/shop/presentation/shop_screen.dart`
- `docs/superpowers/plans/2026-06-29-night-ui-b2-main-flow.md`

## Verification

- `dart run build_runner build --delete-conflicting-outputs`
  - Passed; generated 112 ignored outputs for local verification.
- `flutter analyze`
  - Passed; no issues found.
- Targeted widget tests:
  - `flutter test test/features/main_menu/presentation/main_menu_test.dart test/features/battle/presentation/battle_command_console_test.dart test/features/battle/presentation/victory_overlay_test.dart test/features/mainline/presentation/stage_list_screen_test.dart test/features/mainline/presentation/stage_victory_dialog_test.dart test/features/character_panel/presentation/character_panel_screen_test.dart test/features/inventory/presentation/inventory_screen_test.dart test/features/inventory/presentation/equipment_detail_screen_test.dart test/features/technique_panel/presentation/technique_panel_screen_test.dart test/features/shop/shop_screen_test.dart`
  - Passed; 222 tests.

## Manual Visual Smoke Route

1. Launch debug visual host or Phase 2 menu after local build runner.
2. Main menu: check grouped entry matrix, status summary, and right-top quit button at 1280x720 and 1440x900.
3. Mainline: open chapter 1 stage list; inspect journey map, card shadow, intel icon, stage status badge, and sweep entry.
4. Battle: use start-paused or drag-preview visual route; inspect top pause/log/surrender icon buttons, focus chips, skill cards, and fast-forward button.
5. Victory: run a mainline victory route; inspect full-screen continue button, stage victory confirm button, reward rows, lock/source/later actions.
6. Character and inventory: inspect character equipment slots, inventory filters, protected seals, bulk disposal entry, and equipment detail action rows.
7. Technique and shop: inspect set-main/refine action areas, shelf filters, shelf item cards, and buy button disabled/enabled states.

## Risks

- Batch 1 may later centralize shared button sizing; this branch avoids depending on it and keeps adjustments page-local.
- No screenshot automation was added in this batch. Coverage is analyze + targeted widget tests + recorded manual visual route.
- `build_runner` output is required in fresh worktrees for verification but remains gitignored and should not be committed.
