# 即时干预技能有效性计划

> 上游稳定点：`codex/battle-pending-target-validity@39e9125b`
> 分支：`codex/battle-intervention-skill-validity`

## 1. 目标

即时干预收到无效技能时必须 noop，不能静默回落为另一招并消耗 AP：技能须为角色已装备招式，且在当前快照真气足、冷却结束。

## 2. 方案

- `interveneNow` 在借 AP / 写 pending 前校验技能属于角色 `availableSkills`。
- 复用 `canInterveneWithSkill` 同时校验存活、AP、蓄力/踉跄、有效耗气与冷却。
- 保留普攻拒绝、目标资格、actorQueue 边界与正常插队语义。
- 不改数值配置、AI 自动选招与 UI 文案。

## 3. 验收

- [x] 真气不足技能：noop，AP / 真气 / 战报不变。
- [x] 冷却中技能：noop，不静默改打普攻或其他技能。
- [x] 未装备技能：noop。
- [x] 合法技能、减耗、破招与多角色插队不回归。
- [x] 完整战斗模块、analyze 与双视口相关 UI 回归通过。
- [x] 工作树清洁，冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：实现与验证完成，准备冻结提交。
- **最后完成**：`interveneNow` 从角色装备表取规范技能定义，并在写 pending / 借 AP 前复用统一干预门控。
- **下一步**：冻结 `[READY]` 稳定点，继续下一项战斗体验审计。
- **已跑验证**：真气不足用例先红（复现静默普攻）后绿；strategy 15/15；干预确定性 + tap + 指令台 61/61；完整战斗模块 696/696；`flutter analyze` 0 问题；指令台既有 1280×720 / 1440×900 禁用态与布局回归通过。
- **阻塞项**：无。
