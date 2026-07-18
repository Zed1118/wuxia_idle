# 过期结算交接防线计划

> 上游稳定点：`codex/battle-continuous-restart@8a3867ca`
> 分支：`codex/battle-stale-result-handoff`

## 1. 目标

上一场胜利的延迟交接在等待期间若已启动下一场，旧异步任务必须失效；不能在新战斗中途弹出上一场结算、停止新 BGM 或触发旧胜利回调。

## 2. 根因与方案

- 胜利边沿固定延迟 `victoryHandoffDelayMs` 后只检查 `mounted`。
- 连续战斗会把 `_resultDialogShown` 重置为 false，旧任务随后恰好具备再次显示条件。
- 引入结算呈现 epoch：每次结束与重开都推进版本；异步任务捕获自己的 epoch。
- 延迟结束后仅当 epoch 仍匹配、当前 state 仍保持相同完成结果时才呈现。

## 3. 验收

- [x] 胜利延迟未满即启动下一场：旧 overlay/回调不出现，新拍钟继续推进。
- [x] 正常等待完整延迟：当前场结算仍按原时序出现。
- [x] 第二场随后结束：只显示第二场结算一次。
- [x] 败北即时结算与 deferVictoryToCaller 语义不回归。
- [x] 完整战斗模块、analyze 与双视口 UI 通过，冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：实现与验证完成，待冻结稳定点。
- **最后完成**：结算呈现 epoch 已覆盖结束/重开边沿；延迟任务醒来后同时核对 epoch 与当前 provider 结果。
- **下一步**：提交 `[READY]` 后继续审计连续战斗的本地 UI/VFX 状态复位。
- **已跑验证**：先见 500ms 内重开红测；结算时序 8/8；完整 `test/features/battle` 719/719；`flutter analyze --no-pub` 无问题（双视口 UI 包含在完整回归）。
- **阻塞项**：无。
