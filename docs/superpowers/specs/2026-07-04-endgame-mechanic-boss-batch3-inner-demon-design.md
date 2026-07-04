# 终局机制型 Boss · 批次3 心魔应用 · 设计 spec

> 日期：2026-07-04 · 阶段：1.0 长线打磨期 · 类型：设计级（换杠杆 + 新胜负条件，非改值）
> 上游 spec：`docs/superpowers/specs/2026-07-03-endgame-mechanic-boss-design.md` §5/§6/§9 批次3
> 前批：批次1 底座 `7bcd18aa` + 批次2 爬塔 `934df290` + 批次4 周目 `0bd1ed2d` + 批次5 红线 `10b4672d` 均合 main
> 拍板前提：用户 2026-07-04 拍板「完整档：镜像脆弱窗口 + 终关 survive」+ 三个设计点（开窗机制/配置范围/survive 语义）

## 0. Phase 0 证伪（改变原 spec 前提，必读）

原 2026-07-03 spec §6 表格「心魔 7 关：相位开窗（相位=心魔递进）」是在**未核实心魔敌队构造方式**前写的。本批 Phase 0 核实推翻两条前提：

1. **心魔敌队是运行时镜像玩家队，非 yaml 固定 `EnemyDef`**（`stage_battle_setup.dart:57` → `InnerDemonService.buildMirrorEnemyTeam` 深拷贝玩家队 ×buff + clamp caps；`stages.yaml` 心魔关 `enemyTeam: []` 只有 narrative id）。→ 批次1/2 的「相位开窗 via `EnemyDef.bossPhases/vulnerability`」接线路径**对心魔不存在**，须**新接线到 `buildMirrorEnemyTeam`**（注入到镜像 `BattleCharacter`）。且镜像继承玩家 `availableSkills`，玩家不保证有蓄力技 `chargeSkillId` → 脆弱窗口须**人为注入蓄力技**才能开窗（否则永久免疫无解）。
2. **心魔战败惩罚早已完全接线**（`battle_resolution.dart:256` 真调 `InnerDemonService.applyFailurePenalty`：内力×0.85 / 修炼度×0.9 / 余毒 8h，有 `inner_demon_failure_penalty_test` 守护）。外部审查 §6.2「未 wire」写于 2026-07-03，但实装是 M6（2026-06-16）——**审查自身前提过时**。→ 战败惩罚**不是**本批待做项，心魔的「克己」张力已由 gate 拦截 + 镜像 +buff + 战败惩罚三者支撑。

## 1. 目标与非目标

**目标**：让**高层心魔关**（05/06 击败镜像胜）与**终关**（07 生存胜）的满配玩家不能纯 DPS 一发秒杀，须应对机制——05/06 抓镜像脆弱窗口、07 撑过限时生存。前四关（01-04）低层维持现有突破 gate 张力不动。

**非目标**：
- 不削任何数值硬红线（镜像仍 clamp caps HP≤20000 / IF≤15000 / 攻击≤6000，招式倍率仍全局 ≤8000）。
- 不改前四关（01-04）心魔手感（低层维持现状）。
- 不做心魔战败惩罚（M6 已 wire，非本批）。
- 不引入在线 buff / 挂机加速（守 §5.5）。
- 不改「镜像=你自己」的基础语义到 01-04；05/06 的「机制化心魔」是有意的进阶形态例外（见 §3.4）。

## 2. 现状与约束（Phase 0 已核实，带 file:line）

**可复用原语（就绪，批次1/2 已实装）**：
- `BattleCharacter.vulnerabilityMult`（`battle_state.dart:241-243`，double?，null=无机制）+ copyWith（:544,:611）。
- 伤害闸 `vulnerabilityMultOf(defender, state)`（`default_ground_strategy.dart:926-937`）：defender 带 mult 且当前不脆弱（`chargingSkill==null && staggerTicksRemaining==0`）→ 返 mult（减伤）；脆弱窗口内或无机制 → 1.0。消费点 :894，与 `wardMultOf` 相乘进伤害末端，零改伤害计算器。
- 蓄力字段 `chargeSkillId`（:186）/ `chargingSkill`（:189）/ `chargeTicksRemaining`（:192）+ copyWith。
- AI 蓄力触发：`default_ground_strategy.dart:406-429`——AI 选中自己的 `chargeSkillId`（强力技分支靠 `powerMultiplier` 排序选中，`battle_ai.dart:140-150`）→ 进蓄力态（`chargeTicksRemaining = numbers.combat.bossCharge.defaultChargeTicks`，`numbers.yaml:133-137` 已配 =3）→ 放招 → CD → 再蓄。窗口频率 = 蓄招技 CD（现成，`skills.yaml` 可调），**无需新 cadence 字段**。
- 蓄力技注入体例：`stage_battle_setup.dart:448-462`「识破」词条——`chargeSkillId == null` 时设 `chargeSkillId` 并把技追加进 `availableSkills`（若不在列表）。心魔镜像注入照此体例。
- `BattleState.tick`（:667，初值 0，每 stepOne 边界 +1，:90）+ `isFinished => result != null`（:736）+ `BattleResult{leftWin,rightWin,draw}`（:40）。
- 胜负判定三处（`default_ground_strategy.dart`）：内伤致死 :314-327、常规致死 :545-550、超时 draw（`runToEnd` :135-136，`maxTicks=1000` 硬写签名默认）。均按「某方全灭→另方胜 / 双灭或超时→draw」。

**心魔链路现状**：
- `stage_battle_setup.dart:47-70` 心魔分支 → 右队走 `buildMirrorEnemyTeam`（line 57），**不走 `_enemyToBattle`**（无 EnemyDef 对象）→ 现无 vulnerability 灌入、无 chargeSkillId。
- `_mirror`（`inner_demon_service.dart:164-196`）：仅复制/强化 hp/if/attack + 重置战中状态，**未设 vulnerabilityMult / chargeSkillId / 注入蓄力技**。
- 05/06/07 配置：`stages.yaml:1622-1668`（`enemyTeam:[]` / `isBossStage:true` / 无 winCondition）；`numbers.yaml:1572-1627` innerDemonDef（mirror_buff 05=0.18 / 06=0.20 / 07=0.40，mirror_caps HP20k/IF15k/攻击6k，failure_penalty，required_realm_layer）。
- `InnerDemonDef`（`inner_demon_def.dart:15-41`）：mirrorBuffPerStage / mirrorCaps / failurePenalty / residueDebuff / unlockTriggers / requiredRealmLayer，fromYaml Map 读取（:71-116）。

**已知坑（必须规避，均已核实）**：
- ⚠️ **镜像继承玩家技能未必含蓄力技** → 必须注入专属心魔蓄力技，否则永不开窗 = 永久免疫无解（对齐批次1「vulnerability 必有 chargeSkillId」的硬前提）。
- ⚠️ **首击秒杀使机制失效**（memory `boss_phase_needs_hp_not_just_threshold`）→ 镜像默认 ×mult 减伤正好防首击秒整只；镜像有 caps 内血量撑到窗口。
- ⚠️ **跨阶才真难**（memory `boss_balance_crosstier`）→ 诊断须测 under-gear 跨阶（心魔关 required_realm_layer 锁 wuSheng，跨阶诊断走低强化/欠共鸣满配）。
- ⚠️ **Strategy immutable vs UI tick**（memory `strategy_immutable_vs_ui_tick` / `battle_determinism_test_via_notifier`）→ 机制逐 tick 生效，诊断测走 `notifier.advance` / `ProviderContainer` 永久 listener + 固定 seed，非直接 `strategy.tick`。
- ⚠️ **结算路径读 config 崩轻量 widget 测**（memory `battle_result_path_config_read_crashes_light_test`）→ winCondition 消费路径若被轻量 widget 测触及须防御式兜底。
- ⚠️ **survive 判定必须逐 tick 内部做**（见 §5.2）→ 不可上层 `runToEnd` 返回后补判。

## 3. 模块1：心魔镜像脆弱窗口（削秒杀 · 配 05/06）

### 3.1 核心机制

给 **inner_demon_05/06** 的镜像敌注入脆弱窗口：镜像默认承伤 ×`outOfWindowDamageMult`（如 0.10-0.12），只在「运劲蓄力（`chargingSkill != null`）或被破招踉跄（`staggerTicksRemaining > 0`）」窗口内受全额伤。复用批次1 已实装的 `vulnerabilityMult` 字段 + `vulnerabilityMultOf` 伤害闸，**零改伤害计算器**。

### 3.2 开窗机制（用户拍板：注入心魔蓄力技，CD 驱动复发）

- **新蓄力技** `skill_inner_demon_charge`（心魔·运劲）配 `skills.yaml`：`type: powerSkill`，高 `powerMultiplier`（保证 AI 强力技分支选中它 → 进蓄力态），`cooldownTurns` 控开窗频率，`requiresManualTrigger: false`。**仅注入 05/06 镜像，不进玩家技能池 / 不进任何 EnemyDef**。
- **注入点** `buildMirrorEnemyTeam` / `_mirror`：05/06 镜像补 `chargeSkillId = skill_inner_demon_charge` + `availableSkills` 追加该技（照 `stage_battle_setup.dart:448` 识破体例），使镜像周期性蓄力开窗（自动战斗不 no-op：每 tick 普攻在窗口内全额、窗口外 ×mult，进度不摆）。
- **半手动**：玩家识别 telegraph → `canInterrupt` 破招 → 镜像踉跄（延长窗口 + 减防）→ 集火倾泻，奖励参与。

### 3.3 数据模型

`numbers.yaml innerDemonDef` 加 per-stage 脆弱配置：
```yaml
inner_demon:
  # ...现有 mirror_buff_per_stage / mirror_caps / failure_penalty...
  mirror_vulnerability_per_stage:      # 新增：仅高层机制化心魔关配
    stage_inner_demon_05:
      outOfWindowDamageMult: 0.12       # schema [0.05,1.0]
    stage_inner_demon_06:
      outOfWindowDamageMult: 0.10
  mirror_charge_skill_id: skill_inner_demon_charge   # 新增：注入镜像的蓄力技 id（有 vulnerability 配置的关才注入）
```
- `InnerDemonDef` 加 `mirrorVulnerabilityPerStage: Map<String, BossVulnerabilityDef>`（复用 `BossVulnerabilityDef.fromYaml` 的 [0.05,1.0] 校验）+ `mirrorChargeSkillId: String?`。
- **跨字段校验**（fromYaml 末尾）：某关配了 `mirror_vulnerability_per_stage` 但 `mirror_charge_skill_id` 为空 → 启动期 fail-fast（永不开窗无解，对齐批次1 硬前提）。
- 脆弱条件不落 yaml（硬编码复用 chargingSkill/stagger），只配减伤强度 + 蓄力技 id。

### 3.4 语义说明（有意的进阶形态例外）

`buildMirrorEnemyTeam` docstring 现强调「与自己一模一样的对手」。05/06 注入蓄力技后镜像多一层机制，**不再是纯镜像**。这是**有意的「机制化心魔」进阶形态**——对齐 floor25/30 机制型 Boss 定位：高层心魔是「被心魔扭曲的自己」，会运劲蓄势、露出破绽。01-04 低层维持纯镜像。docstring 须同步标注此例外。

## 4. 模块2：终关限时生存（survive · 配 07）

### 4.1 核心机制（用户拍板：撑满 N tick 或击败镜像，任一即胜）

`inner_demon_07` 加 `winCondition: {type: surviveTicks, ticks: N}`。战斗中：
- **撑满 N tick 且左队存活** → `leftWin`（坚持住 = 战胜自己）。
- **右队（镜像）全灭** → `leftWin`（现有判定天然并存，提前斩镜像也算胜）。
- **左队全灭**（tick < N 前） → `rightWin`（被心魔击败）。
两通道任一先达成即结束。survive 与 DPS 彻底脱钩（满配无法靠伤害提速通关，但可选择斩镜像提前胜）。

### 4.2 承载与判定（方案 B：进 BattleState，strategy 逐 tick 内部判）

**为何不能上层判**：`runToEnd` 会一直跑到全灭/maxTicks，若玩家撑不到全灭也没在 tick N 前斩镜像，`runToEnd` 继续跑到玩家全灭（rightWin）或 maxTicks（draw），上层拿到的 `result` 已定，无法回溯「tick N 时左队还活着应判胜」。→ survive 必须在 strategy **写 result 之前逐 tick 检查**。

**接线**：
- 新 `StageWinCondition` 类（`stage_def.dart` 或新 def 文件）：`type`（枚举 `defeatAll`(默认) / `surviveTicks`）+ `surviveTicksRequired: int?`。`StageDef` 加可选 `winCondition` 字段 + fromYaml 解析（`winCondition == null` → 默认 defeatAll，旧关零影响）。
- `BattleState` 加可选 `winCondition: StageWinCondition?`（默认 null = defeatAll 旧行为）+ copyWith（unset sentinel 或 `?? this`）+ initial 可选参数默认 null。`StageBattleSetup` 从 StageDef 透传进 initial state（心魔分支 + 通用分支）。
- `default_ground_strategy.dart`：在三处胜负判定 + `runToEnd` 循环里，**每 tick 推进后、写 result 前**插入 survive 检查——`state.winCondition?.type == surviveTicks && state.tick >= surviveTicksRequired && leftAlive` → `result = leftWin`。survive 检查优先于 draw/超时，与现有全灭判定并存（右队全灭仍先判 leftWin）。
- **`winCondition == null` 时所有现有战斗零行为变化**（默认走 defeatAll，即现状全灭/超时判定）。

### 4.3 数据模型

`stages.yaml stage_inner_demon_07`：
```yaml
- id: stage_inner_demon_07
  # ...现有字段...
  winCondition:
    type: surviveTicks
    ticks: 40            # 诊断校准（§6）
```
schema：`type` 非法值 / `surviveTicks` 缺 ticks 或 ticks≤0 → 启动期 fail-fast。

## 5. 数值起点（诊断驱动校准，plan 阶段定稿）

| 项 | 起点 | 依据 |
|---|---|---|
| 05 镜像 `outOfWindowDamageMult` | 0.12 | 比 floor25(0.10)略松（镜像本已 +18% buff） |
| 06 镜像 `outOfWindowDamageMult` | 0.10 | 对齐 floor25 强度（+20% buff） |
| 心魔蓄力技 `powerMultiplier` | 3000 | 足够高保证 AI 选中进蓄力（低于全局 ≤8000 硬线）；诊断确认真进蓄力态 |
| 心魔蓄力技 `cooldownTurns` | 4 | 对齐现有蓄力技，窗口周期性复发 |
| 心魔蓄力技 `internalForceCost` | 200 | 对齐现有蓄力技；镜像满内力开战撑得起周期放招 |
| 07 `surviveTicks` N | 40 | 上游 spec §5 起点；校准到「满配撑得过但非碾压、欠配有可观败率」 |

**校准红线**：诊断测硬断言——① 05/06 满配 on-level 能赢但 time-to-kill 跨 ≥N 个窗口（证机制真 gate 非首击秒）② under-gear 跨阶有可观败率 ③ 自动战斗窗口真触发（承伤被折扣、窗口周期开、进度不摆）④ 07 satisfy 双通道各触发 + 边界（tick N-1 未达成）。所有诊断走确定性 seed。

## 6. 测试策略（守 memory 五坑）

1. **确定性**：走 `notifier.advance` / `ProviderContainer` 永久 listener + 固定 seed（memory `battle_determinism_test_via_notifier`），**非直接 `strategy.tick`**。
2. **模块1 诊断**（扩 `cycle2_vulnerability_diagnostic_test` 体例）：05/06 满配 A/B（copyWith 有/无 vulnerabilityMult）证窗口独立 gate（B/A time-to-kill 显著↑、窗口外承伤被 ×mult 折扣非全额、Boss 血量进度不摆）+ 跨阶 under-gear 软门槛。避 `ward_noop`。
3. **模块2 诊断**：07 survive 双通道——(a) 满配面对可斩镜像 → 提前斩获 leftWin（tick < N）；(b) 欠配/强镜像撑到 tick N 左队存活 → leftWin；(c) 边界 tick N-1 未达成不误判；(d) 左队 tick < N 全灭 → rightWin。
4. **schema 红绿双验**：`outOfWindowDamageMult` 越界 / `mirror_charge_skill_id` 缺失但配了 vulnerability / `winCondition.type` 非法 / `surviveTicks` 缺 ticks → 启动期 fail-fast（红：摘配置测转红）。
5. **轻量 widget 测防崩**（memory `battle_result_path_config_read_crashes_light_test`）：winCondition 消费路径若被结算/result dialog 轻量测触及，防御式兜底（null-safe 默认 defeatAll）。
6. **注入单测**：`buildMirrorEnemyTeam` 05/06 镜像有 vulnerabilityMult + chargeSkillId + availableSkills 含蓄力技；01-04 / 07 镜像**无** vulnerability 注入（分关精确）。
7. **回归**：改核心 strategy 结束判定（模块2）→ 批末全量 `flutter test --no-pub`；模块1 注入自包含 → targeted + analyze。

## 7. 红线合规

- 纯机制层，**不碰数值硬红线**：镜像仍 clamp caps（HP≤20000/IF≤15000/攻击≤6000）；蓄力技倍率 3000 < 全局 ≤8000；vulnerability 减伤方向、schema 有界 [0.05,1.0]、非属性 buff。
- **守 §5.4 机制型 Boss 例外条款**（批次5 `10b4672d` 已立 v1.30）：心魔 05/06/07 是「减伤方向 / 生存条件」的机制门槛，只压低有效伤害 / 改胜负条件，不膨胀伤害数字、不触「不进百万」硬线。
- survive 不改任何伤害数字，纯胜负条件；不破在线=离线、三系锁死。
- **红线文档同步**（批次末）：GDD §5.4 + CLAUDE §5.4 机制型 Boss 例外条款补登「心魔 05/06 脆弱窗口 + 07 限时生存」（批次5 已铺底座，本批仅追加实例，措辞对齐既有条款）。

## 8. 实装批次（依赖序，Subagent-Driven TDD，每 Task spec+quality 双审）

1. **winCondition 数据面**：`StageWinCondition` 类 + `StageDef.winCondition` 字段 + fromYaml + schema 红绿测（纯数据面，低回归，不接战斗）。
2. **survive 战斗判定**：`BattleState.winCondition` 字段 + copyWith/initial + `StageBattleSetup` 透传 + strategy 逐 tick survive 判定 + 确定性诊断测（改核心结束判定，批内全量跑 battle 测）。
3. **心魔蓄力技 + 镜像注入**：`skill_inner_demon_charge` skills.yaml + `buildMirrorEnemyTeam`/`_mirror` 注入（vulnerabilityMult + chargeSkillId + availableSkills）+ 注入单测（分关精确）。
4. **innerDemonDef 数据面 + 05/06 诊断**：`mirrorVulnerabilityPerStage` + `mirrorChargeSkillId` 解析 + 跨字段校验 + 05/06 端到端诊断测（A/B + 跨阶软门槛）。
5. **07 winCondition 配置 + survive 诊断 + 校准**：`stage_inner_demon_07` winCondition 配置 + survive 双通道诊断测 + 数值校准定稿（05/06 mult、07 N）。
6. **红线文档同步 + 批末全量**：GDD/CLAUDE §5.4 追加实例 + 全量 `flutter test --no-pub` + analyze 0 + PROGRESS 四态更新。

每批独立可验证、小切片 commit、更新 plan 恢复点。Task2（改战斗结束）回归面最大，先做数据面（Task1）铺底再接战斗。

## 9. 风险与 defer 项

- **模块2 改 `isFinished`/winner 判定**：回归面最大。缓解——winCondition 默认 null = defeatAll 旧行为，所有现有战斗零变化；survive 分支仅 winCondition 非 null 时进入。批内全量 battle 测防回归。
- **自动 AI 不「刻意」在窗口爆发**（模块1）：批次1 底座已保证进度不摆（窗口外 ×mult 而非 0），但「自动效率 < 手动」是有意（奖励参与）。若诊断发现自动效率过低致 under-gear 永败，再评估自动 AI 感知脆弱窗口集火（新 AI 分支 opt-in，本批不做）。
- **蓄力技注入破坏纯镜像语义**：05/06 有意例外（§3.4），01-04/07 不注入。若视觉验收觉得「不像打自己」，可回退为仅 07 survive（模块1 defer），但用户已拍板完整档。
- **inner_demon_07 双镜像**（Batch 2.5.C 遗留 +40% 单副本）：本批不动镜像数量，survive 配在现有单副本 +40% 镜像上。
