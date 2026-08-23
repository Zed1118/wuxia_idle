# P2 G2 E03：真实 Dynamic Encounter Runtime

## 任务

在保留 `Phase0aEncounterFlow.compatibility` 的同时，新增 `Phase0aEncounterFlow.runtime`，真实消费 `SpawnDirector + Phase0aEncounterRoster + Phase0aCombatSession`。所有战斗结算只调现有 session/reducer。

## 构造期

- runtime 显式接收 session、director、roster，不接受 Random/resolver/tuning/UI/save/reward。
- `roster.playerId == session.state.player.id`。
- `identical(roster.director, director)`，防止 roster 与另一个 director 漂移。
- `director.state.tick == session.state.tick`。
- session 初始 enemies 的 ID 必须精确等于 director 当前 active units；初始全 pending 时必须为空。

## 每拍顺序

1. 终局后立即空返回并清空 last records。
2. 以局部候选变量调 director.advance 一次，断言新 director tick 等于 `session.state.tick + 1`。
3. 用 `Phase0aSpawnEventAdapter` 从旧 `nextSeq` 投影 spawn events；在 reducer 前为其预留连续 seq。
4. 从新 director active units 组装 arena enemies：已在 arena 的保留运行态，新 entered 的取 roster actor；warning/pending/removed 不入 arena。
5. 从 director active snapshots 的 `canAttack` 生成 `Phase0aSpawnGraceIntentGate`；用 `forkWithStateAndEnemyIntentGate` 原子替换预留态和本拍 gate。
6. 调 session.advance 一次。
7. 仅根据本拍 `Phase0aEnemyDefeated.target` 经 roster 反查 entry 后 `markExited`；未知/重复 target fail closed。本拍不再 advance director，因此补兵最早下一拍。
8. 终局优先级：player dead defeat > survive reached victory > pending/warning/active 全空且 arena enemies 空 victory > ongoing。终局事件继续消费 seq 并固化到 session state。
9. 仅整拍成功后替换 flow 持有的 session/director/outcome/records；前置投影、gate 或 session 异常不得半提交 flow 状态。

## 公开诊断

- `SpawnDirectorState get spawnState`，仅 runtime 可读；compatibility 调用时明确抛 `StateError`。

## 文件边界

- `lib/features/battle/application/phase0a/phase0a_encounter_flow.dart`
- `test/features/battle/application/phase0a/phase0a_dynamic_encounter_flow_test.dart`
- `test/features/battle/application/phase0a/phase0a_dynamic_encounter_consumers_test.dart`
- 本计划文件

不改 session/gate/roster/events/reducer/director/assembler/data/UI/save/reward。如发现上游接口阻断，停止并报告，不跨白名单修复。

## 验收

- warning → entered → graceExpired、spawn/combat/terminal seq 严格递增。
- grace 期敌人可移动不可进攻，到期当拍恢复进攻。
- kill → exit → next-tick reinforcement，director 计数守恒，arena 只含 active。
- defeat/survive/defeat-all/同拍双空/终局幂等。
- 异常时 flow session/director/outcome/records 不半提交。
- controller 可消费 runtime；headless sync/async 同 fixture 结果完全一致。
- compatibility 旧 parity 测试继续通过。
- targeted tests、`dart analyze`、`git diff --check` 通过；中文动宾提交后创建 `[READY][CODEX][P2-G2-E03] 完成真实动态 Encounter Runtime`。
