# 恢复点 · stage_entry_flow 测试补强（试点 A 单 · 2026-07-18）

## 目标

`lib/features/mainline/presentation/stage_entry_flow.dart`（1295 行）测试补强。

- 基线覆盖：全量 111/481 = 23.08%（任务单口径）；本子集口径实测 **LH:104 LF:481**
  （子集 = stage_entry_flow_test / stage_retry_dialog_body_test /
  defeat_loss_banner_residue_test / inner_demon_defeat_summary_test /
  scroll_firstclear_gate_test / scroll_drop_test）。
- 验收：子集同口径 LH/LF ≥ 50%（LH ≥ 241）；全量 `flutter test --no-pub` 绿
  （基线 4384 pass / 0 fail）；零 lib/ 改动。

## 分支

- worktree：`.worktrees/kimi-stage-entry-tests`
- 分支：`kimi/stage-entry-flow-tests`（基于 main 5e3feb0d）

## 任务切片

1. [x] 环境准备：worktree + pub get + build_runner + analyze 0 issues
2. [x] 基线覆盖实测（子集口径 104/481）
3. [x] 切片 1：`buildDefeatLossEntries` Boss 散功组合矩阵 + `_resolveTechName`
       分支 + `shouldSkipScrollDrop` 直测 + `buildDefeatLossBanner` 未测分支
       （19 测 · `stage_entry_flow_pure_test.dart` · 证红通过）
4. [x] 切片 2：`applyVictoryResolution` 分支面（真 Isar + 伪造 finished
       battleProvider，10 测 · `apply_victory_resolution_test.dart` · 证红通过）
       关键经验：testWidgets fake-async zone 中真 Isar 必须经
       `tester.runAsync` 执行；WidgetRef 经 Consumer 捕获后 runAsync 内直调。
5. [x] 切片 3：真实重试对话框（再战/回去）、Boss 战败损失 banner→战败剧情
       push、Boss 击杀声望（4 测 · `stage_entry_flow_branches_test.dart` ·
       证红通过）。阵型选择（`_pickFormation` 经 `_StageBattleHost` 群战
       initState）未做：需真实队伍装配 + BattleScreen 渲染,风险/耗时高,
       覆盖率已达标(52.4%),留作后续候选。
6. [x] 收尾：全量测试 + [READY] commit

## 当前恢复点

- **状态**：完工。切片 1-6 全部完成，[READY] 已打
- **最后完成**：全量测试分 6 片跑通（规避单次 Bash 300s 上限）：
  批 A（data/shared/core/combat/support/audit/widget_test）901 绿 EXIT=0；
  批 B（balance/tools）250 绿 EXIT=0；批 C（features 前段 13 目录）1522 绿
  EXIT=0；批 D（中段一 13 目录）663 绿 EXIT=0；批 E（中段二 11 目录含
  mainline）406 绿 EXIT=0；批 F（末段 12 目录）675 绿 EXIT=0。
  合计 **4417 pass / 0 fail** = 基线 4384 + 新增 33，数字精确对账。
  子集口径覆盖 **LH:252 LF:481 = 52.4%**（基线同口径 104/481 = 21.6%）。
- **下一步**：无，交 Claude 终审
- **已跑验证**：`flutter analyze --no-pub` = 0 issues；
  `dart format --output=none --set-exit-if-changed lib test` = 0 changed；
  全量 4417 绿；三切片各做断言破坏证红（红→还原→绿）
- **阻塞项**：无

## 发现的生产疑似问题（待 Claude 定夺，不修）

（暂无）
