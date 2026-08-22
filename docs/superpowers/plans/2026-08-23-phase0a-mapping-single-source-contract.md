# Phase 0A mapping 单一来源防回流计划

## 目标

将今晚删除的两处 `Phase0aStageMapping` 重复镜像固化为 Route C 源码契约，
防止后续重新引入两个可漂移真相源。只加测试，不改运行代码。

## 分支

`main`（夜班直接收口、提交并推送）。

## 验收标准

- [x] 契约测试只截取 `Phase0aStageMapping` 类体，不误伤 mapper 内合法局部变量。
- [x] 禁止 mapping 声明 `winCondition` 或 `numericSkillBindings` 字段。
- [x] 明确要求对应单一来源 `initialState` 与 `playerAdapter` 仍存在。
- [x] Route C 契约、Phase 0A application 与 analyze 全绿。
- [x] 不改运行代码、数据、文案或玩法数值。

## 任务切片

1. 在既有 Route C contract 增加类体级源码守卫。
2. 跑定向测试并做一次破坏证红。
3. 还原破坏、扩大验证、更新总账。
4. 提交并推送。

## 当前恢复点

- 状态：已完成，待提交推送。
- 最后完成：新增类体级守卫；临时回添 `winCondition` 字段后精确 1 红，
  还原后复绿。
- 下一步：更新总账，提交推送。
- 已跑验证：Route C 契约 **8/8**、Phase 0A application **139/139**、
  `flutter analyze --no-pub` 0 issue、format/diff check 通过；父提交整合态全量
  **4228/4228**。
- 阻塞项：无。
