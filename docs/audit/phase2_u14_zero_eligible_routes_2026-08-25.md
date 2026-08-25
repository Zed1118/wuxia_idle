# Phase 2 U14 五地点零 eligible 路由收口审计

## 结论

`P2-M6-U14-ZERO-ELIGIBLE-ROUTES` 固定验收门由 `0/1` 关闭为 `1/1`，状态 `READY`。江湖地图五个活动地点在 idle 且没有 eligible 参与者时均 fail closed，不再提供虚假进入 CTA；断魂庄与百草岭已有 active 会话时，即使当前候选数为零也仍可恢复原会话。

- branch: `codex/phase2-u14-zero-eligible-routes-20260825`
- base: `948def3598e742483484fdeb7f4ae2d202cdb4ac`
- code candidate: `b4c8dcbe814162cc8be997f056b1b8c99f320227`
- 生产行为覆盖：`3/5 → 5/5`
- 显式 widget 回归：`1/5 → 5/5`
- U14 权威门：仍 `0/1 BLOCKED`
- 顶层 M0–M9：仍 `1/10`

## 五地点生产 owner 与路由结果

| 地点 | eligibility / active owner | 零 eligible 结果 | active 恢复 |
| --- | --- | --- | --- |
| 九霄塔 | `eligibleParticipantCount` | CTA 禁用 | 不适用 |
| 轻功 | `hasEligibleParticipant` | CTA 禁用 | 不适用 |
| 守城 | `hasEligibleParticipant` | CTA 禁用 | 不适用 |
| 断魂庄 | `availableCandidateCount` / `hasActiveRun` | idle CTA 禁用 | 保留 |
| 百草岭 | `availableCandidateCount` / `hasActiveRun` | idle CTA 禁用 | 保留 |

本门没有新建 eligibility provider、session、runner、admission 或 settlement 真相源。断魂庄和百草岭只在现有地点详情消费既有详情模型；塔、轻功和守城保留已有生产 owner。

## RED 与验证证据

- 首轮五地点相关合同：`28 PASS / 2 FAIL`；失败精确落在断魂庄、百草岭 idle 零候选仍可点击。
- 修复后五地点定向：`38/38 PASS`。
- 江湖地图 + 断魂庄 + 百草岭相邻域：`419/419 PASS`。
- `flutter analyze --no-pub lib test`：`0 issue`。
- `git diff --check`：通过。

遵守 90 分钟成本停止线，本门未重复运行已知多小时整仓全量；风险匹配的活动域回归与全应用静态分析已经覆盖本次生产改动。

## 上级门仍被阻塞

本门只补齐 U14 的 `zero-eligible` 地点路由子门，不能替代真实生产 admission。U14 的前三个阻塞保持不变：

1. 九霄塔缺首通后玩家可达的 automation runner / typed admission。
2. 轻功缺首通后 bot/headless/差遣 runner / typed admission。
3. 守城缺首通后 bot/headless/差遣 runner / typed admission。

## 非变更边界

本门未改 schema/saveVersion、YAML、TUNING/candidate、奖励、经济、解锁、叙事或战斗规则，未新增 reducer、session、headless 内核、provider 或 settlement 真相源，未修改 main。
