# P2 批一 1.5：强化 N14 手动回放守卫

## 目标

把 N14 第 2 组的间接 command 摘要对比改为直接守卫：前台 bot 生成的每条命令都必须被 manual controller 实际回放，不能因提前进入终局而静默 `break`。

## 分支与边界

- 分支：`codex/p2-b1-n14-replay-guard-20260827`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-p2-b1-n14-replay-guard`
- 堆叠基线：N14 `85ee8483 [READY] 补齐同核奖励证据`；该测试尚不在 main 或集成分支。
- 只修改 N14 测试与本恢复点，不改生产代码、奖励规则或证据结论。
- 禁止修改：`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`。

## 验收标准

1. matrix 显式暴露 bot 命令数与 manual 实际回放数。
2. 第 2 组先断言命令非空、回放数完整，再校验四模式逐 tick hash。
3. 临时制造 manual 提前一拍 `break` 时，矩阵构造必须拒绝 ongoing 结算；临时少报一条实际回放时，第 2 组必须在新增守卫处证红；还原后 7/7 复绿。
4. scoped analyze、format、禁区核查通过，工作区 clean，tip 为中文 `[READY]` 或 `[BLOCKED]`。

## 当前恢复点

- 状态：READY，等待协调者随 N14 一并集成。
- 最后完成：新增 bot 命令数与 manual 实际回放数的显式守卫，并完成两层破坏验证。
- 下一步：无；保持分支 clean，不在本任务内集成。
- 已跑验证：基线及还原后 N14 均 7/7，稳定摘要保持 battle `3898e0822cd4fc59` / 76 ticks、reward `3f5cec5f1b4acbbb`；manual 提前一拍时 ongoing 结算被拒绝；回放计数临时从 76 少报为 75 时第 2 组按预期失败；scoped analyze 0 issue；format 0 changed；禁区 diff 为空。
- 阻塞项：无；分支为依赖 N14 tip 的堆叠交付。
