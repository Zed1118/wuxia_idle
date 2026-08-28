# P2 批一 1.2：疗养横幅与战斗准入口径统一

## 目标

主菜单“需疗养”横幅只统计会被主线战斗准入拒绝的重伤角色，避免把轻伤层数或内息紊乱误报为无法出战。

## 分支与边界

- 分支：`codex/p2-b1-healing-banner-admission-20260827`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-p2-b1-healing-banner`
- 基线：`main@0d006c9f`
- 采用现有战斗准入口径 `injuryHoursRemaining > 0`，不修改玩家文案与数值规则。
- 禁止修改：`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`。

## 验收标准

1. 横幅只统计 `injuryHoursRemaining > 0` 的角色。
2. 轻伤层数、内息紊乱不会单独产生“需疗养”横幅。
3. 混合状态时计数、最长疗养时长和跳转角色都来自真正被重伤阻断的角色。
4. 生产 provider 测试完成破坏证红并复绿；相关测试、analyze、format、禁区核查通过。
5. 工作区 clean，tip 为中文 `[READY]` 或 `[BLOCKED]`。

## 任务切片

- [x] 收窄横幅统计口径。
- [x] 补单状态与混合状态回归测试。
- [x] targeted、破坏证红、analyze、format、禁区与 clean 核查。

## 当前恢复点

- 状态：READY，等待协调者后续集成。
- 最后完成：横幅只统计重伤阻断角色；轻伤、内息紊乱单状态与混合状态均有回归覆盖。
- 下一步：无；保持分支 clean，不在本任务内集成。
- 已跑验证：旧实现下新增测试按预期 2 条失败（轻伤/内息错误产生横幅、混合状态 1 人误计 3 人）；修复后该测试文件 16/16 全绿；`flutter analyze --no-pub lib test` 0 issue；format 0 changed；禁区 diff 为空。
- 阻塞项：无；不需要修改禁区文案。
