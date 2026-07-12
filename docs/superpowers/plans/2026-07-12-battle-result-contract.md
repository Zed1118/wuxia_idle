# 战斗结算胜负契约收紧执行计划

## 目标

删除 `BattleResolutionService.resolve.isVictory` override，使掉落、惩罚和伤势只由
`finalState.result` 决定，消除胜负第二真相源。

## 分支与工作区

- 分支：`codex/battle-result-contract`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-result-contract`
- 基线：`main` 的 `62164693`

## 验收标准（CLAUDE.md §8.2）

- [ ] 生产接线：BattleNotifier、主线胜/负、爬塔胜利均使用新契约。
- [ ] 单一真相源：resolve 公共参数不含 `isVictory`，胜负只读 `finalState.result`。
- [ ] targeted tests：battle resolution/inner demon 及主线、爬塔相关结算测试通过。
- [ ] 静态检查：`flutter analyze --no-pub` 为 0 issue。
- [ ] 红线说明：不改 numbers/YAML、数值公式、三系、在线/离线、反主流项或文案。
- [ ] 残留风险：记录未覆盖路径；不改变 Isar transaction ownership。
- [ ] 仓库卫生：仅提交相关源码、测试与计划，worktree 干净。
- [ ] 就绪信号：tip commit 以 `[READY]` 开头。

## 任务切片

1. 提交设计和恢复点。
2. RED：测试调用先删除 override，并加 API 源码守卫。
3. GREEN：删除 service 参数与生产调用参数，胜负只从 finalState 派生。
4. 跑 targeted、analyze、格式与 diff 检查。
5. 更新恢复点并以 `[READY]` tip 冻结。

## 当前恢复点

- 状态：进行中（完成调用路径核验与设计，尚未修改测试/生产代码）。
- 最后完成：确认 4 个 production caller，3 个显式 override 均与 finalState 一致；
  已读取 rejected registry，本任务不命中已否方向。
- 下一步：先改测试为无 override API，并运行得到预期 RED。
- 已跑验证：`flutter pub get`；build_runner 写 114 个本地忽略输出；
  基线 `flutter analyze --no-pub` 0 issue。
- 阻塞项：无。

