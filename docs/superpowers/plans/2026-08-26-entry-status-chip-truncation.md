# 入口状态徽章截断修复

## 目标

在不改文案、字号、字重、配色、padding、单行与 ellipsis 兜底的前提下，按全仓状态文案与 1280×720 实际 tile 几何测量结果放宽 `WuxiaInkButton` 状态徽章，并取得双视口真实 App 像素证据。

## 分支

`codex/p2-badge-truncation-fix-20260826`

## 验收标准

- [x] 生产接线：只改共享 `_InkButtonStatusChip`，江湖地图两处真实入口继续消费原有 `UiStrings.mainMenuLateGameLockedHint`。
- [x] 测量：盘点全部 7 个动态 status 生成分支；记录最长正常文案、字符数、渲染宽度、1280×720 tile 与文字栏可用宽度。
- [x] 几何门禁：最长已知静态状态在 1280×720 的真实江湖地图 tile 内 `RenderParagraph.didExceedMaxLines == false`；把宽度改回 116 时必红。
- [x] 验证：`dart format`、共享组件/江湖地图 targeted tests、`flutter analyze` 全绿。
- [x] 视觉：真实 macOS App 经生产导航到江湖地图，1280×720 与 1440×900 各留一张仓外截图，无截断、tile 变形或 RenderFlex 黄黑条。
- [x] 红线：不改数值、三系、在线/离线规则、文案或禁区文件；截图不进 Git。
- [x] 交付：中文动宾 `[READY]` tip，工作树 clean；说明生产路径、测试数、像素证据与残留风险。

## 任务切片

1. 核验分支、禁区与全仓 status 来源。
2. 量文案与 tile 几何，先落能在 116 下失败的门禁。
3. 推导并修改唯一组件宽度，格式化与 targeted 验证。
4. 跑真实 App 双视口视觉验收，提交并冻结。

## maxWidth 推导

- 全仓 43 处 `WuxiaInkButton` 引用与 7 个动态 `status` 生成入口中，最长正常分支是 21 字符的 `UiStrings.expeditionDefeatedBanner`。
- 在组件原样式 `fontSize: 10` / `FontWeight.w800` / 单行下，测试将局部 `Text.style` 与生产树中实际 `DefaultTextStyle` 合并，再用 `TextPainter` 实测完整自然宽度为 `215.25 px`。只读未合并的局部 style 会得到偏小的 `210 px`，不能作为生产布局上限。
- 徽章水平 padding 保持左右各 `8 px`，所以文字加显式 padding 是 `215.25 + 8 + 8 = 231.25 px`。组件现有 `Border.all` 还会以 decoration padding 形式占用左右各 `1 px`，完整的理论容器宽为 `231.25 + 2 = 233.25 px`；向上取整，`_InkButtonStatusChip.maxWidth` 最终取 `234`。`maxWidth` 是上限，不会把常规短状态强制拉宽。
- 1280×720 下该生产地图 tile 实测宽 `872 px`，`234 / 872 ≈ 26.8%`，仍剩余 `638 px`；上限远小于 tile 可用宽度，不需改 43 个使用点结构。
- `maxLines: 1` 与 `TextOverflow.ellipsis` 继续保留为未来超长文案的防御性兜底。

## 验证记录

- 几何 RED：旧值 `116` 下用例 `0/1`，`didExceedMaxLines == true`；最终测试再把上限临时改回 `116` 后同样必红（期望至少 `234`，实际 `116`）。
- 几何 GREEN：最终值 `234` 下精确用例 `1/1`；完整 `jianghu_map_screen_test.dart` 已纳入下表 `27/27`。
- `dart format lib/shared/widgets/wuxia_ink_button.dart test/features/jianghu_map/presentation/jianghu_map_screen_test.dart`：`Formatted 2 files (0 changed)`。
- `flutter analyze --no-pub lib/shared/widgets/wuxia_ink_button.dart test/features/jianghu_map/presentation/jianghu_map_screen_test.dart`：`No issues found`。
- 43 个调用点所在 presentation screen 的直接测试/导航测试，逐文件独立执行 `flutter test --no-pub <file>`：`28/28` 次出现 `All tests passed!`，合计 `220/220`。

| 测试文件 | 通过数 |
|---|---:|
| `test/features/baike/presentation/baike_screen_navigation_test.dart` | 3/3 |
| `test/features/debug/visual_route_shop_test.dart` | 6/6 |
| `test/features/jianghu_chronicle/presentation/pending_jianghu_affairs_screen_test.dart` | 3/3 |
| `test/features/jianghu_map/presentation/expedition_location_detail_screen_test.dart` | 7/7 |
| `test/features/jianghu_map/presentation/gauntlet_location_detail_screen_test.dart` | 7/7 |
| `test/features/jianghu_map/presentation/jianghu_map_expedition_location_test.dart` | 5/5 |
| `test/features/jianghu_map/presentation/jianghu_map_reputation_location_test.dart` | 4/4 |
| `test/features/jianghu_map/presentation/jianghu_map_screen_test.dart` | 27/27 |
| `test/features/jianghu_map/presentation/light_foot_location_detail_screen_test.dart` | 8/8 |
| `test/features/jianghu_map/presentation/mass_battle_location_detail_screen_test.dart` | 8/8 |
| `test/features/jianghu_map/presentation/reputation_location_detail_screen_test.dart` | 5/5 |
| `test/features/jianghu_map/presentation/tower_location_detail_screen_test.dart` | 8/8 |
| `test/features/main_menu/presentation/main_menu_continue_jianghu_test.dart` | 7/7 |
| `test/features/main_menu/presentation/main_menu_corner_tools_test.dart` | 6/6 |
| `test/features/main_menu/presentation/main_menu_gauntlet_gate_test.dart` | 4/4 |
| `test/features/main_menu/presentation/main_menu_inner_demon_entry_relocation_test.dart` | 2/2 |
| `test/features/main_menu/presentation/main_menu_jianghu_chronicle_hub_test.dart` | 5/5 |
| `test/features/main_menu/presentation/main_menu_jianghu_map_light_foot_location_test.dart` | 3/3 |
| `test/features/main_menu/presentation/main_menu_jianghu_map_mass_battle_location_test.dart` | 3/3 |
| `test/features/main_menu/presentation/main_menu_jianghu_map_tower_location_test.dart` | 3/3 |
| `test/features/main_menu/presentation/main_menu_martial_inventory_hub_test.dart` | 11/11 |
| `test/features/main_menu/presentation/main_menu_sect_hub_test.dart` | 12/12 |
| `test/features/main_menu/presentation/main_menu_test.dart` | 51/51 |
| `test/features/onboarding/founder_creation_flow_test.dart` | 6/6 |
| `test/features/sect/presentation/sect_itinerary_panel_test.dart` | 3/3 |
| `test/features/zangjuange/zangjuange_screen_test.dart` | 2/2 |
| `test/shared/widgets/wuxia_ink_button_height_test.dart` | 2/2 |
| `test/shared/widgets/wuxia_ink_button_test.dart` | 9/9 |

## 双视口证据

- 导航路径：真实 App 「选择江湖 → 最近存档 → 主菜单 → 江湖地图」，未使用 `VisualRoute`。
- `~/Desktop/挂机武侠视觉验收-20260826/G/G-江湖地图-1280x720.png`：原生内容视口 1280×720，窗口外框 1280×752，Retina 原始 PNG 2560×1504。
- `~/Desktop/挂机武侠视觉验收-20260826/G/G-江湖地图-1440x900.png`：原生内容视口 1440×900，窗口外框 1440×932，Retina 原始 PNG 2880×1864。
- 两张均目检：已渲染徽章文案完整，tile 高度/间距未变形，无 RenderFlex 黄黑条；两次 `flutter run` 日志均无 overflow 异常。截图位于仓外，Git 无截图变更。

## 残留风险

- 未修改 43 个使用点结构；未来新增超过当前 21 字符最长样本的状态时，仍会按保留的单行 ellipsis 防御性截断，届时需重新测量。
- 真实存档当时展示「已至7层 · 下8层」和两处「主线第六章通关后开放」；21 字符远征战败极值由真实江湖地图 widget 几何测试覆盖，未为了截图改写玩家存档。

## 当前恢复点

- 状态：READY
- 最后完成：已将唯一组件上限改为 234 px，几何门禁真红真绿，28 个相关测试文件合计 220/220，双视口生产导航与像素证据完成，禁区与截图未进 Git。
- 下一步：供 Claude 按 `CLAUDE.md §8.2` 进行合并前评审；本分支冻结，不推送、不合并 main。
- 已跑验证：见「验证记录」与「双视口证据」。
- 阻塞项：无。
