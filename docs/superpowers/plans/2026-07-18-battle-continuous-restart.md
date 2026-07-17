# 连续战斗拍钟重启计划

> 上游稳定点：`codex/battle-pending-request-guard@2e2afcad`
> 分支：`codex/battle-continuous-restart`

## 1. 目标

同一个 `BattleScreen` 承接下一场战斗时，状态从已结束切回进行中必须自动重启拍钟；不能只重置结算弹窗标志却让新战斗永久停在初始画面。

## 2. 根因与方案

- 现有监听只在队伍“空 → 非空”时启动 timer。
- 连续战斗通常保留非空队伍，边沿是 `result != null → null`，所以 timer 已在上一场停止却不会重启。
- 将“结束 → 进行中”纳入 `autoStart` 起拍条件，并继续尊重 `startPaused`。
- `hasTimer` 改为反映 `Timer.isActive`，避免已 cancel 的引用被误判为仍在播放。

## 3. 验收

- [x] 连续战斗第二场进入 running 后，在一个动作间隔内调用 `advanceOneAction`。
- [x] 第一场结束后 `hasTimer == false`，第二场起拍后恢复 true。
- [x] `autoStart=false` 的验收/调试路由不被自动启动。
- [x] 结算弹窗防重入与连续第二场弹窗不回归。
- [x] 完整战斗模块、analyze 与双视口 UI 通过，冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：实现与验证完成，待冻结稳定点。
- **最后完成**：拍钟启动条件已覆盖 `result != null → null`；`hasTimer` 改读 `Timer.isActive`，暂停/结束不再误报。
- **下一步**：提交 `[READY]` 后继续审计剩余 UI/特效/节奏边界。
- **已跑验证**：先见取消 timer 状态红测；播放+连续战斗 20/20；完整 `test/features/battle` 718/718；`flutter analyze --no-pub` 无问题（双视口 UI 包含在完整回归）。
- **阻塞项**：无。
