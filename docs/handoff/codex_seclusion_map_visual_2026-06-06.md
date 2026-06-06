# 闭关地图化全链路 UI 验收

日期：2026-06-06
分支：`codex/t11-inventory-section-header`

## 范围

本轮只做闭关系统四屏视觉与布局包装，不改闭关产出、解锁、开始、收功、提前收功、结算业务语义。

- 地图列表：改为 5 张山水地点大图卡，展示地图名、解锁/进行中状态与产出倾向。
- 准备闭关：加入地图 hero、每小时预估产出、境界倍率和 1/4/12 小时驻留牌。
- 闭关中：加入地图背景、半透明遮罩、宣纸进度面板和收功按钮。
- 收功结果：改为收功战报结构，展示实际挂机时长、收益、装备中文名、领悟点提示和突破 banner。
- Debug 路由：新增 `seclusion_map_list`、`seclusion_setup`、`seclusion_active`、`seclusion_result`。

## 结论

总判：通过。1280x720 等比例窗口下未发现 overflow；地图图像未变形；锁定/可进入/进行中状态清楚；开始/收功/返回按钮明确；收益与派生文字可读。

| 验收点 | 结果 | 说明 |
|---|---|---|
| 地图列表场所化 | 通过 | 5 张地图均使用 `assets/maps/*.png` 大图卡展示，状态与产出倾向可读。 |
| 准备页信息重组 | 通过 | hero、每小时产出、境界倍率、时长选择和开始按钮在同一视觉体系内。 |
| 闭关中沉浸化 | 通过 | 当前地图背景铺满，进度和提前收功按钮保留原逻辑。 |
| 收功结果战报化 | 通过 | 5 类收益路径可展示，装备掉落显示中文名，领悟点提示和升层 banner 可见。 |
| 业务语义不变 | 通过 | 未修改 `SeclusionService`、`RetreatSession`、`RetreatResult` 的业务流程。 |

## 截图清单

- `docs/handoff/codex_seclusion_map_visual_2026-06-06/01_seclusion_map_list.png`
- `docs/handoff/codex_seclusion_map_visual_2026-06-06/02_seclusion_setup.png`
- `docs/handoff/codex_seclusion_map_visual_2026-06-06/03_active_retreat.png`
- `docs/handoff/codex_seclusion_map_visual_2026-06-06/04_retreat_result.png`

## 验证

```bash
flutter test test/features/seclusion/presentation/seclusion_map_list_screen_test.dart test/features/seclusion/presentation/seclusion_e2e_test.dart test/features/seclusion/presentation/retreat_result_screen_test.dart
flutter analyze lib/features/seclusion/presentation lib/features/debug/application/visual_route.dart lib/features/debug/presentation/visual_route_host.dart test/features/seclusion/presentation/seclusion_map_list_screen_test.dart test/features/seclusion/presentation/seclusion_e2e_test.dart test/features/seclusion/presentation/retreat_result_screen_test.dart
flutter build macos --debug --dart-define=VISUAL_ROUTE=seclusion_map_list
flutter build macos --debug --dart-define=VISUAL_ROUTE=seclusion_setup
flutter build macos --debug --dart-define=VISUAL_ROUTE=seclusion_active
flutter build macos --debug --dart-define=VISUAL_ROUTE=seclusion_result
```

以上均通过。
