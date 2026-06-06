# Codex 路线图第一切片交接（2026-06-06）

## 范围

本批只做主线 / 爬塔的“顶部扫读概览”，不重写现有流程：

- 主线章节列表顶部新增「江湖路引」路线条，展示 6 章的已通 / 进行中 / 锁定状态。
- 爬塔层列表顶部新增「九霄塔势」横向 30 层节点，Boss 层以方形节点与“小 / 大”标记区分。
- 原章节卡、爬塔层列表、挑战 / 锁定 / 重打流程保持原行为。
- 新增 debug-only 视觉直达路由 `tower_floor_list`，用于稳定截图验收。

## 改动文件

- `lib/features/mainline/presentation/chapter_list_screen.dart`
- `lib/features/tower/presentation/tower_floor_list_screen.dart`
- `lib/features/debug/application/visual_route.dart`
- `lib/features/debug/presentation/visual_route_host.dart`
- `lib/shared/strings.dart`
- `test/features/mainline/presentation/chapter_list_screen_test.dart`
- `test/features/tower/presentation/tower_floor_list_screen_test.dart`

## 验证

- `flutter test test/features/debug/visual_route_test.dart test/features/mainline/presentation/chapter_list_screen_test.dart test/features/tower/presentation/tower_floor_list_screen_test.dart`
- `flutter analyze lib/shared/strings.dart lib/features/debug/application/visual_route.dart lib/features/debug/presentation/visual_route_host.dart lib/features/mainline/presentation/chapter_list_screen.dart lib/features/tower/presentation/tower_floor_list_screen.dart test/features/debug/visual_route_test.dart test/features/mainline/presentation/chapter_list_screen_test.dart test/features/tower/presentation/tower_floor_list_screen_test.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=chapter_list`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=tower_floor_list`

## 截图

- `docs/handoff/codex_route_map_first_slice_2026-06-06/01_mainline_route_map.png`
- `docs/handoff/codex_route_map_first_slice_2026-06-06/02_tower_spine.png`

## 结论

通过。两处概览均已进入视觉验收包，当前没有红屏、overflow 或原流程回归；后续可在此基础上继续做更完整的空间化路线图 / 塔身图。
