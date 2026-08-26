# Phase 2 A1 四条真实导航链视觉验收（2026-08-26）

- 基线：`c799b964` + A0 `2363af37`；分支 `codex/p2-a-visual-acceptance-20260826`。
- 运行：`flutter run -d macos --debug`，第 1 卷真实存档；未使用 `VisualRoute`、fixture 或 widget test 代替真实导航。
- 尺寸：CGWindow 外框分别为 `1280×752` / `1440×932`，扣除 32 pt 标题栏后内容区为 `1280×720` / `1440×900`；Retina DPR=2，证据图物理像素分别为 `2560×1440` / `2880×1800`。
- 操作：从主菜单可见入口鼠标进入并点击；详情逐个用 AppBar `返回`（`Navigator.pop`）回地图，三个 Hub 逐个返回主菜单；返回后复核上一屏标题与主要入口。
- 判定：稳定帧检查溢出；Tab 后目视可见焦点环；无障碍树逐控件核对 label；鼠标逐控件核对 hover/cursor/热区并实际点击。主菜单“返回”指四条子链均能返回主菜单。
- 证据目录：`~/Desktop/挂机武侠视觉验收-20260826/A1/`（仓外，不提交）。

## 证据表（正好 22 行）

| 目标 | 视口 | 溢出 | 返回 | 键盘 | semantics | 鼠标 | 截图文件名 |
|---|---|---|---|---|---|---|---|
| `main_menu` | 1280×720 | PASS | PASS | PASS | PASS | PASS | `main_menu_1280x720.png` |
| `main_menu` | 1440×900 | PASS | PASS | PASS | PASS | PASS | `main_menu_1440x900.png` |
| `jianghu_map` | 1280×720 | PASS | PASS | PASS | PASS | PASS | `jianghu_map_1280x720.png` |
| `jianghu_map` | 1440×900 | PASS | PASS | PASS | PASS | PASS | `jianghu_map_1440x900.png` |
| `sect_hub` | 1280×720 | PASS | PASS | PASS | PASS | PASS | `sect_hub_1280x720.png` |
| `sect_hub` | 1440×900 | PASS | PASS | PASS | PASS | PASS | `sect_hub_1440x900.png` |
| `martial_hub` | 1280×720 | PASS | PASS | PASS | PASS | PASS | `martial_hub_1280x720.png` |
| `martial_hub` | 1440×900 | PASS | PASS | PASS | PASS | PASS | `martial_hub_1440x900.png` |
| `chronicle_hub` | 1280×720 | PASS | PASS | PASS | PASS | PASS | `chronicle_hub_1280x720.png` |
| `chronicle_hub` | 1440×900 | PASS | PASS | PASS | PASS | PASS | `chronicle_hub_1440x900.png` |
| `expedition_detail` | 1280×720 | PASS | PASS | PASS | PASS | PASS | `expedition_detail_1280x720.png` |
| `expedition_detail` | 1440×900 | PASS | PASS | PASS | PASS | PASS | `expedition_detail_1440x900.png` |
| `gauntlet_detail` | 1280×720 | PASS | PASS | PASS | PASS | PASS | `gauntlet_detail_1280x720.png` |
| `gauntlet_detail` | 1440×900 | PASS | PASS | PASS | PASS | PASS | `gauntlet_detail_1440x900.png` |
| `light_foot_detail` | 1280×720 | SKIP | SKIP | SKIP | SKIP | SKIP | SKIP（未生成） |
| `light_foot_detail` | 1440×900 | SKIP | SKIP | SKIP | SKIP | SKIP | SKIP（未生成） |
| `mass_battle_detail` | 1280×720 | SKIP | SKIP | SKIP | SKIP | SKIP | SKIP（未生成） |
| `mass_battle_detail` | 1440×900 | SKIP | SKIP | SKIP | SKIP | SKIP | SKIP（未生成） |
| `reputation_detail` | 1280×720 | PASS | PASS | PASS | PASS | PASS | `reputation_detail_1280x720.png` |
| `reputation_detail` | 1440×900 | PASS | PASS | PASS | PASS | PASS | `reputation_detail_1440x900.png` |
| `tower_detail` | 1280×720 | PASS | PASS | PASS | PASS | PASS | `tower_detail_1280x720.png` |
| `tower_detail` | 1440×900 | PASS | PASS | PASS | PASS | PASS | `tower_detail_1440x900.png` |

## FAIL 项

无。

## SKIP 项与阻塞

- `light_foot_detail`：两档均从“主菜单 → 江湖地图”抵达真实入口；入口显示“主线第六章通关后开放”且不可进入。缺少前置状态：主线第六章通关。涉及 `lib/features/jianghu_map/presentation/jianghu_map_screen.dart:52`、`:240`。
- `mass_battle_detail`：两档均从“主菜单 → 江湖地图”抵达真实入口；入口显示“主线第六章通关后开放”且不可进入。缺少前置状态：主线第六章通关。涉及 `lib/features/jianghu_map/presentation/jianghu_map_screen.dart:91`、`:259`。
- 未直接挂载详情、未修改存档或产品代码；按派单 `[BLOCKED]` 出口停止这两条链。剩余可执行截图 4 张，须先提供满足上述前置的真实存档状态。

## fixture 参数出处

| 参数 | 值 | 来源 file:line |
|---|---|---|
| 布局密度 fixture | 未设置；第 1 卷真实存档原样 | 不适用（未设置最长名字、最多条目或最大数值） |

## 小结

- 22 行：PASS 18，FAIL 0，SKIP 4；交付状态：`[BLOCKED][CODEX][P2-A1]`。
