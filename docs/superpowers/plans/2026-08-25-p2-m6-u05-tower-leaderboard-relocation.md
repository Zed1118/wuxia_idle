# P2-M6-U05 九霄塔排行榜归位纵切

- taskId: `P2-M6-U05-TOWER-LEADERBOARD-RELOCATION`
- milestone: `M6`
- owner: `codex_root`
- base: `79c5e96c6e99bcb519ac17e27ad51afb673b8601`
- branch: `codex/phase2-m6-u05-tower-leaderboard-relocation-20260825`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u05-tower-leaderboard-relocation`
- status: `in_progress`

## 目标与权威落点

GDD §8.2 明确“通关层数决定排行榜位置”，现有 `LeaderboardScreen` 也只读 `towerProgressProvider`。江湖纪事 Hub 收拢提交从主菜单删除排行榜后，未提供新的生产入口。本切片将“排行榜”归位到 `TowerFloorListScreen` 顶栏，点击复用既有 `LeaderboardScreen`。

## 非目标

- 不把排行榜加入江湖纪事的六类档案，不恢复主菜单平铺入口。
- 不改 `TowerProgress`、最高层、耗时、挑战次数、胜率或 `LeaderboardSyncService` Noop 语义。
- 不引入云排行榜、Supabase、网络调用、账号、购买或发布配置。
- 不改 schema/saveVersion、YAML、数值、奖励、经济、解锁或 narrative。
- 不宣告 U05、U06、M6 或二阶段完成。

## 精确白名单

- `lib/features/tower/presentation/tower_floor_list_screen.dart`
- `test/features/tower/presentation/tower_leaderboard_relocation_test.dart`
- `test/features/tower/presentation/tower_floor_list_screen_test.dart`
- `test/features/tower/presentation/leaderboard_screen_test.dart`
- `test/features/main_menu/presentation/main_menu_jianghu_chronicle_hub_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m6-u05-tower-leaderboard-relocation.md`
- `docs/audit/phase2_m6_u05_tower_leaderboard_relocation_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

## 红绿与门禁

1. 红测证明主菜单/江湖纪事不再平铺排行榜，且九霄塔当前没有排行榜入口。
2. 转绿后九霄塔顶栏提供键盘可达、有 tooltip 的排行榜动作，真实 push `LeaderboardScreen`。
3. 排行榜空态与现有指标继续只读生产塔进度，主菜单与江湖纪事六类 Hub 不回退。
4. 运行排行榜、塔、主菜单/江湖纪事相邻回归、纸面对比审计、两层 analyze 和全量。
5. 独立语义复核通过后才同步审计/真相源并生成 clean READY。

## 停止条件

若排行榜落点必须改变江湖纪事六类设计、塔进度存储、同步合同或需要 schema/网络/发布决策，立即记录精确 `BLOCKED`；不在本切片设计新榜单。
