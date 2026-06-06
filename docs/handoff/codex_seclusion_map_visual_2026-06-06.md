# 闭关地图化视觉验收

## 结论

总判：通过。本轮只做闭关四屏视觉与布局包装，未修改闭关产出、解锁、开始、提前收功、收功结算语义。

| 验收点 | 结果 | 说明 |
|---|---:|---|
| 地图列表地点化 | 通过 | 5 张地图改为山水地点图册，含可闭关 / 进行中 / 境界不足状态。 |
| 准备闭关 | 通过 | 地图 hero、每小时预估产出、境界倍率、1/4/12 小时驻留牌、开始按钮同屏可读。 |
| 闭关中 | 通过 | 当前地图背景、宣纸进度面板、时间范围、进度章、提前收功按钮清楚。 |
| 收功结果 | 通过 | 收功战报卷轴化，5 维收益、中文装备名、领悟点提示、升层 banner 与返回按钮同屏。 |
| 1280x720 overflow | 通过 | 截图四屏未见黄色 overflow 条，关键文字未重叠。 |
| 地图图像加载 | 通过 | 5 张 `assets/maps/*.png` 均以原图比例 cover/背景加载，无拉伸变形。 |

## 截图清单

- `docs/handoff/codex_seclusion_map_visual_2026-06-06/01_seclusion_map_list.png`
- `docs/handoff/codex_seclusion_map_visual_2026-06-06/02_seclusion_setup.png`
- `docs/handoff/codex_seclusion_map_visual_2026-06-06/03_active_retreat.png`
- `docs/handoff/codex_seclusion_map_visual_2026-06-06/04_retreat_result.png`

## 验证命令

- `flutter test test/features/seclusion/presentation/seclusion_map_list_screen_test.dart test/features/seclusion/presentation/seclusion_e2e_test.dart test/features/seclusion/presentation/retreat_result_screen_test.dart`
- `flutter analyze lib/features/seclusion/presentation lib/features/debug/application/visual_route.dart lib/features/debug/presentation/visual_route_host.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=seclusion_map_list`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=seclusion_result`

## 备注

- 视觉截图由临时 widget capture 生成，因当前桌面处于 macOS 锁屏，无法直接截取真实窗口；临时 capture 已删除，未纳入提交。
- 为保证截图与 widget test 稳定加载地图位图，闭关地图图像加载改用 `ExactAssetImage`，不改变资源路径和显示语义。
