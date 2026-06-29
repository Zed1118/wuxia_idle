# 关卡列表章节轴重做计划

## 目标

把主线章节内的纯关卡列表改成更有章节节奏的卷轴 / 路标式结构。重做仅限展示层与集中 UI 文案，不改变关卡解锁、进入战斗、扫荡、战前情报、推荐刷点、周目词条、掉落和结算逻辑。

## 分支

`codex/next-stage-chapter-timeline`

## 边界

- 不做地图地域化。
- 不新增收益、奖励或掉落。
- 不改变 `MainlineProgressService`、`runStageFlow`、扫荡结算、关卡数据和解锁链。
- 不在 Dart presentation 散写中文，新增 UI 文案进 `UiStrings`。
- 保留近期二梯队接入点：周目词条、扫荡前预估、主线章节推荐刷点、战前情报、重打收益路线、整备条。

## 摸排结论

- 主入口：`lib/features/mainline/presentation/stage_list_screen.dart`。
- 现状已有 `_StageJourneyMap` 章头横向节点，但实际关卡仍由 `_StageRow` 顺序列表渲染。
- `_StageRow` 内部承载大量近期改动，风险集中在行内逻辑；本次应复用 `_StageRow`，只改外层编排。
- 相关测试：`test/features/mainline/presentation/stage_list_screen_test.dart`、`stage_list_screen_cycle_test.dart`、`stage_row_loot_wiring_test.dart`。
- CodeGraph 在本 worktree 未初始化；按项目说明未擅自初始化，改用 `rg` 和文件阅读摸排。

## 验收标准

- 章节内关卡呈现为卷轴 / 路标式章节轴，而不是无结构的纯列表。
- 已通关、可挑战、锁定、Boss 节点状态清晰可读。
- 点击可挑战 / 已通关关卡仍走原 `runStageFlow`。
- 行尾战前情报、整备条、周目词条、重打路线仍显示。
- 章节推荐刷点和扫荡前预估仍显示在章级区域。
- `flutter analyze` 0 issue。
- Targeted tests 通过。

## 任务切片

- [x] 读取启动必读文档与批次计划。
- [x] 创建并切到分支。
- [x] 摸排 stage list 结构和近期接入点。
- [x] 引入章节轴外层容器，复用 `_StageRow` 作为每个路标节点内容。
- [x] 补集中 UI 文案与 widget 测试。
- [x] 跑 targeted tests 与 `flutter analyze`。
- [x] 自检 diff，提交本分支。

## 当前恢复点

- 状态：实现与验证完成，准备提交。
- 最后完成：新增章节轴布局组件，复用 `_StageRow` 保留近期接入点；补集中 UI 文案和 widget 测试。
- 下一步：提交本分支。
- 已跑验证：`dart run build_runner build --delete-conflicting-outputs`（恢复本 worktree 生成文件状态；该参数被当前 build_runner 忽略但构建成功）、`flutter test --no-pub test/features/mainline/presentation/stage_list_screen_test.dart test/features/mainline/presentation/stage_list_screen_cycle_test.dart test/features/loot_preview/stage_row_loot_wiring_test.dart`、`flutter analyze`。
- 阻塞项：无。CodeGraph 未初始化，但不阻塞本任务。
