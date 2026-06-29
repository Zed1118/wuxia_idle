# 2026-06-29 Night UI Claude Merge Handoff

## Branches

Review only branches whose worktree is clean and whose tip commit starts with `[READY]`.

Suggested order:

1. `codex/night-ui-b1-foundation`
2. `codex/night-ui-b2-main-flow`
3. `codex/night-ui-b3-system-pages`
4. `codex/night-ui-b4-qa-safety`

Rationale:

- B1/B2/B3 likely touch concrete page visuals.
- B4 adds shared safety tools/tests and should merge after page deltas so its smoke checklist and reports reflect the final visual surface.

## B4 Summary

Adds the morning QA safety net:

- Debug hitbox overlay for visual route app: `--dart-define=HITBOX_DEBUG=true`.
- Smoke visual route checklist expanded across main menu, inventory, battle, technique, shop, seclusion, tower, and encyclopedia/codex.
- Local screenshot helper: `tools/visual_capture/visual_capture.sh`.
- Shared control hardening: tab semantics/cursor/keyboard, dialog action wrapping, ink entry semantics.
- Batch plan and audit notes in `docs/superpowers/plans/2026-06-29-night-ui-b4-qa-safety.md`.

## Suggested Morning Commands

```bash
git worktree list
git log --oneline -1 codex/night-ui-b1-foundation
git log --oneline -1 codex/night-ui-b2-main-flow
git log --oneline -1 codex/night-ui-b3-system-pages
git log --oneline -1 codex/night-ui-b4-qa-safety
```

For B4 specifically:

```bash
flutter analyze
flutter test test/features/debug/application/visual_acceptance_plan_test.dart
flutter test test/shared/widgets/wuxia_ui/plaque_button_test.dart test/shared/widgets/wuxia_ui/paper_dialog_test.dart test/shared/widgets/wuxia_ui/plaque_tab_test.dart test/shared/widgets/wuxia_ink_button_test.dart test/features/debug/hitbox_debug_overlay_test.dart
tools/visual_capture/visual_capture.sh --dry-run --suite smoke
```

Optional manual screenshots:

```bash
tools/visual_capture/visual_capture.sh --suite smoke --resolutions 1440x900
tools/visual_capture/visual_capture.sh --route main_menu --resolutions 1280x720 --hitbox
```

## Merge Risks

- If B1-B3 changed `VisualRoute` IDs or route builders, re-run `visual_acceptance_plan_test` after merging B4.
- If B1-B3 modified shared buttons/dialogs/tabs, check conflicts in `lib/shared/widgets/wuxia_ui/` and keep B4's semantics/hitbox tests.
- `visual_route_test.dart` may fail on machines where IsarCore cannot be downloaded during tests. Treat that as environment setup unless code changes touched Isar route construction.
- The screenshot helper is macOS-interactive; do not run it in non-GUI CI.

## Visual Review Checklist

- Capture `1280x720`, `1440x900`, `1920x1080`, and `2560x1080` for smoke routes.
- Check narrow 720p vertical crowding on battle/technique.
- Check ultrawide over-stretch on main menu, seclusion map, tower, and codex grids.
- Enable hitbox overlay on at least `main_menu`, `inventory`, and `shop`.
- Watch shallow paper panels for accidental `WuxiaColors.text*` usage; paper text should read as ink/muted, not pale gray.
