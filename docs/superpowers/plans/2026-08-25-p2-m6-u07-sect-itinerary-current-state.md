# P2-M6-U07 宗门行止当前态纵切

- taskId: `P2-M6-U07-SECT-ITINERARY-CURRENT-STATE`
- milestone: `M6`
- owner: `codex_root`
- base: `b63adc8fa41bef63b9bcd51668ec3c2e524059f4`
- branch: `codex/phase2-m6-u07-sect-itinerary-current-state-20260825`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u07-sect-itinerary-current-state`
- status: `in_progress`

## 目标与权威落点

二阶段方案将“宗门行止”冻结为宗门 Hub 的当前态摘要：展示真实当前掌门、门人占用、百草岭远征和断魂庄进度。本切片只读既有 `CurrentLeaderResolver`、`CharacterOccupancyService`、active 远征/断魂庄 provider，在 `SectHubScreen` 顶部提供首个生产摘要面板。

## 非目标

- 不新增、开始、召回或结算任何活动，不改占用规则。
- 不创建“已完成报告”或统一归来小结，不展示尚无权威占用源的疗伤/听剑。
- 不改宗门 Hub 既有七条路由与门控，不实现 U06 地点详情或 U14 参与矩阵。
- 不改 schema/saveVersion、YAML、TUNING、数值、奖励、经济、解锁或叙事。
- 不宣告 U07、M6 或二阶段完成。

## 精确白名单

- `lib/features/sect/domain/sect_itinerary_summary.dart`
- `lib/features/sect/application/sect_itinerary_provider.dart`
- `lib/features/sect/presentation/sect_itinerary_panel.dart`
- `lib/features/sect/presentation/sect_hub_screen.dart`
- `lib/shared/strings.dart`
- `test/features/sect/application/sect_itinerary_provider_test.dart`
- `test/features/sect/presentation/sect_itinerary_panel_test.dart`
- `test/features/main_menu/presentation/main_menu_sect_hub_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u07-sect-itinerary-current-state.md`
- `docs/audit/phase2_m6_u07_sect_itinerary_current_state_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## TDD 与验收门禁

1. 红测证明宗门 Hub 当前没有“宗门行止”面板，也没有掌门/占用/活动进度生产聚合。
2. 转绿后指针缺失、悬空或 provider 异常时 fail closed，不猜测掌门；正常时展示真实角色名和活动当前态。
3. 闭关/远征/断魂庄只从统一占用口与 active run 派生；七条原路由及门控不变。
4. 运行 provider/panel、宗门 Hub、占用/远征/断魂庄相邻回归、纸面对比、两层 analyze、独立语义复核和一次最终全量。
5. 仅在代码、测试、独立复核全绿后同步 audit/registry/真相源并生成 clean READY。

## 停止条件

若展示必须新增占用源、改动活动生命周期、引入完成报告或需要 schema/调优/解锁决策，立即标记精确 `BLOCKED`，不在本切片猜测新业务语义。
