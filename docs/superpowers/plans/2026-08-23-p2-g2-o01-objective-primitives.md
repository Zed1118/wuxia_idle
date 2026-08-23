# P2-G2-O01：遭遇目标原语

## 范围

本切片建立八类内容中立的遭遇目标合同：
`DefeatTargetsObjective`、`DestroyAnchorsObjective`、`DefendEntityObjective`、
`SurviveDurationObjective`、`ReachCheckpointObjective`、`TouchMarkersObjective`、
`PursueTargetObjective` 和 `DefeatCommanderObjective`。

目标是不可变、纯领域、确定性推进。目标只接收显式领域事件，不依赖阶段 ID、黑风岭内容、runtime、UI、奖励、存档或 AttackToken。

## 合同约定

- 构造器拒绝空 ID、重复集合 ID 和非正持续时间；`Duration.zero` 事件可安全忽略。
- 目标集合在构造时复制为不可变快照。
- `EncounterObjectiveProgress` 每次推进返回新值；`satisfied` 与 `processedEventIds` 均为不可变集合。
- progress 带有 objective 实例私有 owner token；只有创建它的 objective 能继续推进，跨实例（包括相同参数实例）会 fail-closed。
- 事件带稳定键；相同键重复投递是 no-op。完成后继续投递任何事件也是 no-op。
- 去重键由稳定事件 kind 与 eventId 组成；不同事件类型即使 eventId 相同也不会互吞。
- `EntityDefended` 与 `TimeElapsed` 要求调用方显式提供非空稳定 `eventId`，避免两个合法且连续的相同 tick 被错误合并；相同 duration 但不同键会分别累计。
- zero-duration 时间事件是合法但无进度的 no-op，并消费其事件键；负 duration 仍在构造期拒绝。
- 集合目标只按已满足 ID 集合判定完成，因此输入顺序不影响结果。
- 时间目标按有效的正持续时间累加；调用方可用稳定事件键表达重放/去重。

## 验证

定向测试覆盖八类目标、非法输入、重复与乱序事件、完成幂等和集合不可变性。该合同不选择任何具体生产遭遇目标。
