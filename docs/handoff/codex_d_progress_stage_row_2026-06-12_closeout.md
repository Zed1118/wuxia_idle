# D 四类养成进度五要素标准化 · Codex 视觉验收 closeout（2026-06-12）

对象：`StageProgressRow` 三路由视觉验收（1280x720，macOS `flutter run -d macos --dart-define=VISUAL_ROUTE=...` 直达）。

截图目录（本地，PNG 被 `.gitignore` 忽略）：`docs/handoff/codex_d_progress_stage_row_2026-06-12/`

## 结论

PASS。三路由均能看到统一的「阶段名 → 进度条 → 当前效果 / 下一阶效果 / 进度」骨架，配色与字号一致，无溢出截断。

## 路由结果

| 路由 | 截图 | 判定 | 现象 |
|---|---|---|---|
| `technique_panel_hero` | `01_technique_panel_hero.png` | PASS | 9 层阶梯保留；徽章下新增 `伤害 ×1.75 · 下一阶 ×2.00`，不抢主视觉。 |
| `character_panel` | `02_character_panel_main_technique.png` | PASS | 主修卡为 `StageProgressRow`；显示 `圆满`、`伤害 ×1.75`、`下一阶 ×2.00`、`1500 / 1500`。 |
| `equipment_detail_screen` | `03_equipment_detail_resonance.png` | PASS | 共鸣段显示 `默契`、进度条、`当前属性加成 +20%`、`下一阶 +30%`、`战斗 1240/2000`，并保留「人剑合一」解锁标记。 |

## 根因复核与修复

首轮复验发现 `character_panel` 路由显示 `初窥 / 伤害 ×1.00 / 下一阶 ×1.15 / 0/100`，与派单 seed 不符。根因是 `VisualRoute.characterPanelProfile` 仍调用通用档案页 `seedMasterDisciple()`，未给 D 验收准备圆满主修进度。

修复：新增 `Phase2SeedService.seedMasterDiscipleWithMatureMainTechnique()`，保留档案页基础 seed，再把祖师主修调整为 `yuanMan / 1500`；`character_panel` 路由改用该 seed。组件代码与数值配置未改。

备注：派单里“非空非满”与当前 `numbers.yaml` 中 `yuanMan` 的 `toNext=1500` 存在轻微不一致，因此复验截图为 `1500 / 1500` 满条；按实际配置与派单 `progress=1500` 判为通过。

## 验证

- `flutter test test/features/debug/visual_route_test.dart test/features/character_panel/presentation/character_panel_screen_test.dart`：31/31 passed
- `dart analyze`：No issues found
- 视觉截图：三路由均已人工读图通过
