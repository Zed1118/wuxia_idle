# 桃花岛生产队列可读化

## 目标

让每个桃花岛建筑在现有卡片内显示当前配方、下一件剩余时间、满仓时间、产物去向，降低“岛上到底在产什么、多久能收、产物拿来干什么”的黑箱感。

## 分支

`codex/next-taohua-production-readability`

## 边界

- 不改产量、离线结算规则、升级成本、配方成本、仓储上限。
- 不新增存档字段，不改 schema/saveVersion。
- 展示只从现有桃花岛 config、`IslandProductionService.settle`、`IslandView` 快照、资源用途反查派生。
- UI 文案进入 `UiStrings` 集中层，不在 presentation 散写中文。

## 验收标准

- source 建筑显示采集产物、下一件时间、满仓时间、产物用途。
- processor 建筑显示当前激活配方、下一件时间、满仓时间、产物用途。
- 未选配方、境界未达、满仓、无进展等状态有可读提示。
- 时间推导复用现有纯结算函数，不维护第二套生产公式。
- targeted tests 通过，`flutter analyze` 通过。

## 任务切片

- [x] 读取 `AGENTS.md`、`CLAUDE.md`、`GDD.md`、`PROGRESS.md`、`docs/spec/playability_phase2_backlog.md`、`docs/superpowers/plans/2026-06-29-next-stage-candidate-batch.md`。
- [x] 创建并切换分支。
- [x] 新增只读生产可读性派生模型，基于 `IslandProductionService.settle` 二分探测下一件/满仓时间。
- [x] 在建筑卡接入配方、剩余时间、满仓时间、产物去向。
- [x] 增加 widget/domain targeted tests。
- [x] 跑 targeted tests 与 `flutter analyze`。
- [ ] 更新本计划恢复点并提交。

## 当前恢复点

- 状态：实现与验证完成，待提交。
- 最后完成：新增 `IslandProductionReadability` 只读派生；建筑卡显示当前采集/配方、下一件、满仓、去向；产物用途复用 `ItemUsageLookupService`。
- 下一步：暂存本任务文件并提交。
- 已跑验证：`flutter test --no-pub -j1 test/features/taohua_island/island_production_readability_test.dart test/features/taohua_island/taohua_island_screen_test.dart`；`flutter test --no-pub -j1 test/features/taohua_island`；`flutter analyze`。
- 阻塞项：无。
