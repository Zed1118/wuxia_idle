# 第七阶段 · 批二 · Boss 机制标准 — 设计 spec

> 2026-06-19 · brainstorm 收口 · 分支 `worktree-phase7-batch2-boss-mechanics` · opus xhigh
> 范围拍板：①多阶段 + ②弱点抗性 + ④技能书珍稀展示。**③协同窗口 Boss 单独再设计**（项目无「敌方协同」概念 + 碰红线，本批不做）。
> 主题：让 Boss 从「高血量普通敌人」变成有机制、有差异、有掌掴感的真 Boss 战。全批纯机制/表现层差异化，**不走数值膨胀**。

## Phase 0 现状（已核实，带 file:line）

- Boss 仅两个 bool：`StageDef.isBossStage`（`stage_def.dart:20`）+ `EnemyDef.isBoss`（金边显示，`:217`）。战斗状态机 `BattleState`（`battle_state.dart:505`）**无阶段/血量阈值概念**，`DefaultGroundStrategy` 循环条件只看 `isFinished`。
- 敌人内联配在 stages.yaml `enemies:` 列表，`EnemyDef.fromYaml`（`stage_def.dart:240`）。
- 蓄力机制字段齐全：`chargeSkillId/chargingSkill/chargeTicksRemaining`（`battle_state.dart:163-167`）—— ① telegraphed 反扑复用。
- 伤害唯一真相源 `DamageCalculator.calculateResolved`（`damage_calculator.dart:100`），流派克制在第④步（`:150`）。
- 技能书掉落链路**已存在**：`stage_skill_drop_hook.dart` → `SkillUnlockService.grantManual/addFragment`，但 hook 返回 void「纯数据写无 UI」，玩家战后看不到。调用点 `stage_entry_flow.dart:207` + `tower_entry_flow.dart:165`。战后仪式：`heroCamera → presentVictoryCeremony(装备treasure) → showStageVictoryDialog`（`stage_entry_flow.dart:220-239`）。
- codex 是「机制百科」非敌人图鉴（`codex_category.dart:5`，8 档机制 + lore，无敌人条目）→ ② 事后可查不建图鉴，复用 `clearedStageIds`。
- 红线测：`full_build_damage_redline_test.dart`（calculator 探针 <100万）+ `balance_simulator_test.dart`（极值×周目实战峰值 <100万）。

## ① Boss 多阶段（hp 阈值切阶段）

**Schema**：`EnemyDef` 新增 `bossPhases: List<BossPhaseDef>?`（默认 null = 旧单阶段行为，零回归）。仅大 Boss（章末 + 爬塔 major 10/20/30）配，小 Boss 不配。
```yaml
bossPhases:
  - hpThresholdPct: 1.0          # 第一阶段(满血起，必填首项)
    titleKey: bossPhase1_xxx
  - hpThresholdPct: 0.5          # 每 Boss 自配阈值数组(降序)
    unlockSkillIds: [skill_xxx]  # 解锁阶段专属招(并入该单位 availableSkills)
    aiMode: aggressive           # AI 模式(normal | aggressive | focus)
    onEnterMechanic: chargeCounter  # 一次性 telegraphed:进蓄力态下回合放阶段大招
    titleKey: bossPhase2_xxx
```
`BossPhaseDef.fromYaml` 校验：阈值降序、首项=1.0、unlockSkillIds 指向 skills.yaml 存在 id（否则 fail-fast，沿 game_repository 既有校验体例）。

**运行时**：
- `BattleCharacter` 加 `bossPhaseIndex`（默认 0，非 Boss/无 phases 恒 0）+ phase 配置引用（快照入战斗单位）。
- 转阶段检测放 `DefaultGroundStrategy` 伤害结算后（每次 Boss 受伤后判一次）：Boss 当前 hp% 跨下一阈值 → 升 phase：① `unlockSkillIds` 并入 availableSkills ② 设 aiMode ③ 触发 `onEnterMechanic`（`chargeCounter` = 复用蓄力字段，下回合放大招，玩家有反应窗口）④ actionLog 记 `BossPhaseTransition` 事件（phaseIndex + titleKey）供表现层。
- `BattleAI.decide`（`battle_ai.dart:27`）读 bossPhaseIndex/aiMode：`aggressive` 提高强力技/大招优先级，`focus` 复用 `_pickFocusTargetId` 倾向集火。

**表现层**（纯表现，不动逻辑）：battle_screen 监听 actionLog 新 `BossPhaseTransition` 事件 → 复用 2.4 `ImpactGlyphOverlay` 弹短题字（titleKey→UiStrings）+ `ScreenFlashOverlay` 短闪 + Boss 立绘抖动/变色（复用现成 `_shakeCtrl` / grayscale 通道思路）。

**红线**：无属性 buff、不调伤害公式 → §5.4 不膨胀；阶段切换只影响在场战斗，离线 offline_recap 不经此路径 → §5.5。

## ② 弱点/抗性（按流派）

**Schema**：`EnemyDef` 新增 `schoolDamageTakenMult: Map<Style,double>?`（>1=弱点 / <1=抗性，单字段合并）。默认空 = 全 ×1.0。校验：值域 [0.5, 2.0]（防越界），key 为合法 Style enum。默认推荐值 ×1.25/×0.75 由内容层在 yaml 显式写（不在代码硬编码默认乘子，只校验范围）。
**伤害**：转译到 `BattleCharacter.schoolDamageTakenMult`；`DamageCalculator.calculateResolved` 第④步流派克制后（`:154` 之后）插 `defenderSchoolMult = defender.schoolDamageTakenMult[attackerSchool] ?? 1.0`，新增可选参数默认 1.0（保现有调用零改）。
**叠乘验算**：流派克制 ×1.25 × 弱点 ×1.25 = ×1.56；极值 build 普攻 calculator 探针 ~5.8万 ×1.56 ≈ 9万，**仍远 <100万** ✅。红线测补「弱点叠乘满 build」断言。
**会心发现**（§5.7）：命中弱点（mult>1.0）时 `BattleAction` 标 `weaknessHit` → battle_screen 弹「会心」glyph（复用 ImpactGlyphOverlay 单字），伤害数字本就跳高，玩家自然悟。
**事后可查**（拍板=复用 clearedStageIds，零新持久化）：通关该 Boss（stage.id ∈ clearedStageIds）后，战前关卡信息（主线三掉落传闻区，`stage_list_screen` / `tower_floor_card`）显示该 Boss 弱点/抗性行。未通关不显（守 §5.7）。

## ④ 技能书/残页珍稀展示

**改造**：`SkillUnlockService.grantManual/addFragment` + 两个 hook 返回 `SkillDropResult`：
```dart
class SkillDropResult {
  final String? manualGranted;       // 真解首通(本次新授)
  final String? fragmentSkillId;     // 本次掉的残页招 id(null=未掉)
  final int fragmentCount;           // 掉后累计页数
  final int fragmentThreshold;       // 集齐阈值
  final bool fragmentJustUnlocked;   // 本次集齐触发解锁
}
```
**三态分层展示**（caller 拿 result 后分流）：
- **真解首通**（`manualGranted != null`）/ **残页集齐解锁**（`fragmentJustUnlocked`）→ 重仪式：新建 `skill_treasure_overlay.dart`（卷轴展开 + 招式名题字 + 复用现成心法 cover 卷轴美术），与装备 treasure 印章平行。
- **残页+1 未齐**（`fragmentSkillId != null && !fragmentJustUnlocked`）→ 轻提示：并入 victory dialog 末尾一行「得残页 XXX N/M」。
**战后仪式顺序**：`英雄镜头 → 技能珍稀(重) → 装备treasure → victory dialog(含残页轻提示)`（技能解锁是叙事高潮，排装备前）。改 `stage_entry_flow.dart:220` + `tower_entry_flow.dart:165` 两调用点。
**文案**进 UiStrings。

## 红线守卫（全批硬约束）

- §5.4：① 无属性 buff；② 乘子 ≤2.0 叠乘后 <100万（补 `full_build_damage_redline_test` 弱点叠乘断言 + `balance_simulator` Boss 路径不进百万）；不调伤害公式绝对量级。
- §5.5：阶段切换/弱点只作用在场战斗，离线 offline_recap 不触发。
- §5.6：数值进 numbers.yaml + EnemyDef yaml，中文进 UiStrings/EnumL10n。
- §5.7：弱点战中自然发现 + 事后通关后可查，不直白弹教程。
- §5.1：不碰反主流清单。
- §5.3：阶段专属招 unlockSkillIds 仍受境界锁死（敌方无玩家锁约束，但配置层不破坏玩家可学锁）。

## 任务分解（预估 ~10-12 task，subagent-driven TDD，每 task spec+quality 两阶段 review）

- **①**（4-5）：T1 `BossPhaseDef` schema + 校验 · T2 `BattleCharacter.bossPhaseIndex` + 转阶段检测状态机 · T3 telegraphed（chargeCounter 复用）+ aiMode 接 `BattleAI.decide` · T4 表现层（题字/闪光/立绘）· T5 内容（配 2-3 个大 Boss 多阶段 + numbers/UiStrings）
- **②**（3）：T6 `schoolDamageTakenMult` schema + `DamageCalculator` 插入 + BattleCharacter 转译 · T7 会心 glyph + 事后可查（战前信息行，复用 clearedStageIds）· T8 内容配置 + 红线测（弱点叠乘 + balance_simulator）
- **④**（2-3）：T9 `SkillDropResult` + service/hook 返回 · T10 `skill_treasure_overlay` + 残页轻提示 · T11 两调用点接线 + widget 测

## 视觉验收

- ① 转阶段题字/闪光静态可截，立绘抖动/变色运动单帧截不出 → 真机目检。
- ② 会心 glyph 静态可截；事后可查战前信息行静态可截。
- ④ 技能珍稀 overlay 卷轴静态可截；残页轻提示行静态可截。
- 运动/时序部分逻辑层测 + 真机 `flutter run -d macos` 打大 Boss 目检（沿批一体例）。

## 已知边界 / defer

- ③ 协同窗口 Boss → 单独 brainstorm 批（需先定「敌方协同」新概念 + 改 CLAUDE.md）。
- ② 事后可查仅「通关后」（含战败即查需 encounteredBosses 持久 set，YAGNI 不做）。
- Boss 图鉴/bestiary 子系统不建（codex 是机制百科非敌人图鉴）。
