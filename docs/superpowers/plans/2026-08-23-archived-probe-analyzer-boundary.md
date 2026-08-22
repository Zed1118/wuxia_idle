# 归档难度探针 analyzer 边界修复计划

## 目标

Route C 删除旧 runner 后，恢复无参数 `flutter analyze` 可用性。只排除唯一一份
明确标注为“一次性诊断、不入 test”的 7 月历史附件，不扩大生产源码或测试的
静态分析豁免范围。

## 分支

`main`（夜班直接收口、提交并推送）。

## 验收标准

- [x] `analysis_options.yaml` 仅新增该归档附件的精确路径排除。
- [x] `lib/`、`test/`、`tool/` 与其余 Dart 文件仍受原分析规则约束。
- [x] 无参数 `flutter analyze --no-pub` 从 12 个旧符号错误恢复为 0 issue。
- [x] 标准 `flutter analyze --no-pub lib test tool` 保持 0 issue。
- [x] 不改运行代码、测试逻辑、配置数据或玩法数值。

## 任务切片

1. 记录失败基线与归档附件属性。
2. 增加单文件 analyzer exclude。
3. 复跑无参数和标准范围分析，检查差异。
4. 更新总账，提交并推送。

## 当前恢复点

- 状态：已完成，待提交推送。
- 最后完成：只对该历史附件增加精确 exclude，无参数与标准范围 analyze
  均恢复为 0 issue。
- 下一步：更新总账，提交推送。
- 已跑验证：`flutter analyze --no-pub` 0 issue；
  `flutter analyze --no-pub lib test tool` 0 issue；diff check 通过。
- 阻塞项：无。
