# P2-GOVERNANCE-INTEGRATION

## 目标

将 2026-08-25 原整改报告、两份外部审查和 Codex 最终复核结论收敛到现有规则层，不新建第二套真相源。

## 分支与基线

- branch: `codex/phase2-governance-integration-20260825`
- base: `8671f8920a9e2ef3cd7bf869a047808d0fd742b1`
- primary `main`: 不修改、不合并、不推送

## 验收标准

- `CLAUDE.md` 承载 Gate 层级、两类债务、合并授权、四项测量与无人值守口径。
- `PROGRESS.md` 首屏显示分母/当前 Gate、债务、Top-3 blocker 和待批决策。
- Gate 权重保持待用户批准；不修改 GDD、业务代码、schema、saveVersion、YAML、数值或 `main`。
- Markdown 和 YAML 结构检查通过，`git diff --check` 通过，worktree clean，以 `[READY]` tip 交付。

## 恢复点

- 状态：`ready_reviewed`
- 最后完成：全局规则、Skill、项目规则、仪表盘与桌面整合执行版已落地
- 已跑验证：Skill `quick_validate` PASS；项目 `git diff --check` PASS；YAML 可解析；路径/链接存在性检查 PASS
- 下一步：等待用户批准 Gate 分母/权重与塔个人成绩迁移决策
- 阻塞：Gate 权重与塔个人成绩迁移仍待用户决策，不阻塞本治理补丁
