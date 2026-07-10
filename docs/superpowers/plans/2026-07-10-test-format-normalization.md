# Test Format Normalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用当前 Dart SDK 统一 `test/` 下的历史排版，并证明提交不包含业务语义修改。

**Architecture:** 本批只运行官方 `dart format`，不手工修改测试逻辑。格式化前后分别记录文件数；完成后通过 diff 审计、静态分析、全量测试和 PR CI 证明机械变更安全。

**Tech Stack:** Dart formatter、Flutter analyzer、flutter_test、GitHub Actions。

---

### Task 1: 建立格式基线

**Files:**
- Audit: `test/**/*.dart`

- [x] **Step 1:** 运行 `dart format --output=none --set-exit-if-changed test`，记录扫描文件数和待变更文件数。
- [x] **Step 2:** 记录格式化前 `git status --short`，确认除本计划外没有工作树改动。

### Task 2: 执行机械格式化

**Files:**
- Modify: `test/**/*.dart`（仅 formatter 命中的文件）

- [x] **Step 1:** 运行 `dart format test`。
- [x] **Step 2:** 再运行 `dart format --output=none --set-exit-if-changed test`，预期退出码 0、changed 0。
- [x] **Step 3:** 用 `git diff --check`、文件类型和 diff 内容抽样确认没有生产代码、数据或测试断言语义改动。

### Task 3: 本地回归

- [x] **Step 1:** 按 CI 顺序先运行 `dart run build_runner build`，再运行 `flutter analyze lib/ test/`，结果 0 问题。
- [x] **Step 2:** 运行 `flutter test --no-pub`；首轮出现 1 次瞬时失败，`--fail-fast --reporter expanded` 完整复跑 3790/3790 通过。
- [x] **Step 3:** 更新本计划恢复点与 `PROGRESS.md`，记录实际文件数和验证结果。

### Task 4: 集成

- [x] **Step 1:** 提交纯格式化批次。
- [x] **Step 2:** 推送并创建 PR #34。
- [x] **Step 3:** CI 通过且 annotations 为 0 后 squash 合并。
- [x] **Step 4:** `main` 已同步到合并提交 `1be0388b`，临时执行分支已收口。

## 当前恢复点

- 状态：Task 1-4 全部完成；PR #34 已合并，`main` 已同步。
- 格式结果：扫描 572 个测试 Dart 文件，349 个由官方 formatter 重排；二次审计 0 changed；变更边界只含 `test/` 和本计划/PROGRESS 记录。
- 验证结果：build_runner 生成 114 outputs；`flutter analyze lib/ test/` 0 问题；全量复跑 3790/3790；`git diff --check` 通过。
- 下一步：无；本计划作为已完成历史记录保留。
- 阻塞项：无。
