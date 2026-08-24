# P2-M6-U06 九霄塔统一地点详情纵切

- taskId: `P2-M6-U06-TOWER-LOCATION-DETAIL`
- milestone: `M6`
- owner: `codex_root`
- base: `7adb0d9eca6506f0bae1b3c1ae1aa61c71858ac0`
- branch: `codex/phase2-m6-u06-tower-location-detail-20260825`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u06-tower-location-detail`
- status: `in_progress`

## 目标与权威落点

按二阶段方案 §11.2 建立首个统一地点详情纵切。江湖地图的九霄塔地点先进入详情页，页面只读既有塔进度、下一层 `TowerFloorDef`、掉落表和 `CurrentLeaderResolver`，展示当前进度、推荐境界、敌方生态、核心收获、实际参与者、进入方式与预计占用；详情 CTA 再经原 `guardBattleEntry` 进入 `TowerFloorListScreen`。

## 非目标

- 不改塔层解锁、挑战、进度、首通/重打奖励或排行榜语义。
- 不新增派遣、自动化、持久活动占用或 U14 参与者矩阵决策。
- 不改 schema/saveVersion、YAML、TUNING、数值、概率、奖励、经济、解锁或叙事。
- 不宣告 U06、U14、M6 或二阶段完成。

## 精确白名单

- `lib/features/jianghu_map/domain/tower_location_detail.dart`
- `lib/features/jianghu_map/application/tower_location_detail_provider.dart`
- `lib/features/jianghu_map/presentation/tower_location_detail_screen.dart`
- `lib/features/jianghu_map/presentation/jianghu_map_screen.dart`
- `lib/shared/strings.dart`
- `test/features/jianghu_map/application/tower_location_detail_provider_test.dart`
- `test/features/jianghu_map/presentation/tower_location_detail_screen_test.dart`
- `test/features/jianghu_map/presentation/jianghu_map_screen_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u06-tower-location-detail.md`
- `docs/audit/phase2_m6_u06_tower_location_detail_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## TDD 与验收门禁

1. 红测证明地图点击仍跳过详情直达塔层列表，且不存在所需七类地点信息。
2. 正常态从生产配置展示下一层详情；登顶态明确无下一层但保留重打入口。
3. 领队指针缺失/悬空、塔配置空缺或 provider 异常均 fail closed，页面不显示进入 CTA。
4. CTA 仍经闭关战斗门禁；被门禁阻挡时不得进入塔层列表。
5. 运行 provider/详情/地图定向测试、塔与闭关相邻回归、纸面对比、两层 analyze、独立语义复核和最终全量。
6. 仅在代码、测试、独立复核全绿后同步 audit/registry/真相源并生成 clean READY。

## 停止条件

若实现必须新增长期占用、派遣写入、参与者选择、自动化、schema 或调优决策，立即记录精确 `BLOCKED` 并停止扩张，不在本切片猜测业务语义。
