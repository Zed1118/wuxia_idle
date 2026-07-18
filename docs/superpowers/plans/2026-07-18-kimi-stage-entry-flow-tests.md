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
3. [ ] 切片 1：`buildDefeatLossEntries` Boss 散功组合矩阵 + `_resolveTechName`
       分支 + `shouldSkipScrollDrop` 直测 + `buildDefeatLossBanner` 未测分支
       （空 entries / 伤势汇总行 / 层数段 / 修炼度段 / 混合标题）
4. [ ] 切片 2：`applyVictoryResolution` 分支面（真 Isar + 造 finished
       battleProvider）：Isar 未 ready / 战斗未结束 / 无角色 / 掉落写入 /
       秘籍首通门控 / 库存合并 / boss 首通事件上下文
5. [ ] 切片 3（视时间）：`runStageFlow` 胜利全链路集成 或 `_pickFormation`
       公开消费路径（_StageBattleHost 群战 initState）
6. [ ] 收尾：全量测试 + 覆盖率复测 + format 兜底 + [READY] commit

## 当前恢复点

- **状态**：切片 3 待开工（环境 + 基线就绪）
- **最后完成**：基线覆盖实测 LH:104 LF:481（子集口径）
- **下一步**：写切片 1 测试文件，先证红再定稿
- **已跑验证**：`flutter analyze --no-pub` = 0 issues；基线子集 25 测全绿
- **阻塞项**：无

## 发现的生产疑似问题（待 Claude 定夺，不修）

（暂无）
