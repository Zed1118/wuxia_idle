# 连续战斗表现状态复位计划

> 上游稳定点：`codex/battle-stale-result-handoff@e09d0744`
> 分支：`codex/battle-restart-vfx-reset`

## 1. 目标

同屏开始下一场战斗时，上一场尚未结束的飘字、弹道、特效贴片、题字、闪白、受击闪、攻击位移、屏震/特写和首通展示帧消费状态必须全部复位。

## 2. 方案

- `BattlePlaybackController.onBattleRestarted` 统一清理瞬时队列并 reset 动画控制器。
- 为大招题字与屏幕闪白补 `clear()`，与已有打击 glyph 清理口径一致。
- 若首通导演已启用，重建导演，使下一场独立计算开局/首技/破招首次事件。
- `BattleScreen` 在 finished→running 边沿先复位表现状态，再启动新拍钟。
- 不清玩家偏好（暂停/快进/可读节奏）与手选焦点基线。

## 3. 验收

- [x] 复位后 popups/trails/effects 为空，动作模板回到 melee。
- [x] attack/hitFlash/shake/closeup 控制器回初态。
- [x] glyph/caption/flash 可命令式立即清除。
- [x] 连续战斗第二场拍钟与结算时序不回归。
- [x] 完整战斗模块、analyze 与双视口 UI 通过，冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：已完成，待冻结稳定点。
- **最后完成**：重启边沿统一清空旧场瞬时演出，停止并安全释放动态控制器；caption/flash 补齐命令式清理，首通导演独立复位。
- **下一步**：提交 `[READY]`，从该稳定点继续审计战斗节奏与手动干预边界。
- **已跑验证**：局部 35/35；完整 `test/features/battle` 722/722；`flutter analyze --no-pub` 通过。双视口战斗 UI widget 验收包含在完整战斗回归中。
- **阻塞项**：无。
