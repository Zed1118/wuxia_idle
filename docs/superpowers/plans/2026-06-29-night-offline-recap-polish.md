# 今晚挂机任务 05：离线收益回归卡优化

## 目标

优化离线收益回归卡的明细展示：隐藏 0 值收益项，按来源分组展示经验、材料、装备、心法/招式熟练度等回归信息。只解释「在线=离线」的既有结算结果，不引入加速、在线 buff 或新的收益语义。

## 分支

`codex/night-offline-recap-polish`

## 验收标准

- 离线回归卡不再展示银两 0、熟练度 0、材料 0 等无效收益项。
- active 闭关 recap 继续复用 `OfflineRecapService.buildRecap` 已有预估字段，不提前掷定装备掉落，不重算收益。
- passive 被动 recap 继续复用 `OfflinePassiveService.settle/compute` 的 `PassiveYield`，不新增银两、装备或熟练度收益。
- 明细按来源分组，至少区分「结算说明」与实际收益来源；active 显示闭关收益与收功揭晓项，passive 显示被动精进收益。
- 中文 UI 文案集中在 `UiStrings` / formatter 合法 sink，不在 presentation 散写。
- 跑 targeted tests 与 touched-file analyze；完成后小切片 commit。

## 任务切片

1. [x] 读取 AGENTS / CLAUDE / GDD / PROGRESS / backlog，确认红线与现状。
2. [x] 创建独立分支并写本计划文件。
3. [x] 梳理既有 offline recap detail 模型与 UI 测试。
4. [x] 将 formatter 改为分组明细并隐藏 0 值收益项。
5. [x] 更新卡片展示分组标题与测试断言。
6. [x] 跑 targeted tests / analyze。
7. [x] 更新恢复点并提交。

## 当前恢复点

- 状态：完成，已提交。
- 最后完成：`OfflineRecapDetailFormatter` 改为 `groups` 分组输出；收益明细隐藏 0 值项；active 闭关分为结算说明 / 闭关收益 / 收功揭晓，仍只读 `OfflineRecap` 已有字段且装备掉落保持「收功时揭晓」；passive 被动卡分为结算说明 / 离线精进，不再展示银两 0、掉落无、熟练度 0；`OfflineRecapCard` 改为渲染分组；补充 formatter 与 widget 测试；提交 `7cb407bc`（amend 后以 `git log -1` 为准）。
- 下一步：等待主窗口复核 / 合并。
- 已跑验证：
  - `dart run build_runner build --delete-conflicting-outputs`（当前版本提示该参数已移除并忽略；写出 112 outputs，均为本地生成依赖，未出现在 git status）
  - `flutter test --no-pub test/features/seclusion/application/offline_recap_detail_test.dart test/features/seclusion/application/offline_recap_service_test.dart test/features/seclusion/presentation/offline_recap_card_test.dart test/features/seclusion/presentation/offline_recap_passive_card_test.dart`
  - `flutter analyze --no-pub lib/features/seclusion/application/offline_recap_detail.dart lib/features/seclusion/presentation/offline_recap_card.dart lib/shared/strings.dart test/features/seclusion/application/offline_recap_detail_test.dart test/features/seclusion/presentation/offline_recap_card_test.dart test/features/seclusion/presentation/offline_recap_passive_card_test.dart`
- 阻塞项：无。
