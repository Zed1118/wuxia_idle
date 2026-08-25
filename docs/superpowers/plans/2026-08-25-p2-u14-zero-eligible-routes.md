# Phase 2 U14 zero-eligible 地点路由结果合同

- 单一目标：九霄塔、轻功、守城、断魂庄、百草岭五个江湖地点在 idle 且 zero-eligible 时 CTA 统一 fail closed，active 会话的恢复 CTA 继续可用。
- 固定验收门：`0/1 → 1/1`；必须同时达到五地点生产行为 `5/5` 与显式 widget 回归 `5/5`。
- 实时基线：塔/轻功/守城生产已禁用 zero-eligible CTA，但只有轻功有显式回归；断魂庄/百草岭 idle 且 `availableCandidateCount == 0` 仍可导航。
- 预期增量：本 zero-eligible 子门 `0/1 → 1/1`；U14 六模式整体仍因塔/轻功/守城 automation runner 缺失而 `0/1 BLOCKED`。
- 成本上限：90 分钟无门变化即停止重评；主成本读数为墙钟，不跑数小时整仓全量。
- 验收证据：先 RED 四个缺失证据/行为契约，再跑五地点定向、江湖地图相邻域、`flutter analyze --no-pub lib test`、diff check、双向白名单和 clean READY。
- 非目标：六模式 automation 矩阵、runner、admission、provider、schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则、统一完成报告或 main。
