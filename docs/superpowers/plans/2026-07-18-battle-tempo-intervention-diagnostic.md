# 战斗节奏与手动干预价值诊断计划

> 上游稳定点：`codex/battle-mode-ui-distinction@48963eea`
> 分支：`codex/battle-tempo-diagnostics`
> worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-tempo-diagnostics`

## 1. 目标

不凭观感直接改战斗公式。用真实配置和生产战斗策略量化三人出手占比、技能占比、真气满溢/不足、可干预率、敌方蓄力时破招覆盖与破绽时爆发覆盖；对同 seed 配对比较纯自动与「仅在破招/破绽窗口插队」策略的胜率、耗时和手动出手数。

## 2. 诊断口径

- 样本：前期主线、中期 Boss、终章 Boss × `standard/nearMax` × 固定 seed。
- 生产同源：`GameRepository` 真 YAML、`buildProgressionPlayer`、`StageBattleSetup.buildEnemyTeam`、`defaultGroundStrategy.stepOne/interveneNow`。
- 一次出手按连续同 tick/actor/skill action 分组，AOE 多目标不重复计数。
- 手动策略每 tick 最多插队一次：先破招，后在敌方破绽期选可用高倍率招；不做无窗口连点。
- 本切片只产出诊断工具与审计报告，不改生产数值/规则。

## 3. 验收标准（CLAUDE.md §8.2）

- [x] **生产接线证据**：探针不用手写战斗 fixture，直接经真实 repository/stage/setup/strategy 链路跑完整战斗。
- [x] **targeted test**：同参数结果确定；出手分组与计数自洽；至少一个样本产生技能出手和可干预拍。
- [x] **红线影响**：只读诊断，不改 damage/tick/AI/真气/冷却/胜负/numbers/schema/saveVersion；不引入在线手动增益。
- [x] **证据报告**：输出分关/profile 表与总结，明确区分已证实问题、证伪问题、局限和下一切片建议。
- [x] **UI/UX**：本切片无 UI 改动，不重复双视口验收；上游 `48963eea` 已通过双模式双视口。
- [x] **残留风险**：记录单流派配装、固定干预策略、RNG 消费序列分叉与不等同真人操作的局限。
- [x] **清洁度**：仅提交诊断源码、必要输出与报告，无临时日志/二进制/capture；冻结 `[READY]`。

## 4. 当前恢复点

- **状态**：诊断完成，待最终 analyze、提交并冻结。
- **最后完成**：3 关 × 2 profile × 12 seed × 2 策略共 144 局配对诊断通过；报告确认 Boss 窗口干预降低约 22%～37% 耗时，并定位 AP 归零后仍可重复借行动的规则缺口。
- **下一步**：运行 analyze，提交 `[READY]`；另开生产切片修复同角色连发门控。
- **已跑验证**：targeted diagnostic 1/1 通过；同参数签名确定；出手分组自洽；输出 CSV/Markdown 已生成。
- **阻塞项**：无。
