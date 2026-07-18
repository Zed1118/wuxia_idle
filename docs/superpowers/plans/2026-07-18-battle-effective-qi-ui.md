# 战斗有效耗气 UI 一致性计划

> 上游稳定点：`codex/battle-intervention-ap-gate@6e3595b6`
> 分支：`codex/battle-effective-qi-ui`

## 1. 目标

让交互指令台、自动轮转谱与玩家命令门控统一读取角色心法减耗后的有效真气消耗，消除“引擎与 AI 可以施放，但 UI 显示原价并误判真气不足”的规则漂移。

## 2. 方案

- 在 `QiCycle` 提供读取已封顶角色快照的有效耗气纯函数，现有结算公式继续委托同一实现，避免复制 round/clamp 公式。
- `isSkillReady`、`canInterveneWithSkill`、自动轮转排序/状态、指令台状态/耗气标签统一消费有效耗气。
- 技能秘籍详情仍展示招式基础耗气；角色战斗案台展示本角色实付耗气，两者语义区分明确。
- 不改 `numbers.yaml`、心法减耗值、真气增减、AI 优先级或伤害公式。

## 3. 验收

- [x] 有减耗角色在 `currentQi < baseCost && currentQi >= effectiveCost` 时，指令台可下发且显示有效耗气。
- [x] 无减耗角色显示与行为零回归。
- [x] 自动轮转谱按有效耗气判断 ready/聚气并排序。
- [x] 实际 `interveneNow` 扣气与 UI 显示值一致。
- [x] targeted、完整战斗模块、诊断探针与 analyze 通过。
- [x] 1280×720 / 1440×900 真实 macOS 视觉 smoke 通过。
- [ ] 工作树清洁，冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：实现与验收完成，待冻结提交。
- **最后完成**：统一 `QiCycle`、交互指令台与自动轮转谱的有效耗气口径；真实双视口确认 7 技能位与状态标签无溢出。
- **下一步**：检查 diff，提交 `[READY]` 稳定点。
- **已跑验证**：新增测试先红后绿；targeted 65/65；战斗模块 + 诊断串行 672/672；`flutter analyze` 0 问题；1280×720 / 1440×900 真实 macOS smoke 通过。
- **阻塞项**：无。
