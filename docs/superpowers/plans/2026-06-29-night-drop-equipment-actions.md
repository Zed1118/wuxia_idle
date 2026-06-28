# Equipment Drop Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在胜利结算里给新掉落装备提供轻量即时处理入口，减少战后进仓库前的堆积感。

**Branch:** `codex/night-drop-equipment-actions`

**Architecture:** 复用 `StageVictoryContent` 的掉落列表作为入口，复用 `EquipmentService.setLocked` 写锁定状态，复用 `EquipmentSourceLookup`/`EquipmentSource` 派生来源说明。胜利弹窗只提供锁定、标记常用、查看来源、稍后处理；不提供出售/分解，不改掉落 roll、装备 schema、save version 或数值。

**Tech Stack:** Flutter Desktop, Riverpod 3.x, Isar, existing Wuxia UI widgets.

---

## Acceptance Criteria

- [ ] 胜利结算里每件新掉落装备显示轻量动作区：锁定/解锁、标记常用、查看来源、稍后处理。
- [ ] 锁定和常用动作都只通过既有锁定字段保护装备，不新增会影响存档 schema 的字段。
- [ ] 已锁定、师承遗物、已装备等既有安全规则保持不被绕过；本功能不出现出售/分解按钮。
- [ ] 来源展示复用 `EquipmentSourceLookup`，不复制掉落表硬编码。
- [ ] 中文文案集中进 `UiStrings`，presentation 不散写中文。
- [ ] 至少补 `StageVictoryContent` targeted widget tests，覆盖按钮展示、来源弹窗、锁定回调、不出现出售/分解。
- [ ] 运行 targeted widget test 与 `flutter analyze`。

## Task Slices

### Task 1: 计划与落点确认

**Files:**
- Create: `docs/superpowers/plans/2026-06-29-night-drop-equipment-actions.md`

- [x] 读取 `AGENTS.md`、`CLAUDE.md`、`GDD.md`、`PROGRESS.md`、`docs/spec/playability_phase2_backlog.md`。
- [x] 确认 worktree 隔离状态并创建分支 `codex/night-drop-equipment-actions`。
- [x] 调研 `StageVictoryContent`、`EquipmentDetailScreen`、`EquipmentService.setLocked`、`EquipmentSourceLookup`。
- [ ] 提交计划文件。

### Task 2: 胜利结算装备动作 UI

**Files:**
- Modify: `lib/features/mainline/presentation/stage_victory_dialog.dart`
- Modify: `lib/shared/strings.dart`

- [ ] 给 `StageVictoryContent` 增加可选回调：`onEquipmentLockToggle`、`onEquipmentMarkFavorite`。
- [ ] 把 `_EquipmentDropRow` 从纯文本行扩展为紧凑操作块，显示装备名、品阶、锁定状态、来源摘要与动作按钮。
- [ ] “标记常用”调用同一锁定回调并显示常用语义文案，避免新增 schema 字段。
- [ ] “稍后处理”只折叠/弱化当前操作块或保持无副作用关闭意图，不写库。
- [ ] “查看来源”弹出只读 `PaperDialog`，来源来自 `EquipmentSourceLookup`。

### Task 3: 安全规则与回调接线

**Files:**
- Modify: `lib/features/mainline/presentation/stage_victory_dialog.dart`
- Modify: victory dialog caller if needed after reading call sites.

- [ ] 默认无回调时 UI 仍可只读渲染，保持现有测试和非持久化路径兼容。
- [ ] 有回调时只允许修改 `Equipment.isLocked`，不触发出售/分解。
- [ ] 对 `isLineageHeritage`、`ownerCharacterId != null`、`isLocked` 状态显示保护提示，不提供危险动作。

### Task 4: Targeted Tests

**Files:**
- Modify: `test/features/mainline/presentation/stage_victory_dialog_test.dart`

- [ ] 测试装备掉落显示锁定、查看来源、标记常用、稍后处理动作。
- [ ] 测试点击锁定/常用调用回调并更新 UI。
- [ ] 测试查看来源弹窗显示主线/塔层等来源标签。
- [ ] 测试胜利结算不出现出售/分解按钮。

### Task 5: Verification And Closeout

**Files:**
- Modify: `docs/superpowers/plans/2026-06-29-night-drop-equipment-actions.md`
- Modify: `PROGRESS.md` only if final project convention requires it for this batch.

- [ ] 运行 `flutter test --no-pub test/features/mainline/presentation/stage_victory_dialog_test.dart`。
- [ ] 运行 `flutter analyze`。
- [ ] 更新当前恢复点。
- [ ] 提交实现切片。

## Current Recovery Point

**Status:** 计划创建中。

**Last completed:** 已读取必读文档；已在隔离 worktree `/Users/a10506/.codex/worktrees/8bbc/挂机武侠` 创建分支 `codex/night-drop-equipment-actions`；已确认胜利弹窗、装备详情页锁定、来源反查与保护规则落点。

**Next step:** 提交本计划文件，然后实现 `StageVictoryContent` 的新装备动作区。

**Verification run:** 尚未运行功能验证；当前仅完成文档与代码调研。

**Blocked:** 无。
