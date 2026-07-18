# 战斗不可行动门控一致性计划

> 上游稳定点：`codex/battle-pending-lifecycle@dfb3932d`
> 分支：`codex/battle-incapacitated-gate`

## 1. 目标

让玩家指令台与 strategy 对“角色正在蓄力 / 处于踉跄”的即时干预门控保持一致，消除按钮看似可用、点击后引擎静默拒绝的反馈断层。

## 2. 方案

- `canInterveneWithSkill` 补齐 strategy 已有的 `chargingSkill == null` 与 `staggerTicksRemaining <= 0` 条件。
- 指令按钮统一消费该门控，并用“蓄力中 / 踉跄中”明确解释不可用原因。
- `isSkillReady` 继续只表达资源/冷却 readiness，自动轮转谱语义不变。
- 不改蓄力、踉跄、AP、真气、冷却和伤害数值。

## 3. 验收

- [x] 蓄力角色技能按钮禁用并显示“蓄力中”。
- [x] 踉跄角色技能按钮禁用并显示“踉跄中”。
- [x] 点击上述按钮不进入待发、不调用即时干预。
- [x] 既有 AP/真气/CD 状态与 strategy no-op 测试不回归。
- [x] targeted、完整战斗模块与 analyze 通过。
- [ ] 工作树清洁，冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：实现与验收完成，待冻结提交。
- **最后完成**：UI 命令门控与 strategy 对齐，蓄力/踉跄角色明确显示原因且不可点。
- **下一步**：检查 diff，提交 `[READY]` 稳定点。
- **已跑验证**：新增 4 项测试先红后绿；指令台+点选 51/51；战斗模块 679/679；`flutter analyze` 0 问题。
- **阻塞项**：无。
