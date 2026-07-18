# 败北最后一击交接节奏计划

> 上游稳定点：`codex/battle-effect-coalescing@b1974a15`
> 分支：`codex/battle-defeat-handoff-pacing`

## 1. 目标

败北或平局发生时先保留一个关键帧反应窗口，让致败一击、死亡飘字和命中特写可见，再进入结算 overlay；胜利继续使用既有 500ms 交接，不改变任何胜负或奖励逻辑。

## 2. 方案

- 胜利沿用 `victoryHandoffDelayMs`。
- 败北/平局复用既有 `keyMomentHoldMs`，不新增数值常量或配置支线。
- 延迟后继续用 result epoch 与当前 provider result 双重校验，连续重开时废弃过期交接。

## 3. 验收

- [x] rightWin 后关键帧窗口内不出现结算 overlay，到期后正常出现。
- [x] leftWin 仍按 500ms 交接，deferVictoryToCaller 契约不回归。
- [x] 连续战斗重开仍不会弹出上一场过期结算。
- [x] 完整战斗模块、analyze 与双视口 UI 通过，冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：已完成，待冻结稳定点。
- **最后完成**：胜利用既有 victory handoff，败北/平局复用 keyMomentHold；两类异步交接继续受 epoch 与当前 result 双门控。
- **下一步**：提交 `[READY]`，继续审计结算前后的输入与播放状态。
- **已跑验证**：结果时序 9/9；完整 `test/features/battle` 730/730；`flutter analyze --no-pub` 通过。此前同链双视口真实窗口验收通过。
- **阻塞项**：无。
