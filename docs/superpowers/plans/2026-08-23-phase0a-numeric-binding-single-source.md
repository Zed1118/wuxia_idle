# Phase 0A 数字技能绑定单一来源清理计划

## 目标

删除 `Phase0aStageMapping.numericSkillBindings` 重复镜像，统一从承担输入解释
职责的 `Phase0aPlayerInputAdapter.numericSkillBindings` 读取。只收紧对象图，不改变
技能装配、输入、UI、结算或 bot 行为。

## 分支

`main`（夜班直接收口、提交并推送）。

## 验收标准

- [x] mapping 不再声明或构造数字技能绑定镜像。
- [x] 三个生产战斗宿主从 player adapter 向战斗 UI 传递同一绑定实例。
- [x] mapper、真实 Isar、画像、UI 与 settlement 测试改读单一来源并保持全绿。
- [x] 红线影响：不改 reducer、AI、伤害、资源、奖励、YAML、文案或玩法数值。
- [x] 批末：目标测试、Phase 0A application、analyze、format/diff check 通过。

## 任务切片

1. 删除 mapping 字段和构造参数。
2. 将生产宿主与测试读取迁到 player adapter。
3. 搜索残留并执行定向及目录级验证。
4. 更新总账，提交并推送。

## 当前恢复点

- 状态：已完成，待提交推送。
- 最后完成：删除 mapping 镜像，三宿主与测试统一从 player adapter 读取。
- 下一步：更新总账，提交推送。
- 已跑验证：目标独立文件 **36/36**、Phase 0A application **139/139**；
  `flutter analyze --no-pub lib test` 0 issue，format/diff check 通过。
- 阻塞项：无。
