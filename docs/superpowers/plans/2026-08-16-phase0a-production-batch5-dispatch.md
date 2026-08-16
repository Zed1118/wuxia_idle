# Phase 0A 根应用生产化第五批协调计划

## 目标

把既有 `BattleCharacter` 生产战斗快照确定性映射为 `Phase0aDamageCalculatorAdapter` 的显式入参，消除测试手填 `Phase0aDamageSnapshot` 的接线缺口；只做字段解析与既有 `SkillProficiency` 调用，不复制伤害或熟练度公式。

## 已冻结边界

- 输入必须显式携带 Phase0a `actorId` 与对应 `BattleCharacter`，不得用旧 `characterId` 自行猜测字符串 id；重复 actor id 构造期 fail-fast。
- 稳定字段逐项透传：永久内力、装备攻击、修炼层、流派、境界层阶、防御/闪避/暴击、攻击烘焙乘子、输出乘子、弱点/抗性表、破甲。
- 熟练度只调用 `SkillProficiency.stageFor` / `combinedMult` 与 `SkillDef.proficiency.damagePctAt`；按显式 `moveBindings` 中的非空 `SkillDef.id` 生成 per-skill map，不复制公式。
- `cycle_ningjia` 只按既有 `numbers.cycleEvolution.traits.ningjia.critDamageTakenMult` 映射；无词条用中性乘子。
- 当前 Phase0a reducer 无回血输出，任一 `forgingLifestealPct != 0` 必须在工厂构造期 fail-fast，不能等首次命中才报错。
- 静态 adapter 无法正确跟随护法死亡、Boss 脆弱窗口或踉跄减防变化：`guardianWardMult` / `guardianDefIds` / `vulnerabilityMult` / 活跃 stagger 状态命中时构造期 fail-fast；不得把动态机制冻结成错误常量。
- `moveBindings` 必须显式注入且做防御性不可修改副本；缺 kind 仍由既有 adapter fail-fast，null 仍表示 control-only，不在工厂猜技能。
- 不改 `DamageCalculator` 数学，不改 reducer/session/wave flow 规则，不接 UI、奖励、存档、YAML/schema、旧 3v3 或生产路由。

## 验收

1. 与 `DefaultGroundStrategy._calculateInBattle` 的稳定字段口径逐项同值；熟练度、凝甲、弱点/抗性、破甲精确可测。
2. 外部 combatant/binding/map 构造后 mutation 不影响结果；重复 id、非有限/负值继续由工厂或 adapter 明确拒绝。
3. 吸血、护法结界、脆弱窗口、活跃踉跄均在构造期 fail-fast，错误信息指明未支持机制。
4. 至少一项从工厂 → `Phase0aDamageCalculatorAdapter` → `Phase0aWaveBattleFlow` → session/reducer 的真实链路与 direct `calculateResolved` 同 seed 同值。
5. Phase0a 全套、damage calculator 回归、probe 8 项、根 analyze 与 diff-check 全绿。

## 切片

1. [x] 主窗口审计 `BattleCharacter` 与旧 `_calculateInBattle` 字段口径，冻结动态机制不能静态化的边界。
2. [x] Kimi 独立 worktree：计划 → 红测 → 最小工厂 → 真实 flow 穿透 → `[READY] c133e0e6`。
3. [x] 主窗口独立复核字段同值、fail-fast 与确定性。
4. [x] 合入协调分支，复验并冻结 `[READY]`。

## 当前恢复点

- 状态：**第五批已完成并合入协调分支，待本文件恢复点提交后冻结 `[READY]`**。
- 最后完成：合入 Kimi `[READY] c133e0e6`；新增 `BattleCharacter` 生产快照工厂、16 项工厂测试与真实 wave flow 同 seed 穿透。
- 下一步：提交本恢复点并创建空 `[READY]` tip。
- 已跑验证：Kimi 与主窗口独立两轮均通过 Phase0a 136/136、damage calculator 51/51、nested probe 8/8、`flutter analyze --no-pub` 0 issue、diff-check 干净。
- 阻塞项：无；动态机制以明确 fail-fast 留给后续 state-aware resolver 切片。
