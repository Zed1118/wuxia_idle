# 新档目标引导二期计划

## 目标

在主界面和主线关卡入口用轻提示说明当前自然目标：打哪关、拿什么、为什么。不做教程弹窗、不做任务系统、不加奖励、不写存档，只从当前进度、关卡与掉落配置只读派生。

## 分支

`codex/next-new-save-goal-guidance`

## 验收标准

- 主菜单「主线」入口能显示当前可挑战关卡及关键收获/推进理由。
- 关卡列表中当前可挑战关显示一条目标提示，已通关/锁定关不显示伪目标。
- 战前情报弹窗可查看同一目标提示。
- 文案集中在 `UiStrings`，Dart presentation/domain 不散写中文。
- 不改 `numbers.yaml`、schema、saveVersion、结算、奖励或门槛。
- targeted tests 与 `flutter analyze` 通过。

## 任务切片

- [x] 读取启动文档与现有入口代码。
- [x] 写本计划文件。
- [x] 新增只读目标引导派生服务与单测。
- [x] 接入主菜单状态、关卡行、战前情报。
- [x] 补 widget/domain targeted tests。
- [x] 跑 targeted tests 与 `flutter analyze`。
- [x] 更新恢复点并提交。

## 当前恢复点

- 状态：实现与验证已完成，随本计划提交。
- 最后完成：新增 `NewSaveGoalGuidance` 只读派生；主菜单主线 hint、当前可挑战关卡行、战前情报弹窗均接入同源目标提示；backlog/PROGRESS 已同步。
- 下一步：主窗口复核并按批次合并。
- 已跑验证：`flutter test --no-pub test/features/mainline/new_save_goal_guidance_test.dart test/features/main_menu/presentation/main_menu_test.dart test/features/loot_preview/stage_row_loot_wiring_test.dart test/features/loot_preview/stage_intel_dialog_test.dart`；`flutter analyze`。
- 阻塞项：无。CodeGraph 在本 worktree 未初始化，当前用 `rg`/文件读取推进。
