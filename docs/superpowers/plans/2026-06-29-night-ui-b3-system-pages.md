# 2026-06-29 Night UI B3 System Pages

## Scope

- Worktree: `.worktrees/night-ui-b3-system-pages`
- Branch: `codex/night-ui-b3-system-pages`
- Base: `ec55031feffeb0d3aed705549ecfbc096ca01922`
- Constraint: UI / presentation / tests / plan only. No numbers, save schema, settlement logic, GDD, or CLAUDE changes.

## Checklist

1. Tower: replaced replay confirm dialog with `PaperDialog`; unified tower async error panels; changed tower cycle / sweep actions to `PlaqueButton`.
2. Seclusion: replaced early collect and battle-entry early-exit confirms with `PaperDialog + PlaqueButton`.
3. Taohua Island: unified loading/error/empty treatment using existing Wuxia UI components; added visual host route for island screen.
4. Baike / codex / weapon / encounter / zangjuange: unified Baike empty hint frame; verified existing visual host coverage for weapon codex, encounter codex, skill codex, lineage codex, and zangjuange.
5. Recruitment / sect dialogs: replaced accept/decline/sect event action dialogs and buttons with paper/plaque controls; moved missing-candidates copy into `UiStrings`.
6. Ascension / lineage: replaced ascension confirm dialog and final action button with paper/plaque controls; moved submitting copy into `UiStrings`.
7. Error / empty / loading: used `ErrorFallback`, `InkEmptyState`, and existing `InkLoadingIndicator` in touched screens.
8. Visual host: added `taohua_island` and `recruitment_dialog` routes; full visual suite now includes them.
9. Regression: ran formatter, build_runner generation, `flutter analyze`, targeted widget/debug tests.
10. Handoff: this document plus final response summarize changed files, validation, and residual risks.

## Verification

- `flutter pub run build_runner build --delete-conflicting-outputs`
  - Passed; generated missing Riverpod/Isar outputs in the worktree so analyze could run.
- `flutter analyze`
  - First run failed because generated `.g.dart` files were absent in the new worktree.
  - Second run after build_runner: `No issues found!`
- `flutter test test/features/tower/presentation/tower_floor_list_screen_test.dart test/features/seclusion/presentation/seclusion_map_list_screen_test.dart test/features/seclusion/presentation/active_retreat_exit_test.dart test/features/taohua_island/taohua_island_screen_test.dart test/features/baike/presentation/baike_screen_test.dart test/features/baike/presentation/baike_screen_navigation_test.dart test/features/weapon_codex/weapon_codex_screen_test.dart test/features/zangjuange/zangjuange_screen_test.dart test/features/debug/application/visual_acceptance_plan_test.dart test/features/sect/sect_screen_test.dart`
  - Passed.
- `flutter test test/features/debug/visual_route_test.dart --plain-name '批次3系统页路由 parse'`
  - Passed.

## Risks / Notes

- Full `test/features/debug/visual_route_test.dart` was not run end-to-end in this batch because its IsarCore download path failed in this environment during the broader test run. The new parse case was run directly and passed.
- Existing debug visual fixture files intentionally contain Chinese labels and preview strings; this batch did not migrate those because they follow existing visual-host fixture practice and are not production presentation copy.
- Some tappable cards still use local `InkWell` in older pages. This batch removed the most visible default Material buttons/dialogs in target pages; shared hover/ripple unification remains suitable for batch 1 if that branch standardizes reusable surfaces.

## Claude Merge / Visual Review Notes

- Start review at:
  - Tower replay dialog and sweep/cycle actions.
  - Seclusion active screen early collect dialog.
  - Taohua Island error/empty states and new `taohua_island` visual route.
  - Recruitment accept/decline dialogs and candidate action buttons.
  - Ascension confirm dialog and final action button.
  - Sect event dialog.
- Suggested visual routes:
  - `tower_floor_list`
  - `tower_cycle`
  - `seclusion_map_list`
  - `seclusion_active`
  - `taohua_island`
  - `recruitment_dialog`
  - `weapon_codex`
  - `encounter_codex`
  - `skill_codex`
  - `zangjuange`
