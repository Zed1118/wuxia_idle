# T9 核心 UI 截图包验收

日期: 2026-06-07  
分支: `codex/t11-inventory-section-header`

## 范围

本轮处理 T9「最终截图包与 UI 验收」第一批核心截图。覆盖主菜单、战斗、胜利、角色、仓库、装备详情、心法、主线、爬塔、闭关；已补齐 1280x720 与 1920x1080 双分辨率。

## 改动

- 生成 10 张 1280x720 核心 UI 截图和 1 张 contact sheet。
- 生成 10 张 1920x1080 核心 UI 截图和 1 张 contact sheet。
- 修复 `battle_boss_frame` / `battle_scene` visual route 顶部会显示“出版美术验收...”绿色 debug hint 的问题。
- `ScenarioLauncher.hint` 改为可空；调试菜单仍可传 hint，截图路由传 `null`。

## 截图清单

- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/00_contact_sheet_1280x720.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/01_main_menu_1280x720.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/02_battle_in_progress_1280x720.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/03_battle_victory_1280x720.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/04_character_panel_1280x720.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/05_inventory_1280x720.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/06_equipment_detail_1280x720.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/07_technique_panel_1280x720.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/08_mainline_stage_1280x720.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/09_tower_map_1280x720.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/10_seclusion_map_1280x720.png`

1920x1080 截图位于:

- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/00_contact_sheet_1920x1080.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/01_main_menu_1920x1080.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/02_battle_in_progress_1920x1080.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/03_battle_victory_1920x1080.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/04_character_panel_1920x1080.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/05_inventory_1920x1080.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/06_equipment_detail_1920x1080.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/07_technique_panel_1920x1080.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/08_mainline_stage_1920x1080.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/09_tower_map_1920x1080.png`
- `docs/handoff/codex_final_ui_screenshot_pack_2026-06-07/1920x1080/10_seclusion_map_1920x1080.png`

## 验收结论

总判: 第一批双分辨率核心截图通过，可作为 review 包；暂不标记为最终 Steam 商品图。

| 项 | 结果 | 说明 |
|---|---|---|
| 1280x720 尺寸 | 通过 | 10 张单图全部为 1280x720。 |
| 1920x1080 尺寸 | 通过 | 10 张单图全部为 1920x1080；需放到 LG 2560x1440 屏坐标 `{2000,100}` 截取。 |
| 红屏 / crash / loading 态 | 通过 | 闭关图首拍为 loading，已延长等待重拍。 |
| debug 字段 | 通过 | 战斗图首拍有绿色验收 hint，已修复并重拍。 |
| overflow | 通过 | contact sheet 与单图检查未见黄黑 overflow。 |
| 核心覆盖 | 通过 | 已覆盖 10 个核心 UI 面。 |
| 商品图适配 | 待二轮 | 胜利 preview 构图偏小，后续建议做全屏胜利候选图。 |

## 验证

```bash
flutter analyze lib/features/debug/presentation/battle_test_menu.dart lib/features/debug/presentation/visual_route_host.dart
flutter test test/features/debug/visual_route_test.dart
flutter build macos --debug --dart-define=VISUAL_ROUTE=battle_boss_frame
```

此外，本轮对各截图路由逐个执行了 `flutter build macos --debug --dart-define=VISUAL_ROUTE=<route>` 并打开 macOS app 截图。
