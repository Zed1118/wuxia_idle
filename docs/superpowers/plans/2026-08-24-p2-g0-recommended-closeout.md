# P2 G0 推荐方案关闭计划

## 目标

依据用户 2026-08-24 的明确授权“按推荐方案执行 G0”，把 Batch8 的只读证据包转化为可追溯的设计决议；本批只关闭决策和长期文档，不实现 M2/M5/M6 生产代码或数值。

## 工作范围

1. 将 11 项产品语义写入 decision registry：可直接冻结的项标为 frozen；AI、解锁和生态剩余范围用明确流程与安全默认收口。
2. 将 6 项 `proposed_reopen` 写成 5 项不重开、1 项部分重开，并在 rejected registry 保留历史。
3. 为 20 个顶层 `TUNE-*` 建立登记，只授权 YAML/红线/模拟/Profile/试玩候选流程，不授权生产值。
4. 同步 GDD、CLAUDE、PROGRESS 和 G0 packet 的当前/历史口径；明确 G0 决议不等于代码已上线。
5. 校验 YAML、ID 数量、历史留痕与 Markdown/diff，主控复审后交独立 agent 审查。

## 不做

- 不修改 `lib/`、`data/`、`test/` 或 UI。
- 不删除心魔旧 10% 扣减；该实现迁移归 M5 独立批次。
- 不把七心魔矩阵、逐模式解锁表或剩余逐关生态描述成已冻结实现。
- 不修改 `main` / `origin/main`，不发布、不部署。

## 恢复点

- 基线：Batch8 READY `9ea75869312d69ebe56cc1eb8af28945e95a4854`。
- 工作分支：`codex/phase2-g0-recommended-closeout-20260824`。
- READY 条件：登记/文档一致性检查通过，独立审查 P0/P1/P2 为 0，task registry 写入验证证据并生成 `[READY]` tip。
