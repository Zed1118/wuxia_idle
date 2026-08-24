# P2-M6-U06 江湖地图首地点（九霄塔）纵切

- taskId: `P2-M6-U06-JIANGHU-MAP-TOWER-LOCATION`
- milestone: `M6`
- owner: `codex_root`
- base: `ee51cf06baf96967b1db8882ced96f74be9ce833`
- branch: `codex/phase2-m6-u06-jianghu-map-tower-location-20260825`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u06-jianghu-map-tower-location`

## 目标

建立 U06 首个 production 地图纵切：在“继续江湖”一级卡片内提供次级“江湖地图”
动作，不新增第五个一级卡片；把九霄塔从主菜单平铺项迁为地图地点，保持既有进度状态、
战斗入口守卫与 `TowerFloorListScreen` 生产去向。

## 非目标

- 本批只迁九霄塔，不宣告轻功、群战、断魂庄、商店/声望等地点已迁。
- 不实现统一地点详情的参与者/差遣/生态/奖励完整字段，不关闭 U06/U14。
- 不改变塔解锁、进度、战斗、奖励、扫荡或周目语义。
- 不改 schema/saveVersion、YAML、数值、概率、奖励、经济、解锁或 narrative。
- 不宣告 U05、U06、M6 或二阶段完成。

## 精确白名单

- `lib/features/main_menu/presentation/main_menu.dart`
- `lib/features/jianghu_map/presentation/jianghu_map_screen.dart`
- `lib/shared/strings.dart`
- `test/features/main_menu/presentation/main_menu_jianghu_map_tower_location_test.dart`
- `test/features/main_menu/presentation/main_menu_test.dart`
- `test/features/jianghu_map/presentation/jianghu_map_screen_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u06-jianghu-map-tower-location.md`
- `docs/audit/phase2_m6_u06_jianghu_map_tower_location_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## 红绿与门禁

1. 红测证明主菜单仍平铺九霄塔且没有次级地图入口/地图 Screen。
2. 转绿后“继续江湖”主动作仍直达当前关，次级地图动作进入地图；主菜单不再平铺塔。
3. 地图地点显示数据派生塔进度，点击经原 battle guard 进入 `TowerFloorListScreen`。
4. 覆盖 1280×720、1440×900，运行主菜单、塔、地图相邻回归和两层 analyze。
5. 独立语义复核与全量通过后同步审计/真相源并生成 clean READY。

## 停止条件

若次级地图动作会抢占“继续江湖”主点击、塔迁移要求改变既有 admission，或地图壳必须
先拍板未冻结交互，则记录精确 `BLOCKED`；不以第五个一级卡片冒充四入口架构。
