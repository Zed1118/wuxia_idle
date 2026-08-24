# P2-M6-U06 江湖地图第五地点（百草岭远征）纵切

- taskId: `P2-M6-U06-JIANGHU-MAP-EXPEDITION-LOCATION`
- milestone: `M6`
- owner: `codex_root`
- base: `0f7e576c1a9b5c77f0b4b68eaa00d4721d542a04`
- branch: `codex/phase2-m6-u06-jianghu-map-expedition-location-20260825`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u06-jianghu-map-expedition-location`
- status: `ready_reviewed`
- code candidate: `77292fb3ee897bcd727cb8072adad2f0d878c144`

## 目标

落实二阶段 §11.2“所有野外内容以世界地点出现”：在江湖地图加入“百草岭”第五个生产地点。可见性继续只读 `mainMenuSaveSnapshotProvider` 的既有 `jianghuJourneyUnlocked` 隐藏门；进行中状态只读 `activeExpeditionProvider`；点击复用既有 `ExpeditionOverviewScreen`。

“宗门 → 江湖远行”保留为派遣/管理入口，“江湖地图 → 百草岭”是世界地点入口；两者进入同一生产页，不复制业务状态。

## 非目标

- 不从宗门 Hub 删除远征管理入口。
- 不改远征解锁、人选、方针、节点、周目、占用、战斗、召回、伤势、奖励、记录或离线推进语义。
- 不迁移商店/声望或其他地点，不实现统一地点详情、亲战/差遣选择、敌人生态、奖励详情或宗门行止。
- 不改 schema/saveVersion、YAML、数值、概率、奖励、经济、解锁或 narrative。
- 不宣告 U06、U14、M5、M6 或二阶段完成。

## 精确白名单

- `lib/features/jianghu_map/presentation/jianghu_map_screen.dart`
- `test/features/jianghu_map/presentation/jianghu_map_expedition_location_test.dart`
- `test/features/jianghu_map/presentation/jianghu_map_screen_test.dart`
- `test/features/main_menu/presentation/main_menu_sect_hub_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u06-jianghu-map-expedition-location.md`
- `docs/audit/phase2_m6_u06_jianghu_map_expedition_location_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## 红绿与门禁

1. 红测证明既有门已解锁时地图仍没有百草岭地点、active 状态和生产路由。
2. 转绿后未解锁/加载未决/异常时地图隐藏百草岭；解锁后显示地点，active 远征显示已有深度或战败状态。
3. 地图与宗门两个入口都进入同一 `ExpeditionOverviewScreen`，不改该页写路径。
4. 覆盖 1280×720 / 1440×900，运行地图、宗门 Hub、远征相邻回归、纸面对比审计和两层 analyze。
5. 独立语义复核与全量通过后才同步审计/真相源并生成 clean READY。

## 停止条件

若世界地点必须改变 `jianghuJourneyUnlocked`、宗门管理入口、远征会话/恢复或需要 schema/调优决策，立即记录精确 `BLOCKED`；不在地图复制第二套远征状态。

## 完成证据

- 生产改动前红测 `1/4`，三项目标行为精确失败：无百草岭地点、无 active 深度、无生产路由；未解锁隐藏案例保持绿色。
- 地图与百草岭纵切 `16/16`，纸面对比 `4/4`，联合 `20/20`；地图、远征总览与宗门 Hub 联合 `38/38`，完整远征相邻域 `136/136`。
- `flutter analyze --no-pub lib test tool` 与根 `flutter analyze --no-pub` 均为 0 issue；最终全量 `5396/5396 PASS`。
- 独立语义复核 `P0=0 / P1=0 / P2=0`，额外导航联合 `79/79`，建议 READY；代码候选和评审候选均为 `77292fb3ee897bcd727cb8072adad2f0d878c144`。
