# P2-M1-C03：动作时间线纯领域候选

## 交付范围

- 新增 fixed-tick `ActionTimeline`，覆盖 idle、windup、active、recovery、completed 及取消/打断/失败终态。
- 所有首效 tick、取消窗口、各类失败 cooldown 由调用方注入；一次动作最多产生一个 `firstEffect` 事件。
- 测试覆盖跨 tick advance 不丢事件、确定性状态推进、非法 tick/窗口拒绝、主动取消、被打断及失败冷却标记。
- 不处理真气、伤害、命中、表现或生产 reducer 接线。

## 恢复点与 G1 风险

1. 当前切片只提供可审查的纯 Dart 候选 API，未接 `phase0a_combat_model.dart`、`phase0a_combat_reducer.dart` 或生产入口。
2. G1 主审需确认事件序列、tick 起点、取消窗口是否按“当前 tick/下一 tick”解释，以及终态事件是否由统一事件流承接。
3. 后续接线前需补动作快照恢复、headless/online 同输入 hash 和与效果执行顺序的合同测试；不得另建第二个 reducer/session。
