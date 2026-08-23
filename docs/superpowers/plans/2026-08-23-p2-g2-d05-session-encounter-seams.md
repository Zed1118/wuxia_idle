# P2 G2 D05：Session Encounter 安全接缝

## 任务

为真实 Encounter Flow 建立两个最小接缝：

1. `Phase0aCombatSession.forkWithState(nextState)`：返回仅替换 state 的候选 session，必须保留同一 player adapter、enemy AI adapter、damage resolver、enemy-skill resolver 和 enemy-intent observer。不创建 RNG，不推进 tick/seq，不产生事件。
2. 可选的逐拍 `Phase0aEnemyIntentGate`：默认 null 路径必须与现有完全一致；显式 gate 先筛选 enemy intents，observer 只观察最终要交给 reducer 的不可修改列表。

## 宽限 gate 冻结语义

- `Phase0aSpawnGraceIntentGate` 由调用方显式传入 `canAttackActorIds`，输入集合防御性复制。
- actor 在集合内：允许其原始 intent。
- actor 不在集合内：仅允许 `Phase0aMoveIntent`，普攻、enemy skill 与未来未显式分类的 enemy intent 均 fail closed。
- gate 不得修改 adapter 返回的原列表，输出交给 observer 时必须不可修改。

## 兼容修正

`Phase0aWaveBattleFlow._rebuildSession` 改用 `forkWithState`，锁定换波后 D04 observer 仍持续观察。

## 文件边界

- `lib/features/battle/application/phase0a/phase0a_combat_session.dart`
- `lib/features/battle/application/phase0a/phase0a_enemy_intent_gate.dart`
- `lib/features/battle/application/phase0a/phase0a_wave_battle_flow.dart`
- `test/features/battle/application/phase0a/phase0a_session_encounter_seams_test.dart`
- 本计划文件

不改 reducer、SpawnDirector、AttackTokenDirector、EncounterFlow、生产 assembler、data/UI/save/reward。

## 验收

- fork 的依赖 identity 逐项相同，state 精确等于 nextState。
- 无 gate 的 state/events/resolver transcript/observer 行为与基线一致。
- grace actor 可移动、不可普攻/放 enemy skill，到期 actor 恢复全部原 intent。
- observer 观察 gated intents，不能回写或修改列表。
- wave 换波前后 observer 都收到调用。
- targeted tests、`dart analyze` 和 `git diff --check` 通过。
## 当前恢复点

- 状态：D05 已实现并本地验证完毕，等待主控复审。
- 最后完成：`Phase0aCombatSession.forkWithState` + `Phase0aEnemyIntentGate`/`Phase0aSpawnGraceIntentGate` + wave flow 换波改用 fork（observer/gate 全程保留）；新增 `test/features/battle/application/phase0a/phase0a_session_encounter_seams_test.dart` 13 测全绿；周边 6 文件 72 测全绿；analyze 零新 issue（全仓 1943 条均为 tools/phase0minus_probe/ 历史遗留，改动文件 0 issue）；`git diff --check` 干净。
- 下一步：主控逐 diff 复审，批末集成后由 E03 消费 fork/gate 接缝实现真实 runtime。
- 阻塞项：无；token enforce 与关卡 tuning 仍不在本批范围。

- 普通中文动宾提交，再创建空 READY commit：`[READY][PI][P2-G2-D05] 完成 Session Encounter 安全接缝`。
