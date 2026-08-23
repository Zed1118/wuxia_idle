# P2-G2-E02：EncounterFlow legacy compatibility

## 目标

建立 `Phase0aEncounterFlow.compatibility` 的最薄兼容接缝：包装既有
`Phase0aWaveBattleFlow`，实现 D03 冻结的 `Phase0aBattleFlow` 四成员，
不改变任何战斗规则或生产消费面。

## 实现边界

- 仅新增 `lib/features/battle/application/phase0a/phase0a_encounter_flow.dart`。
- wrapper 只保存一个 legacy wave flow，并原样委托 `state`、`outcome`、
  `lastOrderedEventRecords` 与 `advance`。
- 不新增 reducer、session、headless 内核，不消费 `SpawnDirector`，不启用
  `AttackTokenDirector` enforce，不改数值、data、UI、奖励、伤势或存档。

## parity 验收

新增 targeted parity 测试，使用同 fixture、同 seed、同 command 序列，逐拍
比较 legacy 与 compatibility 的 `state`、events、eventRecords、outcome；
终局后继续推进并确认幂等。另以 headless runner 覆盖 victory、defeat 与
ongoing（预算耗尽）场景，比较 ticks、finalState、events、eventRecords、
outcome。

## 验证

- targeted compatibility parity test；
- 限定 `dart analyze`；
- `git diff --check`；
- 普通实现提交后追加 `[READY][CODEX][P2-G2-E02]` 空提交，确保工作树干净。
