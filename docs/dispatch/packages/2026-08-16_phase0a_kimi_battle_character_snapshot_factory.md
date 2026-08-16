# Kimi 派单：Phase 0A BattleCharacter 生产快照工厂

基线：第五批协调分支派单 commit。先完整读 `CLAUDE.md`、第五批协调计划、第三批 damage adapter 计划/源码/测试、第四批 wave flow，以及 `battle_state.dart`、`default_ground_strategy.dart::_calculateInBattle`、`skill_proficiency.dart`。

## 交付

- 在 `lib/features/battle/application/phase0a/` 新增小型不可变输入值对象与生产快照工厂（命名自行按现有风格确定），把显式 Phase0a actor id + `BattleCharacter` 集合映射为：
  - `Map<String, Phase0aDamageSnapshot>`；
  - 防御性复制后的 `Map<Phase0aDamageKind, SkillDef?>`。
- 允许返回一个不可变 bundle，但不得创建第二套伤害计算器；消费方仍必须实例化/使用既有 `Phase0aDamageCalculatorAdapter`。
- 熟练度必须复用 `SkillProficiency`；稳定字段、凝甲、弱点/抗性、破甲按协调计划逐项映射。
- 吸血与动态护法/脆弱/踉跄机制按协调计划构造期 fail-fast，不能静默填中性值冒充支持。

## 必测

- 先计划 commit，再红测 commit，再实现/加固小切片 commit。
- 字段逐项映射；多个 bound skill 的熟练度；无使用记录的 1.0 语义；凝甲与非凝甲；弱点 map 防御副本；破甲透传。
- 重复/空 actor id、外部 list/map mutation、非零吸血、guardian/vulnerability/stagger fail-fast。
- 至少一项工厂 → production damage adapter → wave flow → session/reducer 穿透，并与 direct `DamageCalculator.calculateResolved` 同 seed 对照；不得只测 helper。
- 扩源码契约，禁止工厂复制 `DamageCalculator` 数学或导入 `DefaultGroundStrategy`/旧 `BattleState` 作为运行依赖。

## 禁区

- 不改 YAML/schema/saveVersion/GDD/PROGRESS/probe/路由/UI/奖励/存档/旧 3v3。
- 不改 `DamageCalculator.calculateResolved` 数学，不给参数加数值默认值，不降低第三/四批 fail-fast 与确定性契约。
- 动态机制需要 state-aware resolver 才能正确支持；本批只 fail-fast 并在恢复点登记，不顺手扩 reducer。

最终跑 Phase0a 全套、damage calculator 51 项、nested probe 8 项、`flutter analyze --no-pub`、禁用依赖搜索与 `git diff --check`；worktree 干净，tip 标 `[READY]` 或 `[BLOCKED]`。
