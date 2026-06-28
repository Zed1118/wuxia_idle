# 离线收益结算明细第一切片

## 目标

在回归 / 离线结算界面展示更清晰的收益来源明细：经验、银两、材料、心法 / 招式熟练度、装备掉落。第一切片只聚合和格式化已有结算字段，不改变离线 / 闭关收益算法，不引入加速、加成或在线 buff。

## 分支

`codex/offline-recap-detail`

## 验收标准

- 离线 recap 的明细由只读模型 / formatter 生成，UI 不再散拼多项结算字段。
- 明细总量来自 `OfflineRecapService` / `OfflinePassiveService` 现有结算字段，测试覆盖经验、银两、材料、心法领悟点、装备掉落占位。
- active 闭关 recap 可展示材料与心法领悟点；装备掉落仍保持“收功时揭晓”，不提前掷定。
- passive 被动离线 recap 明确展示无银两、无心法 / 招式熟练度、无装备掉落，不改变自动入库逻辑。
- 中文 UI 文案集中在 `UiStrings`。
- 跑 targeted test 和 touched-file analyze。

## 任务切片

1. [x] 定位离线结算 domain/result 与 presentation 入口。
2. [x] 新增只读明细模型 / formatter，聚合已有字段。
3. [x] 扩展 `OfflineRecap` 暴露已有 `computeOutputs` 里的材料与心法领悟点。
4. [x] 接入 `OfflineRecapCard`，所有中文走 `UiStrings`。
5. [x] 写测试证明明细总量来自已有结算字段。
6. [x] 跑 targeted test 与 touched-file analyze。
7. [x] 小切片 commit，保留 worktree 给主窗口检查。

## 当前恢复点

- 状态：第一切片完成，已提交（以 `git log -1` 为准）。
- 最后完成：新增 `OfflineRecapDetailFormatter`；active recap 原样携带 `computeOutputs` 已有 `itemRewards` / `techniqueLearnPoints`；active/passive `OfflineRecapCard` 统一读取明细行；中文文案归集到 `UiStrings`；补充 formatter、service、widget 测试；已小切片提交。
- 下一步：等待主窗口检查；后续切片可继续扩展更多离线战斗 / 扫荡来源明细。
- 已跑验证：
  - `dart run build_runner build --delete-conflicting-outputs`（当前版本提示该参数已移除并忽略，最终写出 112 outputs；生成产物 gitignored 不提交）
  - `flutter test test/features/seclusion/application/offline_recap_detail_test.dart test/features/seclusion/application/offline_recap_service_test.dart test/features/seclusion/presentation/offline_recap_card_test.dart test/features/seclusion/presentation/offline_recap_passive_card_test.dart`
  - `flutter analyze lib/features/seclusion/application/offline_recap_detail.dart lib/features/seclusion/application/offline_recap_service.dart lib/features/seclusion/presentation/offline_recap_card.dart lib/shared/strings.dart test/features/seclusion/application/offline_recap_detail_test.dart test/features/seclusion/application/offline_recap_service_test.dart test/features/seclusion/presentation/offline_recap_card_test.dart test/features/seclusion/presentation/offline_recap_passive_card_test.dart`
- 阻塞项：无。CodeGraph 未初始化，本切片已改用 `rg` 与定向读文件定位。
