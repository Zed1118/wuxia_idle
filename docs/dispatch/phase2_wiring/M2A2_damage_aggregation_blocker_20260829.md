# M2A2 聚合伤害阻塞记录（2026-08-29）

## 结论

`[BLOCKED]`。当前生产架构只能可靠区分普通敌人、精英、Boss 与玩家的即时伤害，不能识别方案 §16.4 要求短窗口聚合的毒/内伤伤害。继续只做可达部分会缩小既定范围；自行补齐状态伤害生产链会引入尚未冻结的技能语义与伤害规则。两条路线分别触发作业宪法 §2.8 与 §10，故在写实现前停止。

## 本会话实测

- 基线：`a500248c4e58f055b6acf462d4eadf9693538df5`
- 分支：`codex/p2-m2-damage-aggregation-20260829`
- `Phase0aVfxController.consume` 只从 `Phase0aHitLanded`、`Phase0aGatherApplied`、`Phase0aClearApplied`、`Phase0aSkillApplied` 生成伤害飘字；这些事件均没有伤害来源类型字段。
- `TimedStatusType` 包含 `internalInjury` 与 `poison`，`StatusDamage` 也携带类型；但 `rg -n "TimedStatusLedger|StatusDamage|TimedStatusType" lib test` 的生产命中全部局限在 `lib/features/battle/domain/phase0a/status_effects.dart`，其余命中仅为该文件的单测，没有 reducer、flow、adapter、controller 或 screen 消费点。
- 反向复搜 `rg -n "status_effects|internalInjury|poison" lib/data lib/features` 仍未找到状态伤害进入生产战斗事件链的路径。
- 现有真实 BattleScreen 测试仍断言 R 的每个非零 outcome 各显示一个精确数字；聚合显示将改变该玩家可见契约，而 gate 又禁止删改原断言来求绿。

## 已冻结、可直接实现的部分

- 同一次攻击对普通敌人的伤害在显示居民层合并为“总伤害 + 命中目标数”。
- Boss、精英保留独立数字。
- 玩家受伤在 6–8 组居民上限内拥有最高保留优先级。
- 原始结算事件、逐目标命中/格挡/破势语义保持不变。

## 待用户拍板（推荐方案在前）

1. **推荐：批准两段式范围。** 先完成所有当前生产可达的聚合规则并保留真实逐目标事件；把毒/内伤短窗口聚合作为“状态伤害生产接线”前置完成后的同一 M2A2 后续，不把本批局部完成冒充整项通过。
2. **扩大本单。** 先冻结毒/内伤的生产技能来源、目标、tick cadence、事件 payload 与内容映射，再由本单一并接通状态伤害和聚合表现。

未获拍板前不修改 `lib/`、测试、数值、schema 或 gate。
