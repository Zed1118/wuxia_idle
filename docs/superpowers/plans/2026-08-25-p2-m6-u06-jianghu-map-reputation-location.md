# P2-M6-U06 江湖地图声望地点纵切

- taskId: `P2-M6-U06-JIANGHU-MAP-REPUTATION-LOCATION`
- milestone: `M6`
- owner: `codex_root`
- base: `0dc51a34544481a41b1a8212ffe182b9c0d06e96`
- branch: `codex/phase2-m6-u06-jianghu-map-reputation-location-20260825`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u06-jianghu-map-reputation-location`
- status: `ready_reviewed`
- registration_commit: `b48b3b4533cedc4c7b89f71d84a69c74bf6e500f`
- code_candidate_commit: `898a67e25bb4168a0a90e0b2662681532a2f651c`
- reviewed_candidate_commit: `898a67e25bb4168a0a90e0b2662681532a2f651c`

## 目标与权威落点

冻结信息架构要求主菜单保持“继续江湖 / 宗门 / 武学与行囊 / 江湖纪事”四个一级入口，并将野外内容收入江湖地图。当前“江湖恩怨”仍是主菜单平铺卡片。本切片将它迁为江湖地图第六个生产地点，保持既有第一章末关门槛和 `ReputationPanelScreen` 去向。

## 非目标

- 不迁移江湖商店，不实现统一地点详情、宗门行止或 U14 全矩阵。
- 不改声望阶段、门派关系、NPC 仇敌、任务、奖励、数值或文案。
- 不改 `PROGRESSIVE-UNLOCK-01`；继续使用既有 `kFirstChapterFinalStageId` 门槛，未解锁仍显示锁定卡。
- 不改 schema/saveVersion、YAML、TUNING、云服务、网络或发布配置。
- 不宣告 U05、U06、U14、M6 或二阶段完成。

## 精确白名单

- `lib/features/main_menu/presentation/main_menu.dart`
- `lib/features/jianghu_map/presentation/jianghu_map_screen.dart`
- `test/features/jianghu_map/presentation/jianghu_map_reputation_location_test.dart`
- `test/features/jianghu_map/presentation/jianghu_map_screen_test.dart`
- `test/features/main_menu/presentation/main_menu_test.dart`
- `test/features/main_menu/presentation/main_menu_martial_inventory_hub_test.dart`
- `test/features/jianghu/reputation_panel_screen_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u06-jianghu-map-reputation-location.md`
- `docs/audit/phase2_m6_u06_jianghu_map_reputation_location_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## TDD 与验收门禁

1. 红测证明主菜单仍平铺“江湖恩怨”，地图尚无该地点与生产路由。
2. 转绿后主菜单不再平铺该卡；地图在原门槛前显示锁定且不导航，门槛后启用并真实 push `ReputationPanelScreen`。
3. 宗门 Hub 仍消费同一社交门槛；江湖商店和已有五个地点不变。
4. 运行新纵切、主菜单/地图/声望相邻回归、纸面对比、两层 analyze、独立语义复核和一次最终全量。
5. 仅在代码、测试、独立复核全绿后同步 audit/registry/真相源并生成 clean READY。

## 停止条件

若迁移必须改变社交解锁门槛、声望算法、数值/奖励、schema 或需要新的 hidden/heard/open 决策，立即标记精确 `BLOCKED`，不用本切片猜测新规则。

## 完成证据

- 真实红测：`0/4`，分别精确证明主菜单仍平铺声望，地图缺少声望地点、门槛和真路由。
- 聚焦声望地点/地图/主菜单/原声望面板/纸面对比：`87/87 PASS`。
- 主菜单 + 江湖地图 + 江湖声望 + 商店相邻域：`201/201 PASS`。
- scoped analyze 与 root `flutter analyze`：`0 issue`；`git diff --check` 通过。
- 独立只读复核：`94/94 PASS`，`P0=0 / P1=0 / P2=0`，建议 `READY`。
- 最终 root full suite：`5402/5402 PASS`。
- 该证据只支持声望地点归位，不晋升 U06、U14、M6 或二阶段整体状态。
