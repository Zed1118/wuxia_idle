# 命中顿帧读秒环冻结计划

> 上游稳定点：`codex/battle-intervention-queue-guard@673df566`
> 分支：`codex/battle-hitstop-beat-freeze`

## 1. 目标

命中顿帧暂停下一次逻辑出手时，战斗 UI 的拍钟读秒环同步冻结，避免环先扫完、角色却仍停在命中特写中的节奏错觉；顿帧结束后由新一拍从零重启。

## 2. 方案

- `_applyHitStop` 与 pause/finish 共用冻结 beat controller 的节拍语义。
- 不改变 `BattleNotifier` 推进、hit-stop 时长或在线/离线结算结果。
- 用控制器测试锁定：顿帧内 play timer 停止、beat 值不前进；到期后 timer 与 beat 一起恢复。

## 3. 验收

- [x] hit-stop 开始即停止 play timer 与 beat 动画。
- [x] hold 窗口内 beat 值保持不变。
- [x] hold 到期后新一拍从零恢复，暂停/快进既有行为不回归。
- [x] 完整战斗模块、analyze 与双视口 UI 通过，冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：已完成，待冻结稳定点。
- **最后完成**：`_applyHitStop` 同步停止 beat controller；控制器测试锁定 hold 内值不动、到期拍钟与环共同恢复。
- **下一步**：提交 `[READY]`，继续审计暂停/快进与命中特写的交互节奏。
- **已跑验证**：局部 46/46；完整 `test/features/battle` 725/725；`flutter analyze --no-pub` 通过。双视口战斗 UI 验收包含在完整回归中。
- **阻塞项**：无。
