# 终局机制型 Boss · 设计 spec

> 日期：2026-07-03 · 阶段：1.0 长线打磨期 · 类型：设计级（换杠杆，非改值）
> 来源：外部设计审查 `docs/audit/external_design_review_2026-07-03.md` §6.1 + PROGRESS 2026-07-01 挂账「终局 Boss 100% 胜偏软」
> 拍板前提：用户 2026-07-03 拍板「部分终局 Boss 强制机制，接受削秒杀」+ 范围「三块终局内容全覆盖」

## 1. 目标与非目标

**目标**：让**部分**终局 Boss 的胜负回到「玩家是否应对机制」，而非「满配 DPS 够不够」。满配玩家在这些 Boss 上不能纯堆伤害一发秒杀，必须应对机制窗口 / 护法墙 / 生存条件。

**非目标**：
- 不削任何数值红线（血量仍 ≤60000，招式倍率仍全局 ≤8000，装备派生攻击终局爽感不动）。
- 不改普通终局内容的秒杀爽感（爬塔 5-20、主线关、周目一周目保持现状）。
- 不做全菜单机制（击杀顺序狂暴、Boss 回血陷阱、内力饥荒等本轮不实装——内力饥荒因「敌人放招不扣内力」P5.2 未完成而不成立）。
- 不引入在线 buff / 挂机加速（守 §5.5）。

## 2. 现状与约束（Phase 0 已核实，带 file:line）

**可复用原语（就绪）**：
- 相位系统 `lib/data/defs/boss_phase_def.dart`：`BossPhaseDef{hpThresholdPct, unlockSkillIds, aiMode, onEnterMechanic, titleKey}` + `BossPhaseMechanic.chargeCounter` + `cycleBossPhases`（周目重定义）。floor 20/25/30 已用。
- 破招/蓄力：`BattleCharacter.chargeSkillId/chargingSkill/chargeTicksRemaining/staggerTicksRemaining/staggerDefenseDownOverride`（`battle_state.dart`）。`canInterrupt` 技在 `battle_ai.dart:64` 有 P0 破招锁定优先级。
- 目标 AI：`_pickTargetId`（低血）/`_pickFocusTargetId`（破绽窗口）/`_pickControlTargetId`（蓄力优先），`battle_ai.dart:158-207`。
- 表现层：`BattleAction.bossPhaseTransitionTo/interrupted/openedBreakWindow` 已被弹题字消费。
- Strategy 纯函数 immutable：`default_ground_strategy.dart` `tick/stepOne`，新机制在 `_resolveAction`（伤害前/后）/`_advanceTick`（蓄力递减）注入。BattleCharacter immutable，copyWith。

**已知坑（必须规避，均已核实）**：
- 🔴 **护法结界减伤自动 no-op**（`towers.yaml:1301` 注释自承）：自动 AI 先清低血护法，Boss 从不被选中，`damageTakenMult=0.15` 只对手动越护法的玩家生效。→ 模块 A 修此。
- 🔴 **敌人放招不扣 `currentInternalForce`**（P5.2 对称化未完成）：内力饥荒机制不成立，本轮不做。
- ⚠️ **首击秒杀使 hpThreshold 失效**（memory `boss_phase_needs_hp_not_just_threshold`）：相位阈值在 Boss 被首击秒杀时无意义。→ 脆弱窗口免疫正好防首击秒整只，但护法/Boss 需有血撑到窗口。
- ⚠️ **跨阶才真难**（memory `boss_balance_crosstier`）：诊断须测 under-gear 跨 1-2 阶。
- ⚠️ **Strategy immutable vs UI tick**（memory `strategy_immutable_vs_ui_tick`）：机制须逐 tick 生效，测试走 `notifier.advance` / `ProviderContainer` 永久 listener，非直接 `strategy.tick`。

## 3. 底座：脆弱窗口（Vulnerability Window）

### 3.1 核心机制

机制型 Boss 带 `vulnerability` 档。**默认对全额伤害大幅减伤（承伤 ×`outOfWindowDamageMult`，默认 0.10），只在「脆弱窗口」内受全额伤（×1.0）。**

脆弱窗口判定（**复用现有状态，无新状态字段**）：
```
Boss 脆弱 ⟺ (chargingSkill != null) OR (staggerTicksRemaining > 0)
否则 → 承伤 ×outOfWindowDamageMult
```

### 3.2 窗口如何开（自动 robust 的关键）

**窗口复发靠现成机制，不造新轮子**（planning Phase 0 核实：`default_ground_strategy.dart:406-429` 起手蓄力路径）：
- **Boss 起手蓄力已由 AI 按 `chargeSkillId` 的技能 CD 周期性触发**——AI 选中自己的 `chargeSkillId` → 进蓄力态（`chargeTicksRemaining` 拍）→ 放招 → 技能进 CD → CD 到再蓄。窗口频率 = 该蓄招技的 CD（`skills.yaml` 现成可调），**无需新 `chargeCadenceTicks` 字段/计数器**。相位 `chargeCounter` 额外在进阶时开一次窗（`_advancePhases:633-649` 现成）。
- **硬前提**：机制型 Boss 必须有 `chargeSkillId`（否则永不开窗 = 永久免疫无解）。→ schema 跨字段校验：`vulnerability != null` 要求 `chargeSkillId != null`，启动期 fail-fast。
- **自动战斗**：即便 AI 不「刻意」在窗口爆发，每 tick 普通输出在窗口内全额、窗口外 ×0.10 → 进度不摆、不 no-op（区别于护法减伤 no-op）。
- **半手动**：玩家识别 telegraph → `canInterrupt` 破招（现成优先级）→ Boss 踉跄（`staggerTicksRemaining>0`）延长窗口 + 减防 → 集火倾泻。破招把窗口从「蓄招时长」延长到「蓄招 + 踉跄」，奖励主动参与。

### 3.3 满配为什么秒不了

窗口外 ×0.10 把有效 DPS 卡在「窗口频率 × 窗口时长 × 窗口内 DPS」。一发全屏秒杀不成立；秒杀被拆成「打 N 个窗口」。每个窗口内仍是爽快爆发（爽感走表现层不走数值膨胀，守 §5.4 软线）。周目进化靠收窄窗口（cadence↑ / mult↓）对满配持续加压。

### 3.4 数据模型

挂在 Boss 的 `EnemyDef` 上（yaml，新增 def 类 `BossVulnerabilityDef`）：
```yaml
vulnerability:
  outOfWindowDamageMult: 0.10   # 窗口外承伤乘子 ∈ (0, 1]；schema 校验 [0.05, 1.0]
# 需同时配 chargeSkillId（否则永不开窗 = 无解，schema fail-fast）
```
脆弱条件不落 yaml（硬编码复用 chargingSkill/stagger），窗口节奏由 `chargeSkillId` 的技能 CD 控（现成），只配一个减伤强度旋钮。

### 3.5 新增面（批次 1 收窄后）

- `lib/data/defs/boss_vulnerability_def.dart`（新 def 类，单字段 + schema 校验 [0.05,1.0]，镜像 `BossPhaseDef` 模式）。
- `EnemyDef` 加可选 `vulnerability` 字段 + yaml 解析（镜像 `guardianWard`）+ 跨字段校验（有 vulnerability 必有 chargeSkillId）。
- `BattleCharacter` 加运行时字段 `vulnerabilityMult`（double?，null=无机制）+ copyWith；`StageBattleSetup` 从 EnemyDef 灌入（镜像 `guardianWardMult` plumbing）。
- `default_ground_strategy.dart` 新增 `vulnerabilityMultOf(defender,state)`（镜像 `wardMultOf:912-923`）：目标带 vulnerabilityMult 且不脆弱（`chargingSkill==null && staggerTicksRemaining==0`）→ 返 mult，否则 1.0；与 `wardMultOf` **相乘**传进 `defenderWardMult`（:891-894），零改伤害计算器。
- **无蓄招复发新逻辑**（3.2 已明：CD 现成 governs）。
- 表现层：承伤被 ×mult 折扣时弹「刀枪不入 / 结界未破」类反馈（复用现有减伤表现），可批次 1 末轻量做或并入爬塔批。

## 4. 模块 A：多目标墙（修护法 no-op）

给护法加 **taunt 语义**：护法存活时 **Boss 从目标池排除（不可选，升级现 `damageTakenMult` 语义）**。

- 改 `battle_ai.dart` 三个目标选择器（`_pickTargetId`/`_pickFocusTargetId`/aoe 分支）：被 taunt 护法保护的 Boss 不进候选。
- 护法 `BattleCharacter` 加 `protectsBossId`（或 Boss 加 `untargetableWhileGuardedBy`）。自动 AI 本就先清低血护法 → 行为一致；额外保证手动玩家不能跳护法直捶。
- 护法全灭 → Boss 进目标池 + 脆弱窗口机制接管。floor 30 现成 `guardianWard` 配置直接受益（语义从「减伤」升「不可选」）。

**适用**：爬塔 30 宗师大 Boss。

## 5. 模块 B：限时生存（非 DPS 胜负条件）

新增胜负条件类型（挂 stage/boss，strategy 结束判定读取）：
```yaml
winCondition:
  type: survive          # 或 dealDamage
  ticks: 40              # survive: 扛过 N tick 即胜
  # dealDamage: amount + ticks（N tick 内打出 X 伤即胜）
```
- `survive` 型与 DPS 彻底脱钩（满配无法靠伤害提速）= 最纯的削秒杀。
- 触战斗结束 wiring（`BattleState.isFinished`/winner 判定 + `BattleStrategy` 结束检查）。面比模块 A 大。
- **克制用**：只给极少数关（心魔终关 / 一个隐藏 Boss），不做主模式，避免大改战斗结束语义的回归面。

## 6. 三块终局内容如何应用

| 内容 | 应用 | 保留爽感 |
|---|---|---|
| 爬塔 6 Boss | 25 绝顶 / 30 宗师标机制型（脆弱窗口）；30 叠模块 A 护法墙 | 5/10/15/20 现状不动 |
| 心魔 7 关 | 相位开窗（「克己」语义契合，相位=心魔递进）；终关可选叠模块 B 生存 | 前几关维持突破 gate 张力 |
| 终局周目 | `cycleBossPhases` 收窄窗口（cadence↑/mult↓）对满配加压 | 一周目手感不变 |

## 7. 红线修订（GDD §5.4 + CLAUDE §5.4）

新增例外条款（措辞已经用户 2026-07-03 拍板确认）：
> **标记为「机制型」的终局 Boss（爬塔 25/30、心魔终关、周目进化后）满配不可纯 DPS 秒杀，必须应对脆弱窗口 / 护法墙 / 生存条件。普通终局内容（爬塔 5-20、主线、周目一周目）秒杀爽感保留不动。**

对 2026-06-14「满配秒杀终局=有意爽感」的局部收口：从「全部终局秒杀」→「部分终局机制门」。硬红线（血量/内力/招式倍率上限）不变。实装时同步改 GDD §5.4、CLAUDE §5.4、`p1a_redline_test`/`full_build_damage_redline_test` 相关注释（若断言涉及）。

## 8. 测试策略（守 memory 三坑）

每个机制型 Boss 配诊断测（扩 `tower_boss_feel_diagnostic` / `floor30_soft_gate_diagnostic` 体例），硬断言：
1. **on-level 满配**：能赢，但 time-to-kill 跨 ≥N 个窗口（证机制真 gate，非首击秒）—— 避 `boss_phase_needs_hp`。
2. **under-gear 跨阶**：绝顶-1~2 阶低强化有可观败率（软门槛）—— 守 `boss_balance_crosstier`。
3. **自动战斗下窗口真触发**（关键，避 `ward_noop`）：断言窗口外承伤被 ×mult 折扣（非全额）、窗口按 cadence 周期性开、Boss 血量进度不摆（一直掉，不停滞）。
4. **确定性**：走 `notifier.advance` / `ProviderContainer` 永久 listener + 固定 seed（memory `battle_determinism_test_via_notifier`），非直接 `strategy.tick`。
5. schema 校验红绿双验：`outOfWindowDamageMult` 越界 / `chargeCadenceTicks` 越界 / winCondition 字段自洽启动期 fail-fast。

## 9. 实装批次（依赖序，供 writing-plans 展开）

1. **底座**（脆弱窗口）：def + schema + BattleCharacter 字段/plumbing + 伤害闸（`vulnerabilityMultOf`）+ 表现层 + 诊断测。**先证明底座在自动战斗下不 no-op**，再往下。（窗口复发用现成蓄招 CD，无新复发逻辑。）
2. **爬塔应用**：25/30 配 vulnerability；30 叠模块 A（护法墙 taunt）。诊断测 on-level/under-gear/auto。
3. **心魔应用**：相位开窗配置 + 终关模块 B（生存胜负条件）。
4. **周目应用**：`cycleBossPhases` 收窄窗口。
5. **红线修订**：GDD/CLAUDE §5.4 + 相关注释。
6. **批末全量** + 视觉验收（题字/减伤反馈真机）。

每批独立可验证、小切片 commit、更新 plan 恢复点。模块 B（改战斗结束）风险最高，可最后做且可 defer。

## 10. 风险与 defer 项

- 模块 B（限时生存）改 `isFinished`/winner 判定，回归面最大 → 可 defer 到批次 3 末或独立后续，不阻塞底座 + 爬塔。
- 自动 AI 不「刻意」在窗口爆发 → 底座已保证进度不摆，但「自动效率 < 手动」是有意（奖励参与）。若诊断发现自动效率过低致 under-gear 永败，再评估「自动 AI 感知脆弱窗口集火」增强（新 AI 分支，opt-in）。
- 护法 taunt 改目标选择器 → 须全量跑 battle 测防回归（改的是核心 AI）。
