# Phase 2 U01 主线五模式一致性收口审计

## 结论

`P2-M2-M6-U01-ALL-MODE-CONSISTENCY` 固定验收门已由 `2/5` 提升为 `5/5`，状态为 `ready_reviewed`。本结论只关闭 U01 主线五模式一致性生产子门；顶层 M0–M9 仍 `1/10`，M2、M6 与 Phase 2 均仍 WIP。

- branch: `codex/phase2-u01-all-mode-consistency-20260825`
- base: `403e4f01c97a15e84e6026ea625debb9ccf8da04`
- code candidate: `43ef5b9ce99eec368b902874ac74c2d24b8928e2`
- 成本约束：90 分钟无验收门变化即停线；当时将 reporter `5:00` 误读为约 5 小时而未重复执行整仓全量。实际基线约 4–7 分钟，最终统一候选须补一次完整套件。

## 五模式生产路径

| 模式 | 参与者政策 | controller / runner | 结算与报告 | 结果 |
| --- | --- | --- | --- | --- |
| 首推手动 | 经核实的当前掌门，强制 human/realtime | `Phase0aMainlineBattleHost` → 既有 controller/reducer | 既有首通结算，exact participant | PASS |
| 可见真人重打 | 逐次选 eligible 空闲角色，human/realtime | 同一 Host/controller/reducer | 既有重打结算，实际参与者 | PASS |
| 可见前台 bot 重打 | 逐次选 eligible 空闲角色，playerBot/realtime | 既有 `Phase0aPlayerBotAdapter` 在固定 tick 生成 command，进入同一 controller/reducer | 既有重打结算，实际参与者 | PASS |
| 快速 headless 重打 | 经核实的当前掌门，playerBot/headless | `MainlineHeadlessReplayUnit` → 既有 `Phase0aSweepHeadlessRunner` | 共用重打 settlement，不消耗 sweep readiness，回顾显示实际参与者 | PASS |
| 即时扫荡 | 经核实的当前掌门，playerBot/headless | 同一 `Phase0aSweepHeadlessRunner` | 共享 settlement，错人时在 readiness 写入前 fail closed | PASS |

## 生产 owner 复核

- 参与请求：既有 `ActivityParticipationRequest`。
- participant snapshot：`MainlineParticipantSnapshotService` 复用 `MainlineParticipationPolicy`、`CurrentLeaderResolver`、`CharacterOccupancyService` 与 `PlayerCombatantSnapshotAssembler`，不新增身份真相源。
- controller / runner：可见路径为 `Phase0aMainlineBattleHost` + `Phase0aBattleScreen`；无人值守路径复用 `Phase0aSweepHeadlessRunner`。
- reducer / event：仍为既有 Phase 0A controller/reducer/event，没有新 reducer、session 或 headless 内核。
- settlement：仍经既有 victory resolution / `CombatResolutionService` 共享真相源。
- 报告：可见胜利报告与 headless recap 都消费 exact participant，不回退其他角色。

## Fail-closed 证据

下列状态均在进入战斗或写结算/readiness 之前拒绝：无效/悬空掌门，历史或跨代角色，死亡，疗养，无主修，重复占用，provider 异常，悬空或错主装备/心法，stale participant/snapshot，模式字段组合不合法，未通关 replay/sweep，以及错人 settlement。错人 sweep 路径不写 readiness。

## 验证记录

- RED 契约：5 项初始失败（缺中央 snapshot service、canonical loadout identity 与模式连线）。
- 定向模式/bot 验证：`23/23 PASS`。
- 主线+扫荡全域：`470/470 PASS`。
- 相邻活动/设置/bot/headless/结算域：`146/146 PASS`。
- 真实 Ch1 `stage_01_01` headless replay 生产 smoke：1 项 PASS，终态和当前掌门姓名/ID 一致。
- `test/data/truth_source_guard_test.dart`：`9/9 PASS`。
- `flutter analyze --no-pub lib test`：0 issue。
- `git diff --check`：0 issue。
- P0/P1/P2 语义复核：0 项未解决。
- 证据边界：未执行第二次整仓全量，不冒称全量全绿。

## 非变更边界

本门没有修改 schema/saveVersion、YAML、TUNING/candidate、奖励数量/概率、经济、解锁阈值、叙事或战斗规则；没有新增 reducer、session、headless 内核、provider 或 settlement 真相源；没有修改、合并或 push main。
