# P2-M0 实现差距证据包（PI 只读审计）

> 日期：2026-08-23
> 任务：P2-M0-PI-EVIDENCE（只读证据审计，零生产代码改动）
> 分支：`codex/phase2-m0-pi-evidence-20260823`；基线 `e292d3a0`（= origin/main tip，分支 0 commits ahead）
> 上位文档：`/Users/a10506/Desktop/二阶段优化方案.md`（v2.0，2026-08-23 冻结前最终修订稿；产品方向已有条件通过，G0 未签字）
> 性质：全部数字为 grep/read 实测口径，引用带 `file:line`；**PROPOSED 项一律不视为已决定**，本包只记录现状事实与差距，不写实现。

## 0. 审计范围与方法

五项目标（方案 §0.2 决策表）：

| 决策 ID | 方案状态 | 目标合同 |
|---|---|---|
| COMBAT-WAVE-CD-01 | IMPLEMENTATION-GAP | 同关换波不重置技能冷却，间歇仅自然推进剩余冷却；新关按入场合同重置 |
| EXP-CONCURRENCY-01 | FROZEN | 首版全局同时一条远征 |
| MAINLINE-PARTICIPANT-01 | FROZEN | 主线首推固定「当前掌门」= `founderCharacterId` 所指现任角色；移除静默首角色回退，空值/悬空 ID/角色缺失 fail closed |
| INNER-DEMON-FAILURE-CORE-01 | FROZEN | 心魔失败不回退境界/永久内力/装备、不产生物理伤势、施加内息紊乱 |
| INNER-DEMON-LEGACY-01 | IMPLEMENTATION-GAP | 旧永久内力惩罚注释与配置字段清理（确认无生产读方后删） |

**未触碰项**：`INNER-DEMON-CULTIVATION-01`（主修修炼度扣减）为 PROPOSED，G0 签字前**不得改实现**；`MAINLINE-RUN-01` / `MENTOR-INSIGHT-*` 均 PROPOSED，本包不涉及。

---

## 1. COMBAT-WAVE-CD-01 换波冷却

### 1.1 当前行为

**生产配置与映射把换波策略设为「重置技能冷却」**，与方案目标「同关换波保留剩余冷却并在间歇自然推进」相反：

1. `data/numbers.yaml:1868` — `mainline_wave.wave_intermission.preserve_cooldowns: false`
2. `data/numbers.yaml:1905` — `mass_battle.wave_intermission.preserve_cooldowns: false`（注释：「wave 间 cd 重置(给玩家下波大招机会)」）
3. 映射取反：`lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:172`（主线）与 `:448`（群战）— `resetSkillCooldowns: !intermission.preserveCooldowns` → `false` 被翻成 `true`
4. 执行：`lib/features/battle/application/phase0a/phase0a_wave_battle_flow.dart:196-211` `_applyWaveTransition` — `resetSkillCooldowns=true` 时每个技能槽 `cooldownRemaining: 0` 并重算 availability

**间歇「自然推进」未实现**：换波发生在 `wave_cleared` 同拍（`phase0a_wave_battle_flow.dart:141-190`），无独立间歇拍/间歇时长，冷却只能靠后续战斗 tick 自然递减（`lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:1323` `_cooldownAfter(remaining, deltaSeconds)`）。

### 1.2 精确路径与符号

| 层 | 路径 | 符号 |
|---|---|---|
| 配置 | `data/numbers.yaml:1868 / 1905` | `preserve_cooldowns: false`（主线/群战两处） |
| typed def | `lib/data/defs/mainline_wave_def.dart:129,135,142,155` | `MainlineWaveIntermission.preserveCooldowns`（fromYaml 默认 false） |
| typed def | `lib/data/defs/mass_battle_def.dart:161,190,201` | `MassBattleWaveIntermission.preserveCooldowns`（fromYaml 默认 false） |
| mapper | `lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:172 / 448` | `resetSkillCooldowns: !intermission.preserveCooldowns` |
| flow | `lib/features/battle/application/phase0a/phase0a_wave_battle_flow.dart:20` + `196-211` | `Phase0aWaveTransitionPolicy.resetSkillCooldowns` → `_applyWaveTransition` 清零 |
| 自然递减 | `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:1323` | `_cooldownAfter`（每 tick `remaining - deltaSeconds`） |

### 1.3 现有测试

- `test/data/mainline_wave_schema_test.dart:29` — fixture 写 `'preserve_cooldowns': false`，仅 schema 解析，无语义断言
- `test/features/battle/application/phase0a/phase0a_wave_flow_test.dart:437` — 默认（null policy）换波「HP/真气/CD/技能槽/tick 保留」= 全保留路径已覆盖
- `test/features/battle/application/phase0a/phase0a_wave_flow_test.dart:489` — 显式 `resetSkillCooldowns: true`（`:521-525`）断言冷却清零（即当前生产行为）
- `test/features/battle/application/phase0a/phase0a_stage_content_mapper_test.dart:535-536` — 只断言 `healPlayerToFull=false` + `qiRecoveryPct=0.25`，**未断言 resetSkillCooldowns**（mapper 级缺口）
- `test/data/game_repository_test.dart:529` — 断言群战 `preserveCooldowns==false`（若配置翻转此断言必须同步改）

### 1.4 差距

1. 生产配置/映射与目标合同相反（换波重置 vs 保留）；修法 = 配置翻 true（`resetSkillCooldowns=false` 路径已存在）或改映射语义
2. 缺跨波剩余冷却保留的精确断言（方案 §21.1「同关换波剩余冷却精确保留并在间歇递减」）
3. mapper 级缺 `resetSkillCooldowns` 断言；`game_repository_test.dart:529` 会反向锁死现状
4. 「间歇自然推进」需间歇拍/时长机制（当前换波同拍完成，无间歇段）——属 M1 设计，本包只记录
5. 新关「按入场合同重置」无独立测试

### 1.5 建议 owner 与 targeted 命令

- Owner：主审（Claude）+ 方案 C15/M1（「换波冷却保留、间歇自然推进与新关重置合同」）
- 验收前置：先加 mapper 级断言（`phase0a_stage_content_mapper_test`）+ 跨波剩余冷却保留测，再改 `numbers.yaml` 两处
- Targeted：`flutter test test/features/battle/application/phase0a/phase0a_wave_flow_test.dart test/features/battle/application/phase0a/phase0a_stage_content_mapper_test.dart test/data/mainline_wave_schema_test.dart test/data/game_repository_test.dart --no-pub`
- 改动触及 `numbers.yaml` 主配置 → 批末需 `flutter test test/data --no-pub`

---

## 2. EXP-CONCURRENCY-01 全局单远征

### 2.1 当前行为

**与 FROZEN 一致，无 IMPLEMENTATION-GAP**：

- `lib/features/expedition/application/expedition_service.dart:44` `dispatch()` 内 `writeTxn` 校验：`runs.any((r) => r.saveDataId == save.id)` → `throw StateError('远征派遣：已有进行中的远征，需先召回/结束')`（`:105-108`）
- `lib/features/expedition/application/expedition_service.dart:562-570` `_activeRun()` 返回该存档第一条 `ExpeditionRun`（无 → null）；provider 出口 `lib/features/expedition/application/expedition_providers.dart:32`
- 方案 §8.2/§9.7「首版全局最多一条 active run」与生产实现一致；「按路线/门人数扩并发」为未来新决策，方案已注明需经济模拟+存档互斥设计

### 2.2 精确路径与符号

| 层 | 路径 | 符号 |
|---|---|---|
| service | `lib/features/expedition/application/expedition_service.dart:29` | `class ExpeditionService` |
| 并发守卫 | `expedition_service.dart:105-108` | dispatch 内 `runs.any(saveDataId == save.id)` → StateError |
| 读取 | `expedition_service.dart:562-570` | `activeRun()` / `_activeRun()` |
| provider | `lib/features/expedition/application/expedition_providers.dart:32` | `activeExpeditionRunProvider` 等 |

### 2.3 现有测试

- `test/features/expedition/expedition_dispatch_test.dart:117` —「每存档最多一条 active：二次派遣 → 抛错」✅
- `test/features/expedition/expedition_startup_test.dart:124,154,193` — activeRun 非 null / 召回后 null
- `test/features/expedition/expedition_startup_core_test.dart:227` — fake `activeRun`
- `test/features/debug/application/phase2_seed_service_test.dart:1161` — 重置为单一在途远征

### 2.4 差距

- 代码与文档一致；方案 §21.3「第二条 active 远征一律拒绝」已被 dispatch 测试覆盖
- 无生产改动需求；可选加固：把「每存档最多一条」写成存档级唯一约束/守卫注释，属文档同步不属缺口

### 2.5 建议 owner 与 targeted 命令

- Owner：无需新 owner（现状即冻结态）；M0 底账同步时引用本节即可
- Targeted（确认现有绿）：`flutter test test/features/expedition/ --no-pub`

---

## 3. MAINLINE-PARTICIPANT-01 当前掌门指针与 fallback

### 3.1 当前行为

- **指针**：`SaveData.founderCharacterId`（Isar 字段，旧名「祖师」，实为现任掌门指针）；传位成功时改写：`lib/features/ascension/application/ascend_service.dart:290-297`（performAscend 第 7a 步 `save.founderCharacterId = promotedDiscipleId`，H3 A2 修复）
- **三个生产宿主**均读该指针，且 **null 时静默「取首名角色」回退**：
  1. `lib/features/mainline/presentation/phase0a_mainline_battle_host.dart:154-163` `_buildPlayerSnapshot` — `playerId == null` → `isar.characters.where().findFirst()`（无角色才抛 StateError）
  2. `lib/features/tower/presentation/phase0a_tower_battle_host.dart:121-130` `_buildPlayerSnapshot` — 同模式
  3. `lib/features/sweep/application/phase0a_sweep_headless_runner.dart:109-118` `_loadPlayerSnapshot` — 同模式 + 远征/断魂庄占用拒绝
- **悬空 ID**（指针非空但角色不存在）：`lib/shared/battle_shared/player_combatant_snapshot_assembler.dart:47-58` `loadExactRoster(strictExact: true)` → `StateError('Player roster character ids not found: $missingIds')` —— 已 fail closed，但错误信息是装配层通用文案，不可按「当前掌门指针失效」诊断

### 3.2 精确路径与符号

| 层 | 路径 | 符号 |
|---|---|---|
| 指针定义 | Isar schema `SaveData.founderCharacterId`（`lib/data/isar_setup.dart:366,411,567,695` 等多处读） | `int? founderCharacterId` |
| 传位改写 | `lib/features/ascension/application/ascend_service.dart:290-297` | `save.founderCharacterId = promotedDiscipleId` |
| 主线宿主 | `lib/features/mainline/presentation/phase0a_mainline_battle_host.dart:154-163` | `_buildPlayerSnapshot` null→`findFirst()` 回退 |
| 塔宿主 | `lib/features/tower/presentation/phase0a_tower_battle_host.dart:121-130` | `_buildPlayerSnapshot` 同模式 |
| 扫荡宿主 | `lib/features/sweep/application/phase0a_sweep_headless_runner.dart:109-118` | `_loadPlayerSnapshot` 同模式 |
| 装配校验 | `lib/shared/battle_shared/player_combatant_snapshot_assembler.dart:47-58` | `loadExactRoster` strictExact 抛错 |

### 3.3 现有测试

- `test/features/ascension/application/ascend_service_test.dart:458-467` — 传位后 `founderCharacterId` 自动切继任者（H3 A2 防回退）✅
- `test/features/sweep/application/phase0a_sweep_headless_runner_test.dart:42-43 / 106-107` — 测试自身用 `founderCharacterId ?? findFirst()` 镜像计算期望参与者（seedP3 后指针恒非空，未真正覆盖 null 分支）
- **无任何测试直接断言三宿主的 null 回退 / 悬空 ID / 角色缺失行为**（宿主测试均走 `playerSnapshotForTest` 注入，绕过 `_buildPlayerSnapshot`）

### 3.4 差距

1. null 指针 → 静默「取首名角色」回退，违反方案 G0 处置「移除静默首角色回退，空值/悬空 ID/角色缺失时 fail closed 并给出可诊断错误」
2. 悬空 ID 已 fail closed（loadExactRoster 抛错）但错误文案非「当前掌门指针失效」语义，且发生在装配层而非宿主层
3. 缺传位前后 / 空值 / 悬空 ID / 角色缺失四类测试（方案 G0 处置明确要求）
4. 注意：塔/扫荡参与者也读该指针——G0 处置的「移除静默回退」必须三宿主同步，避免主线 fail closed、塔/扫荡仍静默换人的行为漂移

### 3.5 建议 owner 与 targeted 命令

- Owner：主审（Claude）+ 方案 M1 参与者合同 / MAINLINE-PARTICIPANT-01 G0 处置
- 验收前置：先加证红测试（null/悬空/缺失 → 抛错）再删回退；传位前后指针断言沿用 ascend_service_test 体例
- Targeted：`flutter test test/features/mainline/presentation/phase0a_mainline_wiring_test.dart test/features/sweep/application/phase0a_sweep_headless_runner_test.dart test/features/tower/ test/features/ascension/application/ascend_service_test.dart --no-pub`

---

## 4. INNER-DEMON-FAILURE-CORE-01 心魔失败核心规则

### 4.1 当前行为

生产全链（心魔 → `runStageFlow` → `Phase0aMainlineBattleHost` defeat → `stage_entry_flow.dart:861` `_applyBossDefeatPenalty` → `CombatResolutionService.resolveSnapshot`）：

1. **永久内力不扣** ✅（与 FROZEN 一致）：`lib/features/combat_shared/application/combat_resolution_service.dart:240-265` 心魔 defeat 分支调用 `InnerDemonService.applyFailurePenalty`；`lib/features/inner_demon/application/inner_demon_service.dart:76-106` 只做 `InnerBreathDisorder.apply`（clamp maxHours）+ 主修 progress ×0.90，**从不修改 `ch.internalForce`**
2. **内息紊乱施加** ✅：`lib/core/domain/inner_breath_disorder.dart` apply 写 `innerBreathDisorderHoursRemaining` clamp [0, maxHours]；配置 `data/numbers.yaml:55-62`（`max_hours: 12.0` / `inner_demon_hours: 12.0`）
3. **⚠ 物理伤势仍被施加**（与 FROZEN「不产生物理伤势」冲突）：`combat_resolution_service.dart:265-280` 伤势通用层 `InjuryService.applySettlementInjuries` 不依赖 stageType；`stage_entry_flow.dart:930` 传 `isHardFight: stage.isBossStage`，心魔关 `isBossStage: true`（`data/stages.yaml:5260`）→ 心魔战败对参战角色施加轻伤（`lightInjuryStacks +1` 每场）+ 重伤（`injuryHoursRemaining = recoveryHours`，`lib/features/injury/application/injury_service.dart:25-55`）
4. **主修修炼度 ×0.90 扣减仍在**：属 `INNER-DEMON-CULTIVATION-01 / PROPOSED`，G0 签字前不得擅改（方案 §7.2 明示）

### 4.2 精确路径与符号

| 层 | 路径 | 符号 |
|---|---|---|
| 结算入口 | `lib/features/combat_shared/application/combat_resolution_service.dart:240-265` | 心魔 defeat 分支（`stageDef.stageType == StageType.innerDemon`） |
| 惩罚纯函数 | `lib/features/inner_demon/application/inner_demon_service.dart:76-106` | `InnerDemonService.applyFailurePenalty`（内力不动 / 紊乱 / 主修×0.90） |
| 紊乱 | `lib/core/domain/inner_breath_disorder.dart` | `InnerBreathDisorder.apply/recover` |
| **伤势（缺口点）** | `combat_resolution_service.dart:265-280` + `lib/features/injury/application/injury_service.dart:25-55` | `applySettlementInjuries`（无 stageType 豁免） |
| 硬仗判定 | `lib/features/mainline/presentation/stage_entry_flow.dart:930` / `:709` | `isHardFight: stage.isBossStage` |
| 心魔关标记 | `data/stages.yaml:5260`（`stage_inner_demon_01` 示例） | `isBossStage: true` |

### 4.3 现有测试

- `test/features/inner_demon/application/inner_demon_failure_penalty_test.dart` — 纯函数层 5 组：永久内力不扣 / 紊乱写入与上限 / 主修 ×0.90 / layer 不回退 ✅
- `test/features/mainline/inner_demon_defeat_summary_test.dart` — `buildDefeatLossEntries` 汇总（**无伤势断言**）
- **无生产路径（resolve 全链）「心魔战败不产生伤势」测试**；`applySettlementInjuries` 对 innerDemon 无豁免、无测试锁行为

### 4.4 差距

1. **生产路径心魔战败仍施加物理伤势**（轻 + 重）——方案证据列（「当前不扣永久内力，并施加内息紊乱」）**未记录此事实**；FROZEN 合同含「不产生物理伤势」，G0 处置「保留核心规则并补生产惩罚测试」时须把伤势豁免纳入范围（stageType 豁免或配置开关 + 专项测试）
2. 缺生产级惩罚测试（方案 G0 处置明确要求「补生产惩罚测试」）
3. 现有纯函数测试只覆盖 `applyFailurePenalty`，不覆盖 `resolveSnapshot` 内惩罚 + 伤势两条分支的互斥组合

### 4.5 建议 owner 与 targeted 命令

- Owner：主审（Claude）+ 方案 M-DEMON / M1-C17
- 验收前置：先加证红测试（心魔战败 → 无 injuryHoursRemaining / 无 lightInjuryStacks 新增；对照普通 Boss 战败 → 有伤势），再改 `combat_resolution_service.dart` 伤势分支（或引入 stageType 豁免）
- Targeted：`flutter test test/features/inner_demon/ test/features/mainline/inner_demon_defeat_summary_test.dart test/features/combat_shared/ --no-pub`
- 涉及结算切面 → 批末全量 `flutter test --no-pub`

---

## 5. INNER-DEMON-LEGACY-01 旧惩罚残留

### 5.1 当前行为与残留清单

**实现已不扣永久内力，但配置字段 / 注释 / 测试名仍残留旧公式**：

1. **配置死字段（0 生产读方）**：`data/numbers.yaml:1751-1754` `inner_demon.failure_penalty` 下
   - `internal_force_multiplier: 0.85`（旧「扣 15% 永久内力」）
   - `internal_force_floor_pct: 0.50`（旧「内力扣减地板」）
   - 另三个自标 UNUSED：`sub_cultivation_multiplier: 1.00` / `debuff_id: inner_demon_residue` / `debuff_clear_via_retreat_hours: 8`
2. **typed def 默认与解析**：`lib/data/defs/inner_demon_def.dart:69-90`（`InnerDemonDef.empty()` 携带全部 5 字段）、`:215-283` `InnerDemonFailurePenalty`（fromYaml 解析；`subCultivationMultiplier`/`debuffId` 已带「UNUSED(0 生产消费 · 审计 D5 2026-06-24)」注释）
3. **注释残留**：`lib/features/inner_demon/application/inner_demon_service.dart:66-74` — doc comment 仍写 `ch.internalForce = max(floor(old × internalForceMultiplier), floor(internalForceMax × internalForceFloorPct))`（代码从未执行）；类头 `:10` 「in-place 改 ch.internalForce + mainTech.cultivationProgress 已发生」与实际（内力不动）不符
4. **测试残留**：`test/features/inner_demon/application/inner_demon_failure_penalty_test.dart:79` 测试名「已在地板附近：500 × 0.85 = 425 < 地板 500 → clamp 500」仍描述旧公式（断言本身只验内力不变，恒真）；`test/features/inner_demon/application/inner_demon_service_test.dart:276,296` 与 `test/features/inner_demon/domain/inner_demon_def_test.dart:11,16` 断言死字段值

### 5.2 精确路径与符号

| 层 | 路径 | 符号 |
|---|---|---|
| 配置 | `data/numbers.yaml:1751-1754` | `internal_force_multiplier` / `internal_force_floor_pct`（+ 3 个 UNUSED 字段） |
| typed def | `lib/data/defs/inner_demon_def.dart:69-90 / 215-283` | `InnerDemonFailurePenalty`（empty 默认 + fromYaml 解析） |
| 注释 | `lib/features/inner_demon/application/inner_demon_service.dart:10 / 66-74` | 旧内力惩罚公式描述 |
| 测试 | `test/features/inner_demon/application/inner_demon_failure_penalty_test.dart:79`；`inner_demon_service_test.dart:276,296`；`inner_demon_def_test.dart:11,16` | 死字段断言 / 旧公式测试名 |

**无生产读方实测**：`grep -rn "internalForceMultiplier|internalForceFloorPct" lib/` 仅命中 `inner_demon_service.dart:68-69` 的注释；`subCultivationMultiplier` / `debuffId` / `debuffClearViaRetreatHours` lib 下零引用（def 注释自认 UNUSED）。生产读方 = `InnerDemonFailurePenalty.mainCultivationMultiplier` 唯一（`inner_demon_service.dart:96`）。

### 5.3 现有测试（约束清理范围）

- 上述死字段断言测试若清理配置/def 需同步删改
- 防回退先例：`test/data/truth_source_guard_test.dart:127-130` — `boss_internal_force_penalty` 不得重回 `numbers.yaml`（v1.41 退役同类字段的守卫）；清理 `internal_force_*` 可仿此加守卫

### 5.4 差距

1. 确认无生产读方（已实测）→ 可清理：删配置字段、empty 默认、fromYaml 解析、def 字段与 UNUSED 注释、service 头注释、测试名/断言
2. 清理须一次到位（配置 + def + 注释 + 测试四层同批），避免文档与行为再次脱节
3. 可选加 `truth_source_guard` 式防回退守卫（仿 `boss_internal_force_penalty` 先例）

### 5.5 建议 owner 与 targeted 命令

- Owner：主审（Claude）+ 方案 M1-C17（「心魔失败实现/配置/注释差异清理」）
- Targeted：`flutter test test/features/inner_demon/ test/data/truth_source_guard_test.dart --no-pub`
- 涉及 `numbers.yaml` + typed def → 批末 `flutter test test/data --no-pub` + `flutter analyze`

---

## 6. 汇总：差距矩阵与建议任务

| 决策 ID | 现状 vs 合同 | 差距等级 | owner 建议 | 前置动作 |
|---|---|---|---|---|
| COMBAT-WAVE-CD-01 | 相反（换波重置冷却） | 高（配置+映射+测试三处） | 主审 + C15/M1 | 先补 mapper 断言与跨波保留测，再翻配置 |
| EXP-CONCURRENCY-01 | 一致 | 无（保持现状） | — | 仅文档同步引用 |
| MAINLINE-PARTICIPANT-01 | null 静默回退 / 悬空 ID 已 fail closed | 中（三宿主同步 + 4 类测试） | 主审 + M1 参与者合同 | 先加证红测试再删回退 |
| INNER-DEMON-FAILURE-CORE-01 | 永久内力 ✅ / 紊乱 ✅ / **伤势仍施加** | 高（证据列缺伤势事实） | 主审 + M-DEMON/M1-C17 | 先证红（心魔战败无伤势）再豁免 |
| INNER-DEMON-LEGACY-01 | 死配置/注释/测试残留 | 中（四层同批清理） | 主审 + M1-C17 | 已实测无生产读方，可直接排期 |

## 7. 复现命令附录

```bash
# COMBAT-WAVE-CD-01
grep -rn "preserve_cooldowns" data/numbers.yaml lib/ test/
# EXP-CONCURRENCY-01
grep -n "已有进行中的远征\|_activeRun" lib/features/expedition/application/expedition_service.dart
# MAINLINE-PARTICIPANT-01
grep -rn "founderCharacterId" lib/features/mainline/presentation/phase0a_mainline_battle_host.dart \
  lib/features/tower/presentation/phase0a_tower_battle_host.dart \
  lib/features/sweep/application/phase0a_sweep_headless_runner.dart \
  lib/features/ascension/application/ascend_service.dart
# INNER-DEMON 失败与残留
grep -rn "applyFailurePenalty\|applySettlementInjuries" lib/features/combat_shared/application/combat_resolution_service.dart
grep -rn "internalForceMultiplier\|internalForceFloorPct" lib/ data/numbers.yaml test/ | grep -v inner_demon_def.dart
```

> 本包为只读证据，不含任何实现决策；`PROPOSED` 项（主修修炼度扣减去留、重打/扫荡参与者等）待 G0 签字，G0 前不得按本包推断实现。
