# Phase 0A 胜负条件单一来源清理计划

## 目标

删除 `Phase0aStageMapping.winCondition` 重复镜像，统一从
`Phase0aStageMapping.initialState.winCondition` 读取。只收紧数据结构，不改变
胜负判定、映射输入或运行行为。

## 分支

`main`（夜班直接收口、提交并推送）。

## 验收标准

- [x] 生产结构不再声明或构造 `Phase0aStageMapping.winCondition`。
- [x] survive-ticks 与主线接线测试直接断言初始状态中的胜负条件。
- [x] malformed mapping 回归继续覆盖结算 fail-closed 行为。
- [x] 红线影响：不改 reducer、AI、伤害、奖励、YAML、文案或玩法数值。
- [x] 批末：目标测试、Phase 0A application、analyze、format/diff check 通过。

## 任务切片

1. 删除 mapping 顶层重复字段与构造参数。
2. 改写三个测试文件中的镜像读取。
3. 搜索残留并执行定向及目录级验证。
4. 更新总账，提交并推送。

## 当前恢复点

- 状态：已完成，待提交推送。
- 最后完成：删除 mapping 顶层镜像并将测试统一到初始状态。
- 下一步：更新总账，提交推送。
- 已跑验证：目标三文件 24/24、Phase 0A application 139/139；
  `flutter analyze --no-pub lib test` 0 issue，format/diff check 通过。父提交
  full 4226/4226、release 双架构构建通过。
- 阻塞项：无。
