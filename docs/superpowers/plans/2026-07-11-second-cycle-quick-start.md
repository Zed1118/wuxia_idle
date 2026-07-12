# 二周目快速开局 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为完成过首周目的玩家提供新档快速开局，同时不跳主线、不改奖励、不新增存档 schema。

**Architecture:** 从三个存档的 `MainlineProgress` 派生跨档资格，经 `SlotSummary` 传给存档选择页，再由祖师创建选择传入 `OnboardingService`。复用 `SaveData.isOnboardingCompleted` 与 `tutorialStep` 表达新档引导状态。

**Tech Stack:** Flutter Desktop、Riverpod、Isar Community、flutter_test。

---

### Task 1: 锁定跨档资格契约

**Files:**
- Modify: `test/data/isar_setup_slots_test.dart`
- Modify: `lib/data/slot_summary.dart`
- Modify: `lib/data/isar_setup.dart`

1. 增加失败测试：`stage_06_05#1` 和旧式 `stage_06_05` 都派生 `completedFirstCycle=true`，未通关为 false。
2. 运行 `flutter test test/data/isar_setup_slots_test.dart`，确认新断言先失败。
3. 为 `SlotSummary` 增加默认 false 的只读字段并保留 `copyWith`。
4. 在 `_readSummary` 内实现新旧进度兼容判定。
5. 重跑测试至通过。

### Task 2: 锁定创建模式和值传递

**Files:**
- Modify: `test/features/onboarding/founder_creation_flow_test.dart`
- Modify: `lib/features/onboarding/domain/founder_creation_selection.dart`
- Modify: `lib/features/onboarding/presentation/founder_creation_screen.dart`
- Modify: `lib/shared/strings.dart`

1. 增加失败组件测试：无资格时不显示模式控件；有资格时默认循序模式，可切换并随 selection 提交。
2. 运行定向测试，确认编译或断言失败。
3. 增加 `FounderStartMode` 与 selection 默认值。
4. 创建页增加 `allowQuickStart` 和分段控件，文案集中到 `UiStrings`。
5. 重跑测试至通过。

### Task 3: 接通存档选择页

**Files:**
- Modify: `test/features/save_slot/save_select_screen_test.dart`
- Modify: `lib/features/save_slot/presentation/save_select_screen.dart`
- Modify: `lib/shared/strings.dart`

1. 增加失败测试：有完成槽时空槽显示快速开局提示；无完成槽时不显示。
2. 运行定向测试确认失败。
3. 从 `slots.any` 派生资格，传给空槽卡片与 `FounderCreationScreen`。
4. 重跑测试至通过。

### Task 4: 持久化快速模式

**Files:**
- Modify: `test/features/onboarding/founder_creation_onboarding_test.dart`
- Modify: `lib/features/onboarding/application/onboarding_service.dart`

1. 增加失败测试：快速模式写入完成态、step 5、提示 3/5；循序模式保持默认；资源和主线无额外变化。
2. 运行定向测试确认失败。
3. 在既有 SaveData 同一事务内合并引导状态。
4. 重跑测试至通过。

### Task 5: 闭环正常引导完成态

**Files:**
- Modify: `test/features/tutorial/application/tutorial_service_test.dart`
- Modify: `lib/features/tutorial/application/tutorial_service.dart`

1. 增加失败测试：通关 `stage_01_05` 设置 `isOnboardingCompleted=true`，其他关卡不提前设置。
2. 运行定向测试确认失败。
3. 在 caller 持锁的现有事务路径内写入完成态。
4. 重跑测试至通过。

### Task 6: 校准视觉路由与任务文档

**Files:**
- Modify: `lib/features/debug/presentation/visual_route_host.dart`
- Modify: `GDD.md`
- Modify: `docs/spec/playability_phase2_backlog.md`
- Modify: `docs/spec/rejected_task_registry.md`
- Modify: `PROGRESS.md`

1. 让 `founder_creation` 视觉路由展示有资格状态。
2. 将 GDD 的二周目快速开局从“未实装”改为当前真实语义。
3. 对 backlog 中已完成但仍未勾选的祖师塑形和审计条目作状态订正。
4. 在已否任务登记中保留历史，同时把已完成条目标注为不可再作为活动候选。
5. 在 `PROGRESS.md` 记录本批实现与验证。

### Task 7: 全量验证与交付

**Files:**
- Verify: all changed files

1. 运行 `dart format` 格式化改动 Dart 文件。
2. 运行全部相关定向测试。
3. 运行 `flutter analyze lib test`。
4. 运行 `flutter test --no-pub --reporter json`。
5. 运行 `flutter build macos --debug`。
6. 对 `founder_creation` 执行 `1280x720` 与 `1440x900` 视觉验收并检查截图。
7. 按实现、文档校准、READY 收口拆分提交，确认工作区干净。
