# Phase 0A 根应用生产化第二批协调计划

## 目标

在首批几何规则核与反馈契约之上，交付确定性 reducer、玩家/AI 统一输入适配和最小语义事件闭环，并完成独立复核与可恢复冻结。

## 分支

- 协调：`codex/phase0a-production-batch2-dispatch`
- Qoder：`feat/phase0a-qoder-reducer-input-event-loop`，`[READY] 73f562c1`。
- Kimi：`audit/phase0a-kimi-reducer-contract-review`，`[READY] 10046908`。

## 验收标准

- 根 application 会话真实消费纯 Dart reducer；玩家/AI 只差输入适配器。
- 同初态、同输入、同 resolver 得到相等状态与事件。
- hit/Q/R/死亡/技能可用态事件符合冻结契约，表现层无需重算。
- 零旧 3v3、Flutter/Flame/probe、YAML/schema/saveVersion/数值公式改动。
- targeted tests、首片回归、probe 对照、根 analyze 全绿。
- 两执行分支和协调分支均有干净 `[READY]` 恢复点。

## 任务切片

1. 整合首批两分支并恢复 fresh worktree 环境。
2. 冻结 Qoder 实装派单与 Kimi 交叉复核派单。
3. Qoder 实装并冻结。
4. Kimi 交叉复核/最小修复并冻结。
5. 主窗口独立验证和范围审查，冻结协调恢复点。

## 当前恢复点

- 状态：第二批实现、交叉复核与独立验收完成，待冻结协调 `[READY]`。
- 最后完成：合入确定性 reducer、玩家/AI 输入适配器、application 会话和语义事件闭环；Kimi 复核修复敌方技能污染玩家全局态、负值/非有限值静默合法化两类缺陷。
- 下一步：提交本恢复点，复跑协调分支验证并创建 `[READY]` tip。
- 已跑验证（独立于执行代理）：`flutter test --no-pub test/features/battle/domain/phase0a test/features/battle/application/phase0a`（81/81）；nested probe `combat_rules_test.dart`（8/8）；`flutter analyze --no-pub`（0 issue）；禁用依赖检索、`git diff --check`、worktree 洁净均通过。
- 阻塞项：无。
