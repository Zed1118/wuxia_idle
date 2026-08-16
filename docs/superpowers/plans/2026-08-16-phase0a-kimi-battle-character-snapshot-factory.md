# Phase 0A BattleCharacter 生产快照工厂（Kimi 第五批执行计划）

> 派单：`docs/dispatch/packages/2026-08-16_phase0a_kimi_battle_character_snapshot_factory.md`
> 协调计划：`docs/superpowers/plans/2026-08-16-phase0a-production-batch5-dispatch.md`

## 目标

把既有 `BattleCharacter` 生产战斗快照确定性映射为 `Phase0aDamageCalculatorAdapter`
的显式入参（`Map<String, Phase0aDamageSnapshot>` + 防御性复制后的
`Map<Phase0aDamageKind, SkillDef?>`），消除测试手填快照的接线缺口；只做字段解析
与既有 `SkillProficiency` 调用，不复制伤害或熟练度公式，不创建第二套伤害计算器。

## 分支 / worktree

- 分支：`feat/phase0a-kimi-battle-character-snapshot`
- worktree：`.worktrees/phase0a-kimi-battle-character-snapshot`
- 基线：协调分支派单冻结 tip `51205486`（第四批 `[READY] d6763b06` 之上）

## 已冻结契约（自派单 + 协调计划 + 主窗口架构提示）

1. 新文件位于 `lib/features/battle/application/phase0a/`：
   - `Phase0aCombatantInput`：不可变输入值对象，显式 Phase0a `actorId` +
     `BattleCharacter`；空 actorId 构造期 fail-fast。
   - `Phase0aBattleSnapshotBundle`：不可变输出，`combatants` 与 `moveBindings`
     均为防御性不可修改副本。
   - `Phase0aBattleSnapshotFactory`：持 `NumbersConfig`，`create(...)` 产出 bundle。
2. `BattleCharacter` 经 `import '../../domain/battle_state.dart' show BattleCharacter;`
   精确收窄导入；源码契约继续按符号禁止 `BattleState` / `BattleAI` /
   `DefaultGroundStrategy`，不因同文件定义 `BattleCharacter` 而放宽旧状态运行依赖。
3. 稳定字段逐项透传（与 `DefaultGroundStrategy._calculateInBattle` 口径同值）：
   永久内力 `internalForce`、装备攻击 `totalEquipmentAttack`、修炼层
   `mainCultivationLayer`、流派、境界层阶、防御/闪避/暴击、攻击烘焙乘子
   `attackPowerMultiplier`、输出乘子 `outputMultiplier`、弱点/抗性表
   `schoolDamageTakenMult`（防御副本）、破甲 `forgingPiercePct`。
4. 熟练度只调用 `SkillProficiency.stageFor` / `combinedMult` 与
   `SkillDef.proficiency.damagePctAt`；按显式 `moveBindings` 中非空 `SkillDef.id`
   生成 per-skill map（无使用记录 = uses 0 → 阶段表首阶语义）；null binding
   仍表示 control-only，不在工厂猜技能，缺 kind 由既有 adapter fail-fast。
5. 凝甲只按 `activeBuffs` 含 `cycle_ningjia` 映射
   `numbers.cycleEvolution.traits.ningjia.critDamageTakenMult`，无词条用 1.0。
6. 构造期 fail-fast（不静默填中性值冒充支持，不冻结动态机制）：
   - `forgingLifestealPct != 0`（reducer 无回血输出）；
   - `guardianWardMult != null` 或 `guardianDefIds` 非空（护法结界随存活变化）；
   - `vulnerabilityMult != null`（脆弱窗口随蓄力/踉跄变化）；
   - `staggerTicksRemaining > 0` 或 `staggerDefenseDownOverride != null`（活跃踉跄
     减防是战中动态状态）。
7. 不改 `DamageCalculator` 数学、不改 reducer/session/wave flow 规则、不加数值
   默认值、不降低第三/四批 fail-fast 与确定性契约；不接 UI/奖励/存档/YAML/schema/
   旧 3v3/路由/生产入口。

## 任务切片

1. [x] 调查：`_calculateInBattle` 字段口径、`BattleCharacter`、`SkillProficiency`、
   第三/四批 adapter 与 wave flow 及其测试、源码契约测。
2. [x] 本计划档 commit（`4e84cba6`）。
3. [x] 红测 `test/features/battle/application/phase0a/phase0a_battle_snapshot_factory_test.dart`
   + 源码契约扩项（红证据：编译失败 + 契约 4 项文件缺失红，`50646522`）。
4. [x] 最小实现 `phase0a_battle_snapshot_factory.dart` + 契约放宽为符号级禁令
   （`2cf689aa`；const lint 收尾随最终提交）。
5. [x] 全验证并冻结 `[READY]`。

## 验收标准（证伪点）

- 字段逐项映射与 `_calculateInBattle` 口径同值；多 bound skill 熟练度逐项等于
  手动 `SkillProficiency.combinedMult(...)`；无使用记录恰为 1.0；凝甲/非凝甲
  精确；弱点 map 防御副本（外部 mutation 不污染、不可写）；破甲透传。
- 重复/空 actor id、外部 combatant 列表与 moveBindings map 构造后 mutation、
  非零吸血、guardian/vulnerability/活跃 stagger 全部构造期 fail-fast，错误信息
  指明未支持机制。
- 至少一项 工厂 → `Phase0aDamageCalculatorAdapter` → `Phase0aWaveBattleFlow` →
  session/reducer 真实穿透，与 direct `DamageCalculator.calculateResolved`
  同 seed 同值（不只测 helper）。
- 源码契约扩项：application/phase0a 禁 `BattleState`/`BattleAI`/
  `DefaultGroundStrategy` 符号与 `battle_ai.dart`/`default_ground_strategy.dart`
  导入（改符号级，允许工厂 `show BattleCharacter` 收窄导入）；工厂文件禁
  `DamageCalculator`/`GameRepository` 依赖、必须复用 `skill_proficiency.dart`。
- 回归：Phase0a 全套、damage calculator 51 项、nested probe 8 项、
  `flutter analyze --no-pub`、`git diff --check`、禁用依赖搜索。

## 当前恢复点

- 状态：**已交付，tip 冻结 `[READY]`**。
- 最后完成：工厂实装 + 16 项工厂测（含 1 项 工厂→adapter→wave flow→
  session/reducer 穿透与 direct `calculateResolved` 同 seed 对照）+ 契约 4 项扩项全绿。
- 下一步：主窗口独立复核字段同值、fail-fast 与确定性，合入协调分支。
- 已跑验证（2026-08-16 实测）：
  - `flutter test --no-pub test/features/battle/domain/phase0a test/features/battle/application/phase0a` → **136/136**（既有 120 + 工厂 16）
  - `flutter test --no-pub test/combat/damage_calculator_test.dart` → **51/51**
  - nested probe `tools/phase0minus_probe test/gameplay/combat_rules_test.dart` → **8/8**
  - `flutter analyze --no-pub` → **0 issue**；`git diff --check` → 干净
  - 禁用依赖搜索（工厂文件无 dart:ui/Flutter/Flame/probe/battle_ai/
    default_ground_strategy/damage_calculator/game_repository）→ 无命中
- 阻塞项：无；动态机制以明确 fail-fast 留给后续 state-aware resolver 切片。

## 残留风险（登记，不在本批扩）

- `AttackResult.appliedEffects` / `lifestealHeal` 仍无 Phase0A 消费方（沿第三批登记）。
- 动态护法/脆弱/踉跄的正确支持需要 state-aware resolver，本批只 fail-fast。
- 快照数值上界（如防御率 >1）仍由 adapter/配置层守，工厂不重复校验数值合法性
  （有限/非负由 adapter 既有 `_validateSnapshot` 兜底）。
