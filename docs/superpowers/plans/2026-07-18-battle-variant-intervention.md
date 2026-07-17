# 特殊战斗形态即时干预计划

> 上游稳定点：`codex/battle-kill-climax-snapshot@9632487c`
> 分支：`codex/battle-variant-intervention`

## 1. 目标

轻功对决与群战守城的点选技能必须与地面战一致：合法输入立即插队结算并将 AP 归零，而不是退化为“排队等待下一自然行动”。

## 2. 根因与方案

- 两种组合策略只委派了 `tick/runToEnd/requestUltimate`，未覆写后来新增的 `interveneNow`。
- 因而落入 `BattleStrategy` 默认降级实现，只写 pending；同一个战斗 UI 在不同关卡产生不同操作语义。
- `LightFootStrategy.interveneNow` 先幂等烘焙地形，再委派地面策略即时结算。
- `MassBattleStrategy.interveneNow` 先确保当前 wave/阵型已建立，再委派即时结算。
- 保留非法技能、AP、控制态、目标合法性等地面策略单一防线。

## 3. 验收

- [x] 轻功战点选技能立即产生动作、命中指定目标、AP 归零并保留地形烘焙。
- [x] 群战点选技能立即产生动作、命中当前 wave 指定目标、AP 归零并保留阵型烘焙。
- [x] 非法输入仍 noop，不产生 pending 漂移。
- [x] 完整战斗模块、analyze 与双视口 UI 回归通过。
- [x] 冻结 `[READY]` 稳定点。

## 4. 当前恢复点

- **状态**：实现与验证完成，待冻结稳定点。
- **最后完成**：轻功/群战均覆写 `interveneNow`，在各自入口准备地形或阵型/wave 后委派地面战即时结算；群战致胜后同步沿既有规则切波。
- **下一步**：提交 `[READY]` 后继续审计战斗反馈或手动目标边界。
- **已跑验证**：两条旧实现红测；策略定向 32/32；非法输入 2/2；完整 `test/features/battle` 707/707；`flutter analyze --no-pub` 无问题（双视口 UI 包含在完整回归）。
- **阻塞项**：无。
