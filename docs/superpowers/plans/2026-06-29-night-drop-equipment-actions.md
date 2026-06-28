# Equipment Drop Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在胜利结算里给新掉落装备提供轻量即时处理入口，减少战后进仓库前的堆积感。

**Branch:** `codex/night-drop-equipment-actions`

**Architecture:** 复用 `StageVictoryContent` 的掉落列表作为入口，复用 `EquipmentService.setLocked` 写锁定状态，复用 `EquipmentSourceLookup`/`EquipmentSource` 派生来源说明。胜利弹窗只提供锁定、标记常用、查看来源、稍后处理；不提供出售/分解，不改掉落 roll、装备 schema、save version 或数值。

**Tech Stack:** Flutter Desktop, Riverpod 3.x, Isar, existing Wuxia UI widgets.

---

## Acceptance Criteria

- [x] 胜利结算里每件新掉落装备显示轻量动作区：锁定/解锁、标记常用、查看来源、稍后处理。
- [x] 锁定和常用动作都只通过既有锁定字段保护装备，不新增会影响存档 schema 的字段。
- [x] 已锁定、师承遗物、已装备等既有安全规则保持不被绕过；本功能不出现出售/分解按钮。
- [x] 来源展示复用 `EquipmentSourceLookup`，不复制掉落表硬编码。
- [x] 中文文案集中进 `UiStrings`，presentation 不散写中文。
- [x] 至少补 `StageVictoryContent` targeted widget tests，覆盖按钮展示、来源弹窗、锁定回调、不出现出售/分解。
- [x] 运行 targeted widget test 与 `flutter analyze`。

## Task Slices

### Task 1: 计划与落点确认

**Files:**
- Create: `docs/superpowers/plans/2026-06-29-night-drop-equipment-actions.md`

- [x] 读取 `AGENTS.md`、`CLAUDE.md`、`GDD.md`、`PROGRESS.md`、`docs/spec/playability_phase2_backlog.md`。
- [x] 确认 worktree 隔离状态并创建分支 `codex/night-drop-equipment-actions`。
- [x] 调研 `StageVictoryContent`、`EquipmentDetailScreen`、`EquipmentService.setLocked`、`EquipmentSourceLookup`。
- [x] 提交计划文件。

### Task 2: 胜利结算装备动作 UI

**Files:**
- Modify: `lib/features/mainline/presentation/stage_victory_dialog.dart`
- Modify: `lib/shared/strings.dart`

- [x] 给 `StageVictoryContent` 增加可选回调：`onEquipmentLockToggle`。
- [x] 把 `_EquipmentDropRow` 从纯文本行扩展为紧凑操作块，显示装备名、品阶、锁定状态、来源摘要与动作按钮。
- [x] “标记常用”调用同一锁定回调并显示常用语义文案，避免新增 schema 字段。
- [x] “稍后处理”只折叠/弱化当前操作块或保持无副作用关闭意图，不写库。
- [x] “查看来源”弹出只读 `PaperDialog`，来源来自 `EquipmentSourceLookup`。

### Task 3: 安全规则与回调接线

**Files:**
- Modify: `lib/features/mainline/presentation/stage_victory_dialog.dart`
- Modify: victory dialog caller if needed after reading call sites.

- [x] 默认无回调时 UI 仍可只读渲染，保持现有测试和非持久化路径兼容。
- [x] 有回调时只允许修改 `Equipment.isLocked`，不触发出售/分解。
- [x] 对 `isLineageHeritage`、`ownerCharacterId != null`、`isLocked` 状态显示保护提示，不提供危险动作。

### Task 4: Targeted Tests

**Files:**
- Modify: `test/features/mainline/presentation/stage_victory_dialog_test.dart`

- [x] 测试装备掉落显示锁定、查看来源、标记常用、稍后处理动作。
- [x] 测试点击锁定/常用调用回调并更新 UI。
- [x] 测试查看来源弹窗显示主线/塔层等来源标签。
- [x] 测试胜利结算不出现出售/分解按钮。

### Task 5: Verification And Closeout

**Files:**
- Modify: `docs/superpowers/plans/2026-06-29-night-drop-equipment-actions.md`
- Modify: `PROGRESS.md` only if final project convention requires it for this batch.

- [x] 运行 `flutter test --no-pub test/features/mainline/presentation/stage_victory_dialog_test.dart`。
- [x] 运行 `flutter analyze`。
- [x] 更新当前恢复点。
- [x] 提交实现切片。

## Current Recovery Point

**Status:** 已完成。

**Last completed:** 胜利结算装备掉落行已扩展为即时处理块；主线胜利流程已接 `EquipmentService.setLocked`；文案集中进 `UiStrings`；新增 5 个 targeted widget tests 覆盖动作区、锁定、常用、来源、稍后处理与不显示出售/分解。

**Next step:** 汇报分支、提交、验证与剩余风险。

**Verification run:** `flutter test --no-pub test/features/mainline/presentation/stage_victory_dialog_test.dart` 26 passed；`flutter analyze` No issues found。

**Blocked:** 无。
