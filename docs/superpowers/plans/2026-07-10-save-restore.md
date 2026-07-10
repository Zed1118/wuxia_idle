# Save Restore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在设置页补齐当前槽历史备份恢复，并保证恢复前安全备份、替换失败回滚和崩溃后启动自愈。

**Architecture:** `SaveManagementService` 编排恢复，`SaveRestoreFileOps` 隔离可注入文件故障，`IsarSetup` 持有 schema 校验和启动恢复知识。UI 只选择备份、确认、阻塞交互并在数据库关闭后退出应用。

**Tech Stack:** Dart IO、Isar Community、Riverpod、Flutter Material、flutter_test。

---

### Task 1: 恢复领域类型与文件边界

**Files:**
- Create: `lib/features/save_management/domain/save_restore.dart`
- Create: `lib/features/save_management/application/save_restore_file_ops.dart`
- Test: `test/features/save_management/save_restore_file_ops_test.dart`

- [x] **Step 1: 写失败测试**，验证 `DartIoSaveRestoreFileOps` 可 copy、rename、delete，并且缺失文件的 `exists` 为 false。
- [x] **Step 2: 运行测试确认因类型不存在而失败**：
  `flutter test --no-pub test/features/save_management/save_restore_file_ops_test.dart`
- [x] **Step 3: 定义固定类型**：

```dart
enum SaveRestorePhase {
  preflight,
  safetyBackup,
  closeDatabase,
  swapFiles,
  rollbackFiles,
}

class SaveRestoreResult {
  const SaveRestoreResult({
    required this.selectedBackup,
    required this.safetyBackup,
    required this.slotId,
  });
  final SaveBackupInfo selectedBackup;
  final SaveBackupInfo safetyBackup;
  final int slotId;
}

class SaveRestoreException implements Exception {
  const SaveRestoreException({
    required this.phase,
    required this.requiresRestart,
    required this.cause,
  });
  final SaveRestorePhase phase;
  final bool requiresRestart;
  final Object cause;
}
```

- [x] **Step 4: 实现仅含 `copy/rename/delete/exists/length` 的文件边界并跑绿测试。**
- [x] **Step 5: 提交**：`git commit -m "Add save restore file boundary"`。

### Task 2: Isar 候选校验与启动自愈

**Files:**
- Modify: `lib/data/isar_setup.dart`
- Test: `test/data/isar_setup_slots_test.dart`

- [ ] **Step 1: 写失败测试**：候选档槽位一致时返回元数据；错误槽位、未来版本、无祖师档抛错。
- [ ] **Step 2: 写失败测试**：正式文件缺失时 rollback 优先于 candidate；正式文件存在时清理 partial/candidate/rollback。
- [ ] **Step 3: 运行定向测试确认失败**：
  `flutter test --no-pub test/data/isar_setup_slots_test.dart`
- [ ] **Step 4: 在 `init()` 的 `Isar.open` 前调用**：

```dart
await _recoverInterruptedRestore(dir, slotId);
```

- [ ] **Step 5: 新增 `validateRestoreCandidate`**，用 `_allSchemas` 打开候选副本，读取 id=0 的 `SaveData` 和祖师，使用 `_compareVersion` 拒绝未来版本，finally 关闭临时实例。
- [ ] **Step 6: 实现固定文件名恢复顺序并重新运行测试至通过。**
- [ ] **Step 7: 提交**：`git commit -m "Add Isar restore validation and recovery"`。

### Task 3: 成功恢复与自动安全备份

**Files:**
- Modify: `lib/features/save_management/application/save_management_service.dart`
- Modify: `lib/features/save_management/domain/save_management_status.dart`
- Test: `test/features/save_management/save_management_service_test.dart`

- [ ] **Step 1: 写失败测试**：备份状态 A、当前改成 B、恢复 A、重开后读到 A，安全备份打开后读到 B。
- [ ] **Step 2: 写失败测试**：目录外、错误槽、缺失、空文件和损坏备份均在当前 Isar 仍打开时失败。
- [ ] **Step 3: 运行测试确认失败**：
  `flutter test --no-pub test/features/save_management/save_management_service_test.dart`
- [ ] **Step 4: 实现签名**：

```dart
Future<SaveRestoreResult> restoreBackup(SaveBackupInfo backup)
```

实现顺序固定为 path/filename 预检、partial copy、candidate rename、Isar 候选校验、`touchOnlineNow()`、`createBackup()`、close、正式档→rollback、candidate→正式档、清理 rollback。

- [ ] **Step 5: 所有第 6 步前异常包装为 `requiresRestart: false`，并清理 partial/candidate。**
- [ ] **Step 6: 运行服务测试至通过并提交**：`git commit -m "Implement safe save restore"`。

### Task 4: 文件替换失败回滚

**Files:**
- Modify: `test/features/save_management/save_management_service_test.dart`
- Modify: `lib/features/save_management/application/save_management_service.dart`

- [ ] **Step 1: 用 fake `SaveRestoreFileOps` 在 candidate→正式文件 rename 注入异常。**
- [ ] **Step 2: 断言正式文件由 rollback 恢复，抛出的 `SaveRestoreException.phase` 为 `swapFiles` 且 `requiresRestart` 为 true。**
- [ ] **Step 3: 再注入 rollback rename 失败，断言 phase 为 `rollbackFiles` 且安全备份仍存在。**
- [ ] **Step 4: 运行服务与槽位测试至通过。**
- [ ] **Step 5: 提交**：`git commit -m "Cover save restore rollback failures"`。

### Task 5: 设置页恢复交互

**Files:**
- Modify: `lib/shared/strings.dart`
- Modify: `lib/features/settings/presentation/settings_panel.dart`
- Test: `test/features/settings/settings_panel_save_restore_test.dart`

- [ ] **Step 1: 写 widget 失败测试**：无备份禁用；多备份倒序显示文件名、时间、大小；选择后出现自动安全备份与退出说明。
- [ ] **Step 2: 写 widget 失败测试**：预检失败不调用 `AppExit.quit`；成功和 `requiresRestart=true` 失败只显示关闭动作并调用 quit override。
- [ ] **Step 3: 运行测试确认失败**：
  `flutter test --no-pub test/features/settings/settings_panel_save_restore_test.dart`
- [ ] **Step 4: 删除 `saveManagementRestoreTodo`，新增选择、确认、处理中、成功、失败和关闭游戏文案。**
- [ ] **Step 5: 实现 `_selectBackup`、`_confirmRestore`、`_runRestore` 三段流程；处理期间使用不可 dismiss 的 `PaperDialog`。**
- [ ] **Step 6: 运行 widget 测试与现有 settings overflow/slot-switch 测试至通过。**
- [ ] **Step 7: 提交**：`git commit -m "Add save restore settings flow"`。

### Task 6: 存档恢复批验证

**Files:**
- Modify: `PROGRESS.md`
- Modify: `docs/superpowers/plans/2026-07-10-quality-batch-master.md`

- [ ] **Step 1: 运行格式化与静态检查**：
  `dart format lib/data/isar_setup.dart lib/features/save_management lib/features/settings/presentation/settings_panel.dart test/data/isar_setup_slots_test.dart test/features/save_management test/features/settings/settings_panel_save_restore_test.dart`
  `flutter analyze lib/ test/`
- [ ] **Step 2: 运行存档相关测试**：
  `flutter test --no-pub test/data/isar_setup_slots_test.dart test/features/save_management test/features/settings`
- [ ] **Step 3: macOS 1280x720 与 1440x900 检查选择、确认、处理中、成功/失败状态，无 overflow/exception。**
- [ ] **Step 4: 更新 PROGRESS 与主计划恢复点并提交**：`git commit -m "Document save restore completion"`。

## 当前恢复点

- 状态：Task 1 已完成，Task 2 待开始。
- 最后完成：恢复领域类型与可注入文件边界已按 TDD 实现。
- 下一步：Task 2 Step 1，写 Isar 候选校验与启动中断恢复测试。
- 已跑验证：`save_restore_file_ops_test.dart` 1/1 通过；设计文档 diff check 通过。
- 阻塞项：无。
