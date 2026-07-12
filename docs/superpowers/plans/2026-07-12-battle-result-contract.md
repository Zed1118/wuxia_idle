# 战斗结算胜负契约收紧执行计划

## 目标

删除 `BattleResolutionService.resolve.isVictory` override，使掉落、惩罚和伤势只由
`finalState.result` 决定，消除胜负第二真相源。

## 分支与工作区

- 分支：`codex/battle-result-contract`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-result-contract`
- 基线：`main` 的 `62164693`

## 验收标准（CLAUDE.md §8.2）

- [x] 生产接线：BattleNotifier、主线胜/负、爬塔胜利均使用新契约。
- [x] 单一真相源：resolve 公共参数不含 `isVictory`，胜负只读 `finalState.result`。
- [x] targeted tests：battle resolution/inner demon 及主线、爬塔相关结算测试通过。
- [x] 静态检查：`flutter analyze --no-pub` 为 0 issue。
- [x] 红线说明：不改 numbers/YAML、数值公式、三系、在线/离线、反主流项或文案。
- [x] 残留风险：记录未覆盖路径；不改变 Isar transaction ownership。
- [x] 仓库卫生：仅提交相关源码、测试与计划，worktree 干净。
- [x] 就绪信号：冻结流程将以 `[READY]` 空提交作为最终 tip。

## 任务切片

1. 提交设计和恢复点。
2. RED：测试调用先删除 override，并加 API 源码守卫。
3. GREEN：删除 service 参数与生产调用参数，胜负只从 finalState 派生。
4. 跑 targeted、analyze、格式与 diff 检查。
5. 更新恢复点并以 `[READY]` tip 冻结。

## 当前恢复点

- 状态：实现与验证完成，待 `[READY]` tip 冻结。
- 最后完成：删除 `resolve.isVictory` 与 3 个 production 重复实参；结算胜负固定从
  `finalState.result` 派生；迁移全部相关测试调用并加入 API 源码守卫。RED 先观察到
  守卫明确命中旧 `bool? isVictory`，GREEN 后完整行为回归通过。
- 下一步：提交本恢复点，追加 `[READY]` tip，冻结后不再写此 worktree。
- 已跑验证：
  - `flutter pub get`；build_runner 写 114 个本地忽略输出；
  - `flutter test --no-pub <battle resolution/inner demon/post combat/mainline/tower 5 files>`：53 tests passed；
  - 覆盖胜/负/平、掉落、Boss 散功、心魔惩罚、伤势、内息恢复、周目材料与真实消费路径；
  - `flutter analyze --no-pub`：0 issue；格式与 `git diff --check` 通过；
  - `flutter test --no-pub --reporter json | jq ...`：`success: true`，232848 ms，
    无 error 或 non-success testDone 事件。
- 残留风险：未执行 Windows 实机/发布构建；没有修改 Isar writeTxn 所有权，也未继续
  抽象完整结算 context。tower flow 测试仍输出既有 leaderboardSync 的 Isar 未初始化
  防御日志，但测试全部通过，本改动未新增该日志。
- 阻塞项：无。
