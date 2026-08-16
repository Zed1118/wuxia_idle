# Phase 0A 生产 DamageCalculator 适配器（Kimi 第三批执行计划）

> 派单：`docs/dispatch/packages/2026-08-16_phase0a_kimi_damage_calculator_adapter.md`
> 协调计划：`docs/superpowers/plans/2026-08-16-phase0a-production-batch3-dispatch.md`

## 目标

实现 `Phase0aDamageResolver` 的生产适配器 `Phase0aDamageCalculatorAdapter`，真实调用
`DamageCalculator.calculateResolved`（公式单一真相源），禁止第二套公式。

## 分支 / worktree

- 分支：`feat/phase0a-kimi-damage-calculator-adapter`
- worktree：`.worktrees/phase0a-kimi-damage-calculator-adapter`
- 基线：协调分支 `codex/phase0a-production-batch3-dispatch` 冻结 tip `69bfcea4`（第二批 `[READY] 36b6aaff` 之上）

## 已冻结契约（自派单 + 协调计划）

1. adapter 位于 `lib/features/battle/application/phase0a/`；domain reducer 不依赖 Flutter/旧 `BattleState`。
2. 不可变显式注入伤害快照（`Phase0aDamageSnapshot`）承载 `calculateResolved` 所需 primitive/enum；招式按 `Phase0aDamageKind` 显式绑定（`Map<Phase0aDamageKind, SkillDef?>`，value null = control-only 零伤绑定）。
3. 映射固定：`isHit = !isDodged`、`isCritical` 原样、`damage = finalDamage`。不用 `mainDamage`，不重算、不 clamp。
4. RNG 构造显式注入（`Random`，测试用 seed）；同 seed + 同稳定目标顺序回放相等；control-only 绑定不消费 RNG，返回 hit=true / critical=false / damage=0。
5. 缺 attacker/target 快照、缺 kind 绑定、负值/NaN/Infinity 快照、`attackerLifestealPct != 0` 一律在计算前 fail-fast（禁止静默丢回血效果，当前 reducer 无回血输出）。
6. proficiency/ward/weakness/output/pierce 只作调用方已解析乘子透传；weakness 沿 `weaknessMultOf` 体例做守方 `schoolDamageTakenMults[attacker.school] ?? 1.0` 纯查表。`AttackResult.appliedEffects` 无 Phase0A 消费方，登记残留风险，不扩状态系统。
7. 不改 UI/YAML/schema/saveVersion/GDD/PROGRESS/probe/旧 3v3；不改 `DamageCalculator` 数学；不接胜负/存档。

## 任务切片

1. [x] 调查：`damage_calculator.dart`、`default_ground_strategy.dart::_calculateInBattle`、第二批 reducer/session、根 numbers fixture（`test/support/test_data.dart::loadTestGameRepository`）。
2. [ ] 本计划档 commit。
3. [ ] 红测 `test/features/battle/application/phase0a/phase0a_damage_calculator_adapter_test.dart`（先红后绿）。
4. [ ] 最小实现 `lib/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart`。
5. [ ] 全验证并冻结 `[READY]`。

## 验收标准（证伪点）

- 真实 numbers fixture 下 direct `calculateResolved` 与 adapter 调用：命中/暴击/闪避/finalDamage 精确一致。
- 同 seed 两实例、多次调用序列完全相等；不同 target 稳定顺序可复现。
- control-only 零伤且 RNG 未推进（随后一次调用与未插 control 的对照相等）。
- missing actor / missing binding / 负值·NaN·Infinity 快照 / 非零吸血分别红测转绿。
- `Phase0aCombatSession.advance` 穿透生产 adapter → reducer，事件拿到真实 resolved damage/crit/hit/闪避。
- 回归：第二批 phase0a 81 项、`test/combat/damage_calculator_test.dart`、nested probe `combat_rules_test.dart` 8 项、`flutter analyze --no-pub`、`git diff --check`。

## 当前恢复点

- 状态：计划档已建，即将写红测。
- 最后完成：契约调查完成；基线 phase0a 81/81 全绿（实测 2026-08-16）。
- 下一步：写 adapter 红测。
- 已跑验证：`flutter test --no-pub test/features/battle/domain/phase0a test/features/battle/application/phase0a` → 81/81 pass。
- 阻塞项：无。

## 残留风险（交付时更新）

- `AttackResult.appliedEffects`（extra_effect 打标 / armor_pierce）在 Phase0A 无消费方，本片登记不扩状态系统。
- `lifestealHeal` 同理：本片以「非零吸血 fail-fast」替代静默丢弃；未来 reducer 加回血输出后可放开。
