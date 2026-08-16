# Phase 0A 根应用生产化第二批协调计划

## 目标

在首批几何规则核与反馈契约之上，交付确定性 reducer、玩家/AI 统一输入适配和最小语义事件闭环，并完成独立复核与可恢复冻结。

## 分支

- 协调：`codex/phase0a-production-batch2-dispatch`
- Qoder：待由本计划派生独立 worktree。
- Kimi：待 Qoder `[READY]` 后从其 tip 派生独立 worktree。

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

- 状态：派单冻结中。
- 最后完成：首批 Qoder/Kimi `[READY]` 分支无冲突整合；根 Phase 0A 24 项通过；fresh worktree 补齐 nested probe package config 后 `flutter analyze --no-pub` 0 issue。
- 下一步：提交派单文件，创建 Qoder 执行 worktree 并启动实现。
- 已跑验证：`flutter test --no-pub test/features/battle/domain/phase0a/`（24）；`flutter analyze --no-pub`（0 issue）。
- 阻塞项：无。
