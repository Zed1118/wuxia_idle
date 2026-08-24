# P2-M6-U06 江湖地图第二地点（轻功试炼）纵切

- taskId: `P2-M6-U06-JIANGHU-MAP-LIGHT-FOOT-LOCATION`
- milestone: `M6`
- owner: `codex_root`
- base: `269e1baaad6b89544c90c66b8f86815ecb8c54ca`
- branch: `codex/phase2-m6-u06-jianghu-map-light-foot-location-20260825`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u06-jianghu-map-light-foot-location`
- status: `in_progress`

## 目标

延续 U06 生产地图架构：把“轻功试炼”从主菜单平铺项迁为江湖地图第二个生产地点。地点锁定和进度只从现有 `MainlineProgress` + `LightFootService` + production config 派生；点击仍经 `guardBattleEntry` 进入既有 `LightFootScreen`。

## 非目标

- 不改轻功 Ch6 解锁、五关链、周目、地形、战斗、奖励或记录语义。
- 不同批迁移群战、断魂庄、远征、商店/声望或其他地点。
- 不实现统一地点详情、参与者/差遣、敌人生态、奖励详情或宗门行止。
- 不改 schema/saveVersion、YAML、数值、概率、奖励、经济、解锁或 narrative。
- 不宣告 U06、U14、M5、M6 或二阶段完成。

## 精确白名单

- `lib/features/main_menu/presentation/main_menu.dart`
- `lib/features/jianghu_map/presentation/jianghu_map_screen.dart`
- `lib/shared/strings.dart`
- `test/features/main_menu/presentation/main_menu_jianghu_map_light_foot_location_test.dart`
- `test/features/main_menu/presentation/main_menu_test.dart`
- `test/features/jianghu_map/presentation/jianghu_map_screen_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u06-jianghu-map-light-foot-location.md`
- `docs/audit/phase2_m6_u06_jianghu_map_light_foot_location_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## 红绿与门禁

1. 红测证明主菜单仍平铺轻功，地图没有轻功地点。
2. 转绿后主菜单不再平铺轻功；地图在新档显示原 Ch6 锁定语义，解锁后显示 production 五关进度。
3. 地点点击仍经既有 battle guard 进入 `LightFootScreen`。
4. 覆盖 1280×720 / 1440×900，运行主菜单、地图、轻功相邻回归、纸面对比审计和两层 analyze。
5. 独立语义复核与全量通过后才同步审计/真相源并生成 clean READY。

## 停止条件

若迁移必须改变 Ch6 门槛、轻功链、准入或战斗去向，立即记录精确 `BLOCKED`；不在地图复制第二套解锁真相源。
