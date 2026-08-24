# P2-M6-U05 九霄塔排行榜归位审计

- 日期：2026-08-25
- 基线：`79c5e96c6e99bcb519ac17e27ad51afb673b8601`
- 登记：`deff575be68ad51c5b3749170f716164f36efd01`
- 代码候选：`bd1c492397c452adbf616f2504fa8b704b540acd`
- 状态：`ready_reviewed`

## 问题与权威归属

`GDD.md` §8.2 将排行榜位置与九霄塔通关层数绑定，既有 `LeaderboardScreen` 也只读 `towerProgressProvider` 的最高层、最佳耗时、挑战次数与派生胜率。江湖纪事收拢后主菜单不再平铺排行榜，但原屏没有新的生产入口，因此归位到 `TowerFloorListScreen` 标题栏是唯一与已有数据权威一致的落点。

## 实现边界

- 标题栏新增带 tooltip 和 button semantics 的奖杯动作，点击真实 push 既有 `LeaderboardScreen`。
- 主菜单不恢复排行榜平铺入口；江湖纪事仍为六类档案，不新增第七类。
- `LeaderboardSyncService` 仍为 `NoopLeaderboardSync`；没有 cloud/account/network/Supabase 路径。
- 未修改 `TowerProgress`、schema/saveVersion、YAML、调优、数值、奖励、经济或解锁。

## TDD 与验证

- 红测：新增的可访问动作与真导航两项在生产接线前为 `0/2`，均精确失败于缺失 `tower-leaderboard-action`。
- 聚焦排行榜/塔列表/主菜单与江湖纪事/纸面对比：`29/29 PASS`。
- 九霄塔相邻域 + 江湖纪事：`113/113 PASS`。
- scoped analyze 与 root `flutter analyze`：均 `0 issue`。
- 独立复核：`98/98 PASS`，`P0=0 / P1=0 / P2=0`，建议 `READY`。
- 最终 root full suite：`5398/5398 PASS`；`git diff --check` 通过。

## 结论

九霄塔本地排行榜入口纵切达到 `READY`。该结论不代表云排行榜完成，也不晋升 U05、U06、M6 或二阶段整体状态。
