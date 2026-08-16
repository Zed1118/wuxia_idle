# Kimi 派单：Phase 0A 真实 DamageCalculator 生产适配器

## 基线与目标

- 从协调分支 `codex/phase0a-production-batch3-dispatch` 的冻结 tip 派生独立 worktree。
- 先读 `CLAUDE.md`、本派单、`docs/superpowers/plans/2026-08-16-phase0a-production-batch3-dispatch.md`、`damage_calculator.dart`、`default_ground_strategy.dart::_calculateInBattle`、第二批 phase0a reducer/session。
- 目标：实现 `Phase0aDamageResolver` 的生产适配器，真实调用 `DamageCalculator.calculateResolved`，禁止第二套公式。

## 强制契约

1. 适配器位于 `lib/features/battle/application/phase0a/`；domain reducer 保持不依赖 Flutter/旧 BattleState。
2. 以不可变、显式注入的伤害快照承载 `calculateResolved` 所需 primitive/enum 值；招式按 `Phase0aDamageKind` 显式绑定。
3. 映射固定：`!isDodged → isHit`、`isCritical`、`finalDamage → damage`。不得用 `mainDamage`，不得重算或 clamp。
4. RNG 由构造方显式注入；同 seed、同稳定目标顺序必须回放相等。control-only 零伤绑定不消费 RNG，返回 hit=true/critical=false/damage=0。
5. 缺 attacker/target/kind binding、非法负值/NaN/Infinity 快照必须 fail-fast。`attackerLifestealPct != 0` 必须在计算前拒绝，因为当前 reducer 无回血输出，禁止静默丢失。
6. proficiency、ward、weakness、output、pierce 等均只作为调用方已解析乘子透传；不得复制推导公式。`AttackResult.appliedEffects` 尚无 Phase0A 状态消费方，登记残留风险，不顺手扩状态系统。
7. 不改 UI/YAML/schema/saveVersion/GDD/PROGRESS/probe/旧 3v3；不改 `DamageCalculator` 数学；不接胜负或存档。

## 必测

- 用根测试 numbers fixture，构造一次 direct `calculateResolved` 与 adapter 调用，命中/暴击/闪避/finalDamage 精确一致。
- 同 seed 两实例、多次调用序列完全相等；不同 target 的稳定顺序可复现。
- control-only 零伤且 RNG 未推进（随后一次 calculator 调用与未插 control 的对照相等）。
- missing actor / missing binding / 非法快照 / 非零吸血分别红测并转绿。
- 从 `Phase0aCombatSession.advance` 穿透生产 adapter → reducer，事件拿到真实 resolved damage/crit/hit，不只测 adapter helper。
- 第二批 phase0a 81 项回归；相关 damage calculator 测试；probe 8 项；`flutter analyze --no-pub`；`git diff --check`。

## 交付协议

- 先建 `docs/superpowers/plans/2026-08-16-phase0a-kimi-damage-calculator-adapter.md`，再 TDD 小切片提交。
- 若发现契约无法在不丢生产语义下成立，先写证据与最小接口修订建议，不擅自扩胜负/UI/状态系统。
- 最终 tip 以 `[READY]` 或 `[BLOCKED]` 开头，worktree 干净；报告测试计数、变更范围和残留风险。
