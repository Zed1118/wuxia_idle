# 2026-06-29 今晚挂机任务 09：周目敌人词条可视化

## 目标

让二周目、三周目的敌人词条在关卡行和战前情报中可读可解释。玩家应能在开战前看懂「真气」「玉体」等周目词条带来的战斗差异，而不是只感到暗中变难。

## 分支

`codex/night-tier2-cycle-trait-visibility`

## 验收标准

- 关卡行在二周目及以上显示敌人周目词条摘要，未解锁/未选择高周目时不误导。
- 战前情报弹窗展示敌人词条说明，解释词条效果与风险。
- 只做可视化/说明，不改周目数值、不改掉落、不新增日课、留存、在线 buff 或首通差异奖励。
- UI 中文文案进入 `UiStrings` 或既有集中格式化层，不在 presentation 散写中文。
- 有 targeted tests 覆盖词条说明生成和 UI 展示；运行 targeted tests 与 touched-file analyze。

## 任务切片

1. 定位周目词条数据结构、关卡行、战前情报弹窗和现有测试。
2. 设计集中 formatter/文案入口，产出词条摘要与详情说明。
3. 接入关卡行高周目词条摘要。
4. 接入战前情报弹窗词条说明。
5. 补 targeted tests，运行 analyze/test。
6. 更新 `PROGRESS.md` 与本计划恢复点，小切片提交。

## 当前恢复点

- 状态：完成，等待上游复核/合并。
- 最后完成：新增 `CycleTraitIntel` 集中 formatter；关卡行显示高周目词条摘要；战前情报新增「周目词条」段；补纯函数与 widget tests；更新 `PROGRESS.md`。
- 下一步：主窗口复核分支 diff，必要时做真机视觉目检后合并。
- 已跑验证：`dart run build_runner build --delete-conflicting-outputs`；`flutter test --no-pub test/features/battle/cycle_trait_intel_test.dart test/features/loot_preview/stage_intel_dialog_test.dart test/features/mainline/presentation/stage_list_screen_test.dart`；`dart analyze lib/features/battle/domain/cycle_trait_intel.dart lib/features/mainline/presentation/stage_list_screen.dart lib/features/loot_preview/presentation/stage_intel_dialog.dart lib/shared/strings.dart test/features/battle/cycle_trait_intel_test.dart test/features/loot_preview/stage_intel_dialog_test.dart test/features/mainline/presentation/stage_list_screen_test.dart`。
- 阻塞项：无。
