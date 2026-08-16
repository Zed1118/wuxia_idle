# Kimi 派单：Phase 0A 生产 flow 装配器（第六批）

## 基线与交付

- 基线：第六批协调冻结 commit（第五批 `[READY] 7cc62093` 之上）。
- 独立分支：`feat/phase0a-kimi-production-flow-assembler`。
- 先创建执行计划档并 commit；随后红测 commit、最小实现 commit、全验证，最终空 commit 标记 `[READY]` 或 `[BLOCKED]`。
- worktree 必须干净；不 push、不 merge、不改主工作区。

## 任务

在 `lib/features/battle/application/phase0a/` 新增命名清晰的生产装配器，单一入口接收：

- `Phase0aArenaState initialState`
- `List<Phase0aWave> waves`
- `List<Phase0aCombatantInput> combatants`
- `Map<Phase0aDamageKind, SkillDef?> moveBindings`
- `NumbersConfig numbers`
- 显式 `Random rng`
- `Phase0aPlayerInputAdapter playerAdapter`
- `Phase0aEnemyAiAdapter enemyAiAdapter`

入口返回已接好真实伤害的 `Phase0aWaveBattleFlow`。只允许调用既有：

1. `Phase0aBattleSnapshotFactory`
2. `Phase0aDamageCalculatorAdapter`
3. `Phase0aCombatSession`
4. `Phase0aWaveBattleFlow`

不得复制其中任何公式、规则或状态机。

## 构造期契约

- 全场 expected actor ids = `initialState.player.id` + 每一波 `enemy.id`；combatants 的显式 actor ids 必须精确覆盖，missing/extra 均 fail-fast，错误 id 稳定排序。
- `playerAdapter.playerId == initialState.player.id`，否则 fail-fast。
- `Phase0aDamageKind.values` 每项必须被 `moveBindings.containsKey` 显式覆盖；null 是合法 control-only，不得当缺失。
- 先完成不消费 RNG 的结构校验；结构错误不得推进 RNG。第五批工厂自身的动态机制/吸血 fail-fast 必须原样穿透。
- 首态/波次 side、首波一致性和跨波 id 唯一交给 `Phase0aWaveBattleFlow` 既有校验，不复制。
- 装配后外部 list/map mutation 不影响 flow；只创建一个 damage adapter，并把同一个显式 RNG 实例交给它，换波不得重置。

## 必测证伪点

- 两波真实穿透，至少两次可产生随机判定的命中：与 direct `DamageCalculator.calculateResolved` 使用同 seed 的连续调用逐击同值；第二波若错误重置 RNG，测试必须能红。
- missing actor、extra actor、player id mismatch、缺 basic/gather/clear 任一 binding：装配期 fail-fast 且 RNG 下一值仍等于未消费对照。
- null control-only 完整 binding 合法。
- combatants/waves/moveBindings 外部 mutation 不污染已装配 flow。
- 非零吸血或动态 guardian/vulnerability/stagger 经装配入口立即 fail-fast，不延迟到首击。
- 源码契约：装配器禁 `DamageCalculator` / `BattleState` / `BattleAI` / `DefaultGroundStrategy` / `GameRepository`，不得出现公式数字或 UI/Flutter/Flame/probe 依赖。

## 禁区

- UI、奖励/掉落/成长/伤势、存档、YAML/schema、旧 3v3、生产路由。
- 修改 `DamageCalculator`、reducer、session、wave flow 行为。
- 新 RNG、按波 seed、猜 actor id/技能、第二套字段/熟练度/伤害计算。

## 验证

- 新装配器测试与源码契约红→绿。
- Phase0a 全套。
- `test/combat/damage_calculator_test.dart` 51 项。
- `tools/phase0minus_probe/test/gameplay/combat_rules_test.dart` 8 项。
- `flutter analyze --no-pub`、`git diff --check`、禁用依赖搜索。
