# Test Infrastructure Migrations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 收口剩余直接 Isar core 初始化，并把等价的 production GameRepository 测试加载改为共享 helper。

**Architecture:** Isar 测试只替换初始化入口，不改变各文件 setUpAll 顺序；GameRepository 只迁移“读取仓库真实 data 文件”的调用，故障注入、内容 patch 和 fresh-instance 测试保留自定义 loader。

**Tech Stack:** Dart、flutter_test、Isar Community、GameRepository test support。

---

### Task 1: 盘点并分批迁移 Isar 初始化

**Files:**
- Modify: `test/**/*.dart` 中直接调用 `Isar.initializeIsarCore(download: true)` 的测试
- Reuse: `test/support/isar_test_support.dart`

- [x] **Step 1: 生成文件清单并按 `data/balance/features/tools` 四批记录基线数量。**
- [x] **Step 2: 每批把直接调用替换为 `initializeTestIsarCore`，保留生产配置加载的先后顺序并删除未使用 Isar import。**
- [x] **Step 3: 每批运行对应目录定向测试；失败时只修 import/初始化顺序，不改测试语义。**
- [x] **Step 4: 断言除 helper 本身和说明注释外直接调用计数为 0。**
- [x] **Step 5: 提交**：`git commit -m "Finish Isar test core migration"`。

### Task 2: 迁移等价 production repository loader

**Files:**
- Modify: production-data tests under `test/core`, `test/combat`, `test/balance`, `test/features`, `test/tools`
- Reuse: `test/support/test_data.dart`

- [x] **Step 1: 只选取等价于以下代码的调用**：

```dart
await GameRepository.loadAllDefs(loader: (path) => File(path).readAsString());
```

替换为：

```dart
await loadTestGameRepository();
```

- [x] **Step 2: 保留 `game_repository_test.dart`、broken/patched/hybrid loader、期望抛错和必须 fresh repo 的测试。**
- [x] **Step 3: 按目录运行定向测试，确认全局 singleton 复用不改变断言。**
- [x] **Step 4: 删除迁移后未使用的 `dart:io` import。**
- [x] **Step 5: 提交**：`git commit -m "Finish production repository test migration"`。

### Task 3: 迁移批验证与记录

- [x] **Step 1: `flutter analyze lib/ test/`。**
- [x] **Step 2: `flutter test --no-pub`。**
- [x] **Step 3: 更新 backlog 与 PROGRESS 的迁移文件数和剩余直接调用数。**
- [x] **Step 4: 迁移记录纳入最终质量批验证提交。**

## 当前恢复点

- 状态：Task 1-3 实现与验证完成，等待最终文档提交。
- 最后完成：新增迁移 204 文件，使用共享 helper 的文件 45→249；直接 `loadAllDefs` 文件 230→25；直接 Isar Core 初始化 95→0。
- 下一步：提交最终恢复点并进入 PR CI。
- 已跑验证：repository 首批目录回归 `balance/combat/data` 756/756、`features` 2727/2727、`tools` 42/42；返回 repo 批 162/162；`fileLoader` 批 232/232；最终补充批 112/112 + 133/133；全量测试 3790/3790；`flutter analyze lib/ test/` 0 问题。剩余直接调用均为 helper 自身、broken/patched/hybrid/fresh-instance 或多次重载测试。
- 阻塞项：无。
