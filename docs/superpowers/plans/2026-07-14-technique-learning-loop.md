# 心法学习闭环 · 实施计划

- **目标**：接线学新心法闭环（spec `docs/superpowers/specs/2026-07-14-technique-learning-loop-design.md`）
- **分支**：`feat/technique-learning-loop`（基 `fix/audit-batch-20260714` tip，PR #35 以 merge commit 合入后血缘干净）
- **验收标准**：analyze 0；format 0 changed；服务测+widget 测全绿；全量无回归；§8.2 四证据齐

## 任务切片

- [x] T1 编排服务 `TechniqueLearnFlowService` + provider + `recordTechniqueLearned` 事件（TDD：服务测先红后绿）
- [x] T2 UiStrings + 面板入口行 + 可学列表 dialog + 二确流（生产接线）
- [x] T3 widget 测（入口两态/列表过滤/超阶灰显/二确流）
- [x] T4 文档订正（insight_exchange 注释 / game_event #4 注释 / numbers learning_cost 注释 / CLAUDE §5.3 v1.38 / backlog §十三 #1 勾账 / PROGRESS 条目）
- [x] T5 门禁（build_runner / analyze / format / targeted / 全量）+ commit + push + PR

## 当前恢复点

- **状态**：完成，待 commit/push/PR
- **最后完成**：服务层 + provider + 事件 + UI 入口/dialog/二确 + 文档订正全部落地
- **已跑验证**：analyze 0；format 0 changed；targeted 30/30（服务 8 + domain 4 + panel widget 14 含 3 新）；全量 **3949 pass / 0 fail**（EXIT=0）
- **阻塞项**：无
