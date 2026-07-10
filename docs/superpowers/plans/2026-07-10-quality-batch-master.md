# Quality Batch Master Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成存档恢复、测试基础设施迁移、通用 UI 可靠性和 GDD 数据口径四批任务，不包含发布准备。

**Architecture:** 以 `codex/save-restore-design` 为主执行分支，先完成高风险存档恢复，再处理互不依赖的测试与 UI 清理。每个批次单独计划、定向验证和提交，批末统一全量回归、PR CI 与 macOS 视觉验收。

**Tech Stack:** Flutter Desktop、Dart、Riverpod、Isar Community、flutter_test、GitHub Actions。

---

## 批次与验收

- [x] **批次 A：存档恢复闭环**
  - 计划：`docs/superpowers/plans/2026-07-10-save-restore.md`
  - 验收：成功恢复、自动安全备份、故障回滚、启动中断恢复、设置页完整流程。
- [x] **批次 B：测试基础设施迁移**
  - 计划：`docs/superpowers/plans/2026-07-10-test-infrastructure-migrations.md`
  - 验收：剩余直接 Isar 初始化收口；只迁移等价的 production GameRepository loader，保留故障注入 loader。
- [x] **批次 C：通用 UI 可靠性**
  - 计划：`docs/superpowers/plans/2026-07-10-ui-reliability.md`
  - 验收：标题栏返回/主页动作统一语义与热区；关键图片缺失时有稳定且可诊断的业务 fallback。
- [x] **批次 D：GDD 数据口径销账**
  - 计划：`docs/superpowers/plans/2026-07-10-skill-count-drift.md`
  - 验收：机器实数与 GDD 口径一致，过期 PROGRESS 债务删除。
- [ ] **批末门禁**
  - [x] 本批新增与手工修改文件已按范围执行 `dart format`
  - [x] `flutter analyze lib/ test/`
  - [x] `flutter test --no-pub`（3790/3790）
  - [x] `flutter build macos --debug`
  - [x] macOS 1280x720、1440x900 视觉验收（main_menu、chapter_list、equipment_detail_screen）
  - [x] `git diff --check`
  - PR CI pass 且 annotations 为 0

> 格式化说明：对 `main...HEAD` 全部分支 Dart 文件执行只读 formatter 审计时，235 个文件中有 162 个会被当前 SDK 重排；这些主要是仅迁移初始化/helper 调用的既有测试。为避免把大规模无关格式噪声混入迁移，本批不做机械全仓重排，静态分析与全量测试作为代码门禁。

## 当前恢复点

- 状态：批次 A-D 功能、文档销账、本地门禁与 macOS 双尺寸视觉验收均完成。
- 最后完成：全量 3790 项测试、静态分析、macOS 构建、六张视觉截图和日志异常扫描。
- 下一步：提交最终恢复点，推送分支，创建 PR，等待 CI 后合并。
- 已跑验证：`flutter analyze lib/ test/` 0 问题；`flutter test --no-pub` 3790/3790；macOS Debug 构建成功；main_menu/chapter_list/equipment_detail_screen @ 1280x720、1440x900 均 READY 且 window-id 截图无异常；`git diff --check` 通过。
- 阻塞项：无。
