# P2-M6-U06 江湖地图第四地点（断魂庄）纵切

- taskId: `P2-M6-U06-JIANGHU-MAP-GAUNTLET-LOCATION`
- milestone: `M6`
- owner: `codex_root`
- base: `cec23572e10bb3f47eff7a1875f6b4a6abec490a`
- branch: `codex/phase2-m6-u06-jianghu-map-gauntlet-location-20260825`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u06-jianghu-map-gauntlet-location`
- status: `ready_reviewed`
- code candidate: `c06489f2ec79caf7766959a3431f75da6b228ac2`

## 目标

延续 U06 生产地图架构：把“断魂庄”从主菜单平铺项迁为江湖地图第四个生产地点。地点可见性继续只读 `mainMenuSaveSnapshotProvider` 的既有 `jianghuJourneyUnlocked` 隐藏门；进行中状态只读 `activeGauntletProvider`；点击仍进入既有 `GauntletLoadoutScreen`，由原页面处理新建与崩溃恢复。

## 非目标

- 不改断魂庄解锁、断魂帖、三关链、周目、阵型、参与者、补给、战斗、奖励或记录语义。
- 不开放断魂庄前台 bot 或代选奖励。
- 不同批迁移远征、商店/声望或其他地点。
- 不实现统一地点详情、亲战/差遣、敌人生态、奖励详情或宗门行止。
- 不改 schema/saveVersion、YAML、数值、概率、奖励、经济、解锁或 narrative。
- 不宣告 U06、U14、M5、M6 或二阶段完成。

## 精确白名单

- `lib/features/main_menu/presentation/main_menu.dart`
- `lib/features/jianghu_map/presentation/jianghu_map_screen.dart`
- `test/features/main_menu/presentation/main_menu_gauntlet_gate_test.dart`
- `test/features/main_menu/presentation/main_menu_test.dart`
- `test/features/jianghu_map/presentation/jianghu_map_screen_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u06-jianghu-map-gauntlet-location.md`
- `docs/audit/phase2_m6_u06_jianghu_map_gauntlet_location_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## 红绿与门禁

1. 红测证明解锁后断魂庄仍平铺在主菜单、地图没有断魂庄地点和生产路由。
2. 转绿后主菜单不再平铺断魂庄；未解锁/加载未决时地图继续隐藏，既有解锁后才显示。
3. 地点显示 active 庄局的真实关次/阶段状态，点击仍进入 `GauntletLoadoutScreen` 并由原页面处理恢复。
4. 覆盖 1280×720 / 1440×900，运行主菜单、地图、断魂庄相邻回归、纸面对比审计和两层 analyze。
5. 独立语义复核与全量通过后才同步审计/真相源并生成 clean READY。

## 停止条件

若迁移必须改变 `jianghuJourneyUnlocked`、庄局恢复、参与者、奖励或需要 schema/调优决策，立即记录精确 `BLOCKED`；不在地图复制第二套断魂庄状态。

## 完成证据

- 修正测试 fixture 后的真实红测为 `1/4`，其中三项目标行为各自精确失败；首次因未加载测试仓库而无效的运行不计证据。
- 断魂庄门控与地图 `15/15`，纸面对比 `4/4`，联合 `19/19`；地图、断魂庄与主菜单联合 `66/66`，相邻域 `299/299`。
- `flutter analyze --no-pub lib test tool` 与根 `flutter analyze --no-pub` 均为 0 issue；最终全量 `5391/5391 PASS`。
- 独立语义复核 `P0=0 / P1=0 / P2=0`，建议 READY；代码候选和评审候选均为 `c06489f2ec79caf7766959a3431f75da6b228ac2`。
