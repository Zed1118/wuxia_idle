# 战场镜头运动作用域计划

> 上游稳定点：`codex/battle-auto-incapacitated-status@835dec97`
> 分支：`codex/battle-field-motion-scope`

## 1. 目标

将命中特写缩放与屏震限定到人物战场，保持顶栏、危险条、战报和底部武学案台稳定，避免峰值一击时整个 HUD 被放大裁边。

## 2. 方案

- `BattlePlaybackMotion` 从 `SafeArea` 外层移到承载 `BattlePlaybackField` 的 `Expanded` 内。
- 战场人物、弹道、流派特效与受击反馈继续作为同一运动层；Header、DangerBar、BattleReportStrip、BottomBar/AutoRotationBar 不参与缩放和屏震。
- 命中特写触发条件、缩放幅度、屏震幅度、hit-stop、overlay 题字与数值均不改。

## 3. 验收

- [x] `BattlePlaybackField` 是 `BattlePlaybackMotion` 后代。
- [x] Header 与两类底栏都不是 `BattlePlaybackMotion` 后代。
- [x] 1280×720 / 1440×900 静态布局无溢出。
- [x] 真实 macOS 峰值命中帧中 HUD 不缩放裁边，战场仍有特写。
- [x] 完整战斗模块与 analyze 通过。
- [ ] 工作树清洁，冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：实现与验收完成，待冻结提交。
- **最后完成**：运动层下沉到战场 `Expanded`；实机裂石指命中保留题字、飘字与人物推近，HUD 固定。
- **下一步**：检查 diff，提交 `[READY]` 稳定点。
- **已跑验证**：结构测试先红后绿；双视口 2/2；真实 macOS 峰值命中 smoke；战斗模块 681/681；`flutter analyze` 0 问题。
- **阻塞项**：无。
