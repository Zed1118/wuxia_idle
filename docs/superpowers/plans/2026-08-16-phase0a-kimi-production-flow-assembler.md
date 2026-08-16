# Phase 0A 生产 flow 装配器（Kimi 第六批执行计划）

> 派单：`docs/dispatch/packages/2026-08-16_phase0a_kimi_production_flow_assembler.md`
> 协调计划：`docs/superpowers/plans/2026-08-16-phase0a-production-batch6-dispatch.md`

## 目标

新增唯一生产装配器 `Phase0aProductionFlowAssembler`，把既有
`Phase0aBattleSnapshotFactory` → `Phase0aDamageCalculatorAdapter` →
`Phase0aCombatSession` → `Phase0aWaveBattleFlow` 一次性装配为已接好真实伤害的
`Phase0aWaveBattleFlow`，消除调用方手工接线与「配置错误延迟到首击才暴露」的缺口；
只做组合与启动期结构校验，不复制任何伤害/移动/AI/CD/真气/波次/终局规则。

## 分支 / worktree

- 分支：`feat/phase0a-kimi-production-flow-assembler`
- worktree：`.worktrees/phase0a-kimi-production-flow-assembler`
- 基线：第六批协调冻结 commit `6587c9a3`（第五批 `[READY] 7cc62093` 之上）

## 已冻结契约（自派单 + 协调计划）

1. 新文件 `lib/features/battle/application/phase0a/phase0a_production_flow_assembler.dart`，
   单一静态入口 `assemble(...)` 接收：`Phase0aArenaState initialState`、
   `List<Phase0aWave> waves`、`List<Phase0aCombatantInput> combatants`、
   `Map<Phase0aDamageKind, SkillDef?> moveBindings`、`NumbersConfig numbers`、
   显式 `Random rng`、`Phase0aPlayerInputAdapter playerAdapter`、
   `Phase0aEnemyAiAdapter enemyAiAdapter`；返回 `Phase0aWaveBattleFlow`。
2. 启动期结构校验（全部不消费 RNG，先于一切伤害组件构造）：
   - 全场 expected actor ids = `initialState.player.id` + 每一波 `enemy.id`；
     combatants 显式 actor ids 必须精确覆盖，missing/extra 均 fail-fast，
     错误信息列出稳定排序后的 id；
   - `playerAdapter.playerId == initialState.player.id`，否则 fail-fast；
   - `Phase0aDamageKind.values` 每项必须被 `moveBindings.containsKey` 显式覆盖；
     null 是合法 control-only，不当缺失。
3. 结构校验完成后才调 `Phase0aBattleSnapshotFactory.create`；其动态机制/吸血
   fail-fast 原样穿透（不包装、不延迟）；随后只创建**一个**
   `Phase0aDamageCalculatorAdapter` 并把同一个显式 RNG 实例交给它，
   换波不重置、不按波新建 RNG。
4. 首态/波次 side、首波一致性、跨波 actor id 唯一继续交给
   `Phase0aWaveBattleFlow` 既有构造期校验，装配器不复制其规则。
5. 防御性副本沿既有体例（工厂 bundle / adapter / flow 均已不可修改化），
   装配后外部 combatants/waves/moveBindings mutation 不影响 flow。
6. 禁区：UI、奖励/掉落/成长/伤势、存档、YAML/schema、旧 3v3、生产路由；
   不改 `DamageCalculator`/reducer/session/wave flow 行为；不新 RNG、不按波 seed、
   不猜 actor id/技能、不引入第二套字段/熟练度/伤害计算。

## 任务切片

1. [x] 调查：四个既有组件签名与构造期校验、batch4/5 穿透测试体例、
   源码契约测（`test/features/battle/domain/phase0a/phase0a_source_contract_test.dart`）、
   `calculateResolved` RNG 消费序（先闪避 roll 后暴击 roll，未闪避恒 2 值/次）。
2. [ ] 本计划档 commit。
3. [ ] 红测 `test/features/battle/application/phase0a/phase0a_production_flow_assembler_test.dart`
   + 源码契约第六批扩项（装配器未实现，预期编译红）commit。
4. [ ] 最小实现装配器 commit。
5. [ ] 全验证并冻结 `[READY]`。

## 验收标准（证伪点）

- **两波真实穿透 + RNG 连续**：装配入口 → factory → damage adapter → session →
  wave flow；两波共 ≥ 每波两次可产生随机判定的命中（criticalRate > 0）；
  与同 seed direct `DamageCalculator.calculateResolved` 连续调用序列逐击同值
  （damage + isCritical）；**重置反例**：用同 seed 新建 RNG 复算「第二波若被重置」
  的假设序列，断言其与实测第二波命中序列不同（证明实现若按波重置 RNG 本测必红）。
- missing actor / extra actor / player id mismatch / 缺 basic、gather、clear 任一
  binding：装配期 fail-fast，且错误后 `rng.nextDouble()` 仍等于未消费对照首值。
- null control-only 完整 binding 合法：装配成功，gather 指令经装配链路产出
  零伤害 outcomes。
- 外部 combatants/waves/moveBindings 装配后 mutation 不污染已装配 flow
  （与未污染对照 flow 事件/state 全等）。
- 非零吸血、guardianWard/guardianDefIds、vulnerabilityMult、活跃 stagger 经装配
  入口立即 fail-fast（StateError 原样穿透，不包装不延迟），RNG 未消费。
- 源码契约第六批扩项：装配器文件禁 `damage_calculator.dart`/`DamageCalculator`、
  `game_repository.dart`/`GameRepository`、`battle_state.dart` 及旧 3v3 符号、
  UI/Flutter/Flame/probe 依赖；不得出现公式数字字面量；必须引用四个既有组件符号。
- 回归：Phase0a 全套、`test/combat/damage_calculator_test.dart` 51 项、
  nested probe `combat_rules_test.dart` 8 项、`flutter analyze --no-pub`、
  `git diff --check`、禁用依赖搜索。

## 当前恢复点

- 状态：计划档已创建，红测编写中。
- 最后完成：调查收口（切片 1）。
- 下一步：红测 + 契约扩项 commit。
- 已跑验证：无（红测前）。
- 阻塞项：无。

## 残留风险（登记，不在本批扩）

- `AttackResult.appliedEffects` / `lifestealHeal` 仍无 Phase0A 消费方（沿第三批登记）。
- 动态护法/脆弱/踉跄的正确支持需 state-aware resolver，本批只穿透既有 fail-fast。
- 装配器只覆盖「构造接线 + 启动期校验」；玩家/敌方 adapter 的调优数值来源
  （生产如何取 attackRange/CD 等）仍由调用方决定，不在本批。
