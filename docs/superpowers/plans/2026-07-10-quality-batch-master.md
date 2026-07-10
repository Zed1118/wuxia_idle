# Quality Batch Master Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成存档恢复、测试基础设施迁移、通用 UI 可靠性和 GDD 数据口径四批任务，不包含发布准备。

**Architecture:** 以 `codex/save-restore-design` 为主执行分支，先完成高风险存档恢复，再处理互不依赖的测试与 UI 清理。每个批次单独计划、定向验证和提交，批末统一全量回归、PR CI 与 macOS 视觉验收。

**Tech Stack:** Flutter Desktop、Dart、Riverpod、Isar Community、flutter_test、GitHub Actions。

---

## 批次与验收

- [ ] **批次 A：存档恢复闭环**
  - 计划：`docs/superpowers/plans/2026-07-10-save-restore.md`
  - 验收：成功恢复、自动安全备份、故障回滚、启动中断恢复、设置页完整流程。
- [ ] **批次 B：测试基础设施迁移**
  - 计划：`docs/superpowers/plans/2026-07-10-test-infrastructure-migrations.md`
  - 验收：剩余直接 Isar 初始化收口；只迁移等价的 production GameRepository loader，保留故障注入 loader。
- [ ] **批次 C：通用 UI 可靠性**
  - 计划：`docs/superpowers/plans/2026-07-10-ui-reliability.md`
  - 验收：标题栏返回/主页动作统一语义与热区；关键图片缺失时有稳定且可诊断的业务 fallback。
- [ ] **批次 D：GDD 数据口径销账**
  - 计划：`docs/superpowers/plans/2026-07-10-skill-count-drift.md`
  - 验收：机器实数与 GDD 口径一致，过期 PROGRESS 债务删除。
- [ ] **批末门禁**
  - `dart format --output=none --set-exit-if-changed lib test`
  - `flutter analyze lib/ test/`
  - `flutter test --no-pub`
  - macOS 1280x720、1440x900 视觉验收
  - `git diff --check`
  - PR CI pass 且 annotations 为 0

## 当前恢复点

- 状态：批次 A 功能实现完成，等待批次验证。
- 最后完成：设置页恢复状态机和退出边界按 widget 测试通过。
- 下一步：批次 A Task 6，静态检查、定向回归与 macOS 视觉验收。
- 已跑验证：定向 analyze 0；存档与设置 46/46；file-ops 1/1。
- 阻塞项：无。
