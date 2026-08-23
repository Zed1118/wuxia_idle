# P2-G2-C02：前向扇形生产等价接线

## 目标与边界

- 分支：`codex/phase2-g2-c02-forward-fan-20260823`。
- 让 Phase 0A 单目标普攻/技能/敌方技能的既有选择路径，经
  `isTargetInsideStrikeArc` 消费 C02 `ForwardFanScope`。
- 保持单目标选择、距离优先/id 决胜、guardian 过滤、闭区间边界，以及
  零朝向默认向右的既有兼容语义。
- 不接多目标、其余五种 scope、数据/调优配置、存档或 UI。

## 验收清单

1. 真实 reducer 的 `_selectStrikeTarget` 继续经 `isTargetInsideStrikeArc`
   到达 `ForwardFanScope`，不是仅 fixture 或孤立 adapter。
2. 相关测试覆盖距离/扇角边界、零朝向、非法参数 fail closed、最近/id
   决胜、guardian 过滤和每次单目标结算。
3. 不触及数值硬红线、三系锁死、在线/离线一致性、反主流清单；无新增
   Dart 调优常量或中文文案。
4. 跑 targeted test、限定路径 analyze 与 `git diff --check`；残留风险只
   是尚未接入多目标及其余五种 C02 scope，按本切片边界留给后续任务。

## 当前恢复点

- 状态：已完成，等待主调度按 READY tip 审核/合并。
- 最后完成：旧扇区规则改为最薄兼容 adapter；零向量映射默认向右，其他
  非法输入由 `ForwardFanScope` fail closed；新增 guardian 单目标回归测试。
- 下一步：主调度在集成态复核 diff，并在批次合并后执行联合验证。
- 已跑验证：修改前新增负距离重合目标测试红；修复后
  `flutter test --no-pub` 五个 geometry/rules/reducer/skill/guardian 定向文件
  `64/64` 通过；限定六路径 `flutter analyze --no-pub` 为零问题；
  `git diff --check` 通过。
- 阻塞：无。
