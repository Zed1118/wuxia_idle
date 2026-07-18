# 终局危险提示清退计划

> 上游稳定点：`codex/battle-defeat-handoff-pacing@27ab99a1`
> 分支：`codex/battle-terminal-danger-clear`

## 1. 目标

战斗进入胜负已定但结算 overlay 尚未交接的最后一击反应窗时，清退“敌人正在蓄力”的危险条，避免已结束状态仍提示玩家准备破招。

## 2. 方案

- `DangerBar` 在 `state.isFinished` 时直接收起。
- 活跃战斗的蓄力筛选、布局与文案完全不变。
- 破绽提示和技能按钮已经由 `canInterveneNow` 在终局门控，无需重复改动。

## 3. 验收

- [x] 活跃态敌方蓄力仍显示危险条。
- [x] 同一快照写入 rightWin 后危险条立即消失。
- [x] 败北交接窗口与结算 overlay 时序不回归。
- [x] 完整战斗模块、analyze 与双视口 UI 通过，冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：可冻结。
- **最后完成**：终局快照立即收起残留蓄力危险条；活跃态逻辑与结果交接节奏保持不变。
- **下一步**：提交 `[READY]` 稳定点，转入特效生命周期审计。
- **已跑验证**：`battle_command_console_test.dart` 39/39；战斗模块 731/731；`flutter analyze --no-pub` 零问题；`battle_tap_preview` 1280×720、1440×900 实机截图无溢出、遮挡或层级回归。
- **阻塞项**：无。
