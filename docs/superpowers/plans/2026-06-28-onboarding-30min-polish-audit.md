# 新手前 30 分钟体验打磨审计计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to execute this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 审计当前 production 新档前 30 分钟路径，列出解锁顺序、默认目标、初期掉落、首个失败点、首个成长反馈的摩擦与可执行修复切片。

**Architecture:** 本批默认不改玩法逻辑，以文档审计为主。证据来自 AGENTS/CLAUDE/GDD/backlog 指定章节、当前 Dart/YAML 实现、现有测试与 seed 约束，结论只写可交叉证明的事实。

**Tech Stack:** Flutter Desktop、Isar、Riverpod、YAML data、现有 `flutter test` 定向测试。

---

## 目标

- 产出 `docs/audit/onboarding_30min_review_2026-06-28.md`。
- 覆盖前 30 分钟路径、当前摩擦、推荐修复切片。
- 不新增教程弹窗；修复建议仅围绕解锁顺序、默认目标、初期掉落、首个失败点、首个成长反馈。
- 若没有极低风险的纯文案/显示层小修，不改 `lib/` / `data/`。

## 分支

- `codex/onboarding-30min-polish-audit`
- 起点：`b2bc6066`
- 不 merge，不 push，不改 main。

## 验收标准

- 审计报告必须列出 0-30 分钟路径，并标注证据来源。
- 每个问题必须绑定至少一种证据：文档、YAML、Dart 实现、现有测试或 seed 说明。
- 推荐修复按小切片拆分，包含建议改动文件、验证方式与风险。
- 报告明确区分“已改善现状”和“仍需修复”。
- 定向验证至少覆盖：onboarding seed、tutorial step、stage/loot 数据或菜单/装备入口中的关键路径。

## 任务切片

### Task 1: 读取约束与建立计划

**Files:**
- Read: `AGENTS.md`
- Read: `CLAUDE.md` §8.0
- Read: `GDD.md` §10 / §5.7
- Read: `docs/spec/playability_phase2_backlog.md` §十二
- Create: `docs/superpowers/plans/2026-06-28-onboarding-30min-polish-audit.md`

- [x] **Step 1:** 读取指定文档章节并确认红线。
- [x] **Step 2:** 创建分支 `codex/onboarding-30min-polish-audit`。
- [x] **Step 3:** 写入本计划文件。
- [ ] **Step 4:** 提交计划切片。

### Task 2: 取证当前新手路径

**Files:**
- Read: `lib/features/save_slot/presentation/save_select_screen.dart`
- Read: `lib/features/onboarding/application/onboarding_service.dart`
- Read: `lib/features/onboarding/application/master_builder.dart`
- Read: `data/masters.yaml`
- Read: `data/stages.yaml`
- Read: `lib/features/mainline/presentation/stage_list_screen.dart`
- Read: `lib/features/tutorial/application/tutorial_service.dart`
- Read: `lib/features/tutorial/domain/tutorial_hint_def.dart`
- Read: `lib/features/equipment/application/equipment_service.dart`
- Read: `lib/features/character_panel/presentation/equip_slot_dialog.dart`
- Read: existing tests under `test/features/onboarding/`, `test/features/tutorial/`, `test/features/mainline/`, `test/features/loot_preview/`, `test/features/equipment/`

- [x] **Step 1:** 确认新档 seed：单人学徒、空手、50 磨剑石、0 心血结晶。
- [x] **Step 2:** 确认 Ch1 关卡链、首关掉落、章末 Boss 和失败处理。
- [x] **Step 3:** 确认菜单门控、关卡整备条、掉落预览、装备穿戴/强化入口。
- [ ] **Step 4:** 整理证据到审计报告。

### Task 3: 写审计报告

**Files:**
- Create: `docs/audit/onboarding_30min_review_2026-06-28.md`

- [ ] **Step 1:** 写“0-30 分钟路径”。
- [ ] **Step 2:** 写“当前摩擦”并绑定证据。
- [ ] **Step 3:** 写“推荐修复切片”。
- [ ] **Step 4:** 写“验证与局限”。
- [ ] **Step 5:** 更新本计划恢复点。
- [ ] **Step 6:** 提交审计报告切片。

### Task 4: 定向验证

**Commands:**
- `flutter test test/features/onboarding/application/onboarding_service_test.dart`
- `flutter test test/features/tutorial/application/tutorial_service_test.dart test/features/tutorial/domain/tutorial_hint_def_test.dart`
- `flutter test test/data/game_repository_test.dart test/data/drop_table_reference_redline_test.dart`
- `flutter test test/features/mainline/presentation/stage_list_screen_test.dart test/features/loot_preview/stage_row_loot_wiring_test.dart`
- `flutter test test/features/equipment/application/equipment_service_test.dart test/features/character_panel/presentation/equip_slot_dialog_test.dart`

- [ ] **Step 1:** 运行定向测试。
- [ ] **Step 2:** 若测试失败，判断是否与本审计改动相关。
- [ ] **Step 3:** 更新审计报告和恢复点中的验证记录。

## 当前恢复点

- **状态:** Task 1 进行中。
- **最后完成:** 已读 AGENTS.md、CLAUDE.md §8.0、GDD.md §10 / §5.7、`playability_phase2_backlog.md` §十二；已创建分支。
- **下一步:** 提交计划文件，然后写审计报告。
- **已跑验证:** `git status --short --branch` 确认当前分支为 `codex/onboarding-30min-polish-audit`。
- **阻塞项:** CodeGraph 未初始化，结构查询改用 `rg`/定向读取；本任务不运行 `codegraph init -i`。
