# 三条 PARKED 战斗合同生产接线差异（2026-08-26）

状态：`READY for coordinator review`；基线 `69563238`。只分析 POSTURE / TIMELINE / QI，不含已接线的 ATTACK-TOKEN，不改玩法或配置。
冻结事实见 `docs/dispatch/phase0a_overhaul/decision_registry.yaml:360-378,396-406`；候选参数顺序见 `docs/spec/phase2_combat_core_tuning_candidates_20260826.md:11-21,34-44,81-92`。
直接消费者复核：以“Config/State/转换函数”“Phase/Event/Timeline”“Ledger/Reservation/Gain”三组名交叉 `rg -l -g '*.dart' ... lib`，三组均只命中各自定义文件，即生产消费者 `0`。
测试冲击数字均为 `rg --count-matches -g '*_test.dart' <该节所列语义正则> <roots>` 的耦合命中数，不伪装成尚未实现 RED 时的精确失败测试数。

## POSTURE

### 1. 生产现状

- 状态：`Phase0aActor` 保存 `chargeCast/chargingCast/chargeTicksRemaining`、`staggerTicksTotal/staggerTicksRemaining` 与内容事实 `vulnerabilityMult`（`lib/features/battle/domain/phase0a/phase0a_combat_model.dart:193-203,219-242`）；伤害快照另存 `vulnerabilityOutMult`（`lib/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart:86`）。
- 写方：`Phase0aStageContentMapper` 从 `numbers.combat.bossCharge` 与敌方快照装配蓄力/踉跄（`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:656-703`）；reducer 每拍递减并压制行动（`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:154-175`），命中蓄力目标后 `_maybeApplyChargeBreak` 立即清蓄力、写技能 CD 与踉跄（`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:1340-1381`）。
- 读方/感知：reducer 把 `defenderStaggered/defenderCharging` 交给伤害 adapter（`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:595-603,1115-1123`），adapter 在窗内解除窗口外减伤并对踉跄减防（`lib/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart:197-213`）；敌 AI 停手（`lib/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart:41-46`）、bot 优先爆发窗（`lib/features/battle/application/phase0a/phase0a_player_bot_adapter.dart:151-163`），玩家看到蓄力、脆弱、踉跄倒计时标签（`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:1096-1155`）。

### 2. 合同语义

- **重合**：`PostureState.isVulnerable`/`vulnerabilityTicksRemaining`（`lib/features/battle/domain/phase0a/posture.dart:110-127`）与现有“蓄力或踉跄即脆弱”同属窗口事实；`advance` 与 reducer 的逐拍递减同拍制；`bossControlToPostureDamage` 可承接 typed `breakPower`。
- **合同新增**：容量/累计值、满值开窗、溢出事件、窗内姿态伤害抑制、命中分类/poise 轻击事件、结束后 `reset/recover` 至冻结累计 4，以及 Boss 控制强度 ×3（`lib/features/battle/domain/phase0a/posture.dart:129-183,186-222,236-243`）；生产今天没有姿态槽。
- **生产独有**：仅命中“正在蓄力”的目标才立刻破招；清招牌技、技能 CD、行动压制、踉跄减防、守卫截招、per-enemy 窗外承伤倍率及现有 UI/VFX，合同均不负责（`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:930-999,1340-1381`）。

### 3. 接线的最小定义

- `lib/data/numbers_config.dart`：给 `CombatNumbers` 增加严格解析的 posture 配置；`lib/features/battle/domain/phase0a/phase0a_combat_model.dart`：把姿态运行态纳入不可变 actor/state。
- `lib/features/battle/domain/phase0a/phase0a_combat_intent.dart`：显式携带每次命中的 posture damage/hit kind；`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart`：初始化适用敌人的 `PostureState` 并注入配置。
- `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart`：每拍 `advance(1)`，命中 `apply`，将开/关窗事件合并到现有 charge/stagger 状态机；`lib/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart`：读取统一窗口事实。
- `lib/features/battle/domain/phase0a/phase0a_combat_events.dart`、`lib/features/battle/presentation/phase0a/phase0a_vfx_controller.dart`、`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart`：投影姿态变化并复用现有文字标签，不新增被否的预兆图标/百科入口。

### 4. 配置落点

```yaml
combat:
  posture: {capacity: 14, vulnerability_ticks: 4, recovery_policy: recover,
    post_vulnerability_accumulated: 4, boss_conversion_factor: 3}
```
落在 `data/numbers.yaml` 现有 `combat` 强类型域；旧 `combat.boss_charge.default_stagger_ticks` 只保留“破招后跳过行动”职责，禁止与 `vulnerability_ticks` 双写同一窗口。

### 5. 行为变化面

- 主线：适用 Boss 从“蓄力时一下破招”增加可累计 14 的循环窗；塔：机制 Boss 的窗外减伤更常被 4 拍姿态窗解除；轻功/守城：仅其敌人被明确标为姿态适用者时变化；断魂庄：三 Boss 连战的姿态累计须每关重建；远征：战斗节点同核改变胜负/余血；扫荡：bot 会读新窗口并改变放招时机；离线：百草岭按 elapsed 结算时仍走同一 headless reducer（`lib/features/expedition/application/expedition_service.dart:442-505`），普通被动挂机不跑该核、无变化。

### 6. 现有测试冲击面

- 正则 `staggerTicks(Remaining|Total)|Phase0aBossChargeInterrupted|defenderStaggered|defenderCharging|vulnerability(Mult|OutMult)|breakPower`：全 test 为 `39 files / 240 hits`；最高耦合为 `test/features/battle/domain/phase0a/phase0a_charge_interrupt_test.dart` 38、`test/features/battle/domain/phase0a/phase0a_guard_intercept_test.dart` 24、`test/features/battle/application/phase0a/phase0a_vulnerability_window_test.dart` 40、`test/features/battle/application/phase0a/phase0a_charge_production_wiring_test.dart` 18、`test/features/battle/application/phase0a/phase0a_vulnerability_production_wiring_test.dart` 15。

### 7. 风险与不确定点

- 候选模拟把普攻=1、技能=`power/basicPower`、破招再加转换值（`test/tuning/phase2_combat_core_tuning_candidates_test.dart:451-475`），但冻结登记只冻结五个参数；生产 posture damage 的权威来源/适用敌人范围仍须在 RED 中先钉死。
- 必须拍板“蓄力命中仍立即破招，姿态槽另开窗”还是“所有破招先累计到 14”；前者保留玩法但有双窗口，后者会改现有破招规则。无论哪种都不触 §5.3/§5.4/§5.5；必须跑现有伤害不进百万与 live/headless 同核守卫。

## TIMELINE

### 1. 生产现状

- 状态：actor 只有秒制 `attackCooldownRemaining`、敌技 `enemySkillCooldowns` 与 Boss charge 倒计时（`lib/features/battle/domain/phase0a/phase0a_combat_model.dart:179-203,231-242`）；技能槽只有 `cooldownRemaining/qiCost/availability`（`lib/features/battle/domain/phase0a/phase0a_combat_model.dart:452-470`），没有玩家 action phase。
- 写方：input adapter 把一个按键直接变成带 `cooldownSeconds` 的 intent（`lib/features/battle/application/phase0a/phase0a_player_input_adapter.dart:138-198`）；reducer 同拍发 `Started`、选目标、结算效果并写 CD（`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:469-624,1041-1217`），每拍仅做 CD 扣减（`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:97-134,178-209`）。
- 读方/感知：VFX controller 消费即时事件产生表现（`lib/features/battle/presentation/phase0a/phase0a_vfx_controller.dart:127-240`），技能印显示冷却/可用（`lib/features/battle/presentation/phase0a/phase0a_skill_seals.dart:167-185`）；玩家当前没有前摇、active、收招、取消窗或失败/被断冷却差异，唯一可见多拍动作是 Boss 蓄力标签。

### 2. 合同语义

- **重合**：固定 tick 推进、started/completed 事件和终态 cooldown marker（`lib/features/battle/domain/phase0a/action_timeline.dart:89-163`）可替代当前“同拍效果 + 秒制动作锁”的一部分。
- **合同新增**：五阶段 `windup/active/recovery`、指定 `firstEffectTick`、取消窗口、cancel/interrupted/failed 三种 CD（`lib/features/battle/domain/phase0a/action_timeline.dart:3-72,142-200`），冻结值由武器分型。
- **生产独有**：空间选靶、多目标/多段效果、actor/action ID、技能独立 CD、输入合并、Boss charge、波间重置、不可变回放状态与表现事件；合同是可变一次性对象，终态后不能 restart，且只记录 CD 不负责递减。

### 3. 接线的最小定义

- `data/equipment.yaml`、`lib/data/defs/equipment_def.dart`：给所有武器补强类型 `weaponType`；`lib/shared/battle_shared/combatant_snapshot.dart`、`lib/shared/battle_shared/player_combatant_snapshot_assembler.dart`：把类型带入战斗快照（今天快照字段表 `lib/shared/battle_shared/combatant_snapshot.dart:79-109` 无此身份）。
- `lib/data/numbers_config.dart`、`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart`：解析五 profile 并按 snapshot 选 timeline；`lib/features/battle/domain/phase0a/phase0a_combat_model.dart`：保存可回放 action timeline snapshot，而非直接塞可变 `ActionTimeline`。
- `lib/features/battle/domain/phase0a/phase0a_combat_intent.dart`、`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart`：按 action ID 起动/取消/打断，且只在 `firstEffect` 触发既有唯一伤害/效果路径；`lib/features/battle/domain/phase0a/phase0a_combat_events.dart`、`lib/features/battle/presentation/phase0a/phase0a_vfx_controller.dart`、`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart`：映射 phase/终态，不复制结算。

### 4. 配置落点

```yaml
phase0a_arena:
  weapon_timelines:
    sword: {windup: 1, active: 2, recovery: 3, first_effect: 1, cancel_start: 1, cancel_end: 4, interrupted_cd: 3, cancelled_cd: 2, failed_cd: 4}
    heavy: {windup: 2, active: 3, recovery: 3, first_effect: 2, cancel_start: 2, cancel_end: 5, interrupted_cd: 4, cancelled_cd: 3, failed_cd: 5}
    flexible: {windup: 1, active: 4, recovery: 2, first_effect: 1, cancel_start: 1, cancel_end: 4, interrupted_cd: 3, cancelled_cd: 2, failed_cd: 4}
    dual: {windup: 0, active: 4, recovery: 2, first_effect: 0, cancel_start: 0, cancel_end: 4, interrupted_cd: 2, cancelled_cd: 1, failed_cd: 3}
    hidden: {windup: 0, active: 2, recovery: 3, first_effect: 0, cancel_start: 0, cancel_end: 3, interrupted_cd: 2, cancelled_cd: 1, failed_cd: 3}
```
`data/equipment.yaml` 每个 weapon 条目另加 `weaponType: sword|heavy|flexible|dual|hidden`；不能从三流派 `schoolBias` 推出五分类。

### 5. 行为变化面

- 主线/塔/轻功/守城/断魂庄 live：普攻不再同拍必出效果，五武器各有前摇/收招/取消与被断窗口；远征/扫荡/headless 断魂庄：同 tick 时序会改变 DPS、超时与胜负；离线百草岭同样改变节点结算，普通被动挂机不变。所有面必须经共享 session→reducer（`lib/features/battle/application/phase0a/phase0a_combat_session.dart:207-214`），不得只改 screen 动画。

### 6. 现有测试冲击面

- 正则 `attackCooldownRemaining|cooldownRemaining|Phase0aAttackStarted|Phase0a(Skill|Gather|Clear)Started|Phase0a(Skill|Gather|Clear)Applied|cooldownSeconds`：`battle/mainline/tower/boss_gauntlet/expedition/sweep` 六域 `62 files / 377 hits`；关键为 `test/features/battle/domain/phase0a/phase0a_reducer_test.dart` 59、`test/features/battle/domain/phase0a/phase0a_numeric_skill_reducer_test.dart` 14、`test/features/battle/application/phase0a/phase0a_wave_flow_test.dart` 14、`test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart` 15、`test/features/battle/application/phase0a/phase0a_headless_kernel_test.dart` 7。

### 7. 风险与不确定点

- `WeaponType` 目前除定义外零生产消费者（`lib/features/battle/domain/phase0a/basic_attack_chain.dart:1-5,59-80`），而生产快照不保留装备 ID/类型；五类装备归属是必需数据决策，禁止按名称猜。
- 候选模拟将 timeline 当连续通用动作流（`test/tuning/phase2_combat_core_tuning_candidates_test.dart:563-633`），未冻结“仅普攻”还是“Q/R/数字技也用武器 timeline”；最小、低冲突 RED 应先锁“仅玩家普攻”，技能仍守自身 CD。该分类不改变装备/心法阶门，故不触 §5.3。

## QI

### 1. 生产现状

- 状态：`Phase0aActor.qiCurrent/qiMax`（`lib/features/battle/domain/phase0a/phase0a_combat_model.dart:138-177`）与槽的 `qiCost/availability`（`lib/features/battle/domain/phase0a/phase0a_combat_model.dart:452-470`）；来源是 `CombatantSnapshot.currentQi/maxQi`，mapper 原值装配（`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:98-129`）。
- 写方：普攻直接 `qiCurrent + qiDelta`（`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:620-624`）；技能 `_tryCastSkill` 同拍验气、扣气、上 CD（`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:1724-1750`）；波间另恢复百分比（`lib/features/battle/application/phase0a/phase0a_wave_battle_flow.dart:203-229`）。没有 reserve/commit/cancel 或击杀回气。
- 读方/感知：`availabilityOf` 生成 `qi` 禁用态（`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:1534-1542`），bot 只选 ready 槽（`lib/features/battle/application/phase0a/phase0a_player_bot_adapter.dart:190-203`），HUD/技能印显示当前/上限与缺气（`lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart:1337-1345`、`lib/features/battle/presentation/phase0a/phase0a_skill_seals.dart:170-182`）。

### 2. 合同语义

- **重合**：有界 current/capacity、余额不足拒绝、gain 溢出（`lib/features/battle/domain/phase0a/qi_resource.dart:48-87,164-171`）与现有 clamp/availability 同义。
- **合同新增**：action ID 幂等；先 reserve、首效才 commit、首效前 cancel 释放；每 wave 击杀收益上限（`lib/features/battle/domain/phase0a/qi_resource.dart:89-162`）。
- **生产独有**：心法派生 max/opening、内息紊乱、gain/cost 修正（`lib/shared/battle_shared/player_combatant_snapshot_builder.dart:73-99`），221 条 `skills.yaml qiDelta`、塔/Boss 开场加成、波/远征节点恢复、敌方耗气/吸气、slot/HUD/结算；且冻结的 `QiRecoveryPolicy`/五武器 profile 只定义在 `test/tuning/phase2_combat_core_tuning_candidates_test.dart:72-88,769-847`，不在 ledger 合同。

### 3. 接线的最小定义

- 复用 TIMELINE 的 weaponType 快照链；`lib/data/numbers_config.dart`：解析 policy/profile；`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart`：把冻结 profile 作为玩家基础收支并在其上保留既有心法修正/内容开场修正。
- `lib/features/battle/domain/phase0a/qi_resource.dart`/`lib/features/battle/domain/phase0a/phase0a_combat_model.dart`：提供不可变可回放的 ledger snapshot（含 reservations、gain IDs、wave window）；`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart`：普攻 gain、动作首效 commit、取消 release、`Phase0aEnemyDefeated` 后 gainKill。
- `lib/features/battle/application/phase0a/phase0a_wave_battle_flow.dart`：每 wave 换 windowId 并保留既有波间恢复；model 继续投影 `qiCurrent`，技能印、bot 与终态运行器无需另建平行玩家状态。

### 4. 配置落点

```yaml
combat:
  qi:
    weapon_policy: {recovery: basic_and_capped_kill, kill_gain: 5, kill_window_cap: 15}
    weapon_profiles:
      sword: {capacity: 100, opening: 40, basic_gain: 20, power_cost: 28, ultimate_cost: 52}
      heavy: {capacity: 100, opening: 40, basic_gain: 24, power_cost: 34, ultimate_cost: 60}
      flexible: {capacity: 100, opening: 40, basic_gain: 22, power_cost: 30, ultimate_cost: 54}
      dual: {capacity: 100, opening: 40, basic_gain: 18, power_cost: 24, ultimate_cost: 46}
      hidden: {capacity: 100, opening: 40, basic_gain: 18, power_cost: 26, ultimate_cost: 48}
```

### 5. 行为变化面

- 主线/塔/轻功/守城/断魂庄：武器改变普攻回气与强力/大招收费，击杀每 wave 最多回 15，HUD/可用技频率随之变；远征：节点终态 qi 与后续恢复基数改变；扫荡：bot 因 ready 集合变化改出招；离线百草岭按相同 headless ledger 结算，普通被动挂机不变。塔的既有开场加成、连战/远征恢复不能被 profile 的 40 覆盖。

### 6. 现有测试冲击面

- 正则 `qiCurrent|currentQi|qiCost|qiDelta|Phase0aSkillAvailability\.qi|Phase0aSkillAvailabilityChanged|recover.*[Qq]i|qiRecovery`：`battle/mainline/tower/boss_gauntlet/expedition/sweep` 六域 `71 files / 379 hits`；关键为 `test/features/battle/domain/phase0a/phase0a_reducer_test.dart` 50、`test/features/battle/domain/phase0a/phase0a_reducer_guard_test.dart` 25、`test/features/battle/application/phase0a/phase0a_stage_content_mapper_test.dart` 22、`test/features/battle/application/phase0a/phase0a_wave_flow_test.dart` 18、`test/features/battle/presentation/phase0a/phase0a_skill_seals_test.dart` 9、`test/features/battle/application/phase0a/phase0a_headless_kernel_test.dart` 8。

### 7. 风险与不确定点

- 必须拍板冻结 power/ultimate cost 是覆盖所有同类型 `SkillDef.qiDelta`，还是作为武器基础再叠每招差异；否则 `skills.yaml` 与 profile 双真相源。候选的 kill window 明确用 `${stage}.${weapon}.wave`（`test/tuning/phase2_combat_core_tuning_candidates_test.dart:918-937`），生产应按真实 wave 重置。
- capacity/opening 100/40 与现有 80–140 心法气海、Boss/塔开场与紊乱惩罚并存；建议定义为 base，再走现有修正与 cap，避免倒退既有玩法。共享 reducer 接入不触 §5.5；只改 live 或只改 headless 才会触停线。

## 批次顺序建议

1. **POSTURE**：先做；已有 charge/stagger/vulnerability 的 model→reducer→damage→UI 完整接缝，且测试耦合面最小（39 files / 240 hits）。
2. **TIMELINE**：次做；需先补生产 weaponType 和可回放 action state，但它提供 QI “首效 commit/首效前 cancel”所需的唯一时点。
3. **QI**：后做；ledger 明文依赖 first-effect 生命周期（`lib/features/battle/domain/phase0a/qi_resource.dart:42-47`），还要协调最大测试面（71 files / 379 hits）、现有心法修正、221 个技能收支与波/节点恢复。
