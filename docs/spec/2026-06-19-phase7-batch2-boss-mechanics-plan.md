# 第七阶段 · 批二 · Boss 机制标准 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development（推荐）逐 task 实施。每 task spec+quality 两阶段 review。Steps 用 `- [ ]` 勾选追踪。
> spec 源：`docs/spec/2026-06-19-phase7-batch2-boss-mechanics-design.md`

**Goal:** 让 Boss 从「高血量普通敌人」变成有阶段、有弱点抗性、掉落有珍稀展示的真 Boss 战。

**Architecture:** 纯机制 + 表现层差异化，零数值膨胀。① `EnemyDef.bossPhases` hp 阈值状态机（复用现成蓄力机制做 telegraphed）；② `EnemyDef.schoolDamageTakenMult` 在 `DamageCalculator` 流派克制后插一乘子（沿 `outputMultiplier` 体例）；④ 技能掉落 hook 回传 `SkillDropResult` 驱动三态分层展示。

**Tech Stack:** Flutter Desktop / Riverpod 3 / Isar / Dart 3，纯 Dart 战斗域 + Widget 表现层，yaml 配置。

---

## 环境前置（worktree 首次跑测必做）

- [ ] 拷 `libisar.dylib`：`cp <主仓>/libisar.dylib .`（fresh worktree dylib 截断，见 memory `feedback_fresh_worktree_libisar_dylib`）
- [ ] 跑 codegen：`dart run build_runner build --delete-conflicting-outputs`（`.g.dart` gitignored）
- [ ] 基线：`flutter test 2>&1 | tail -3`（确认 2442 +1 skip 绿后再动）。analyze：`DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze`
- 每 task commit 用 `DEVELOPER_DIR=/Library/Developer/CommandLineTools git ...`；中文 commit msg 动宾结构。

## 文件结构（创建/修改清单）

**①多阶段**
- Create `lib/data/defs/boss_phase_def.dart` — `BossPhaseDef` + `BossAiMode`/`BossPhaseMechanic` enum + fromYaml 校验
- Modify `lib/data/defs/stage_def.dart:204-263` — `EnemyDef.bossPhases` 字段 + fromYaml
- Modify `lib/data/game_repository.dart` — bossPhases 校验（沿 `_enforceBossChargeRedLines` 体例）
- Modify `lib/features/battle/domain/battle_state.dart` — `BattleCharacter.bossPhaseIndex/bossPhases` + copyWith；`BattleAction.bossPhaseTransitionTo/bossPhaseTitleKey`
- Modify `lib/features/battle/domain/strategy/default_ground_strategy.dart` — 转阶段检测 hook
- Modify `lib/features/battle/domain/battle_ai.dart:27-71` — aiMode 接入
- Modify `lib/features/battle/application/stage_battle_setup.dart` — `_buildEnemyCharacter` 透传 bossPhases
- Modify `lib/features/battle/presentation/battle_screen.dart:430-1015` — 阶段事件 → glyph/flash/抖动
- Modify `data/stages.yaml` + `data/numbers.yaml` + `lib/shared/strings.dart`

**②弱点抗性**
- Modify `lib/data/defs/stage_def.dart` — `EnemyDef.schoolDamageTakenMult`
- Modify `lib/features/battle/domain/damage_calculator.dart:100-206` — `defenderSchoolDamageMult` 参数
- Modify `lib/features/battle/domain/battle_state.dart` — `BattleCharacter.schoolDamageTakenMult`；`BattleAction.weaknessHit`
- Modify damage 调用点（`default_ground_strategy.dart` 结算处）— 传入 defender 的乘子 + 标 weaknessHit
- Modify `lib/features/battle/presentation/battle_screen.dart` — 会心 glyph
- Modify 战前信息（`lib/features/loot_preview/` 或 `stage_list_screen`/`tower_floor_card`）— 通关后显弱点行
- Modify `data/stages.yaml` + `data/numbers.yaml`（值域常量）+ `lib/shared/strings.dart`
- Modify `test/balance/full_build_damage_redline_test.dart` + `test/tools/balance_simulator_test.dart`

**④技能书珍稀展示**
- Create `lib/features/cultivation/domain/skill_drop_result.dart` — `SkillDropResult`
- Modify `lib/features/cultivation/domain/skill_unlock_service.dart:29-60` — grantManual/addFragment 返回结果
- Modify `lib/features/cultivation/presentation/stage_skill_drop_hook.dart` — 两 hook 返回 `SkillDropResult`
- Create `lib/features/cultivation/presentation/skill_treasure_overlay.dart` — 卷轴重仪式
- Modify `lib/features/mainline/presentation/stage_entry_flow.dart:207-230` + `lib/features/tower/presentation/tower_entry_flow.dart:163` — 接线
- Modify victory dialog（残页轻提示行）+ `lib/shared/strings.dart`

---

# ① Boss 多阶段

## Task 1: `BossPhaseDef` schema + 校验

**Files:** Create `lib/data/defs/boss_phase_def.dart` · Test `test/data/defs/boss_phase_def_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';

void main() {
  group('BossPhaseDef.fromYaml', () {
    test('解析全字段', () {
      final p = BossPhaseDef.fromYaml({
        'hpThresholdPct': 0.5,
        'unlockSkillIds': ['skill_a'],
        'aiMode': 'aggressive',
        'onEnterMechanic': 'chargeCounter',
        'titleKey': 'bossPhase2_demo',
      });
      expect(p.hpThresholdPct, 0.5);
      expect(p.unlockSkillIds, ['skill_a']);
      expect(p.aiMode, BossAiMode.aggressive);
      expect(p.onEnterMechanic, BossPhaseMechanic.chargeCounter);
      expect(p.titleKey, 'bossPhase2_demo');
    });
    test('缺省字段默认值', () {
      final p = BossPhaseDef.fromYaml({'hpThresholdPct': 1.0});
      expect(p.unlockSkillIds, isEmpty);
      expect(p.aiMode, BossAiMode.normal);
      expect(p.onEnterMechanic, isNull);
      expect(p.titleKey, isNull);
    });
    test('parseList 阈值非降序抛 StateError', () {
      expect(
        () => BossPhaseDef.parseList([
          {'hpThresholdPct': 1.0},
          {'hpThresholdPct': 0.7},
          {'hpThresholdPct': 0.8}, // 非降序
        ]),
        throwsStateError,
      );
    });
    test('parseList 首项非 1.0 抛 StateError', () {
      expect(
        () => BossPhaseDef.parseList([{'hpThresholdPct': 0.9}]),
        throwsStateError,
      );
    });
  });
}
```

- [ ] **Step 2: 跑测确认 FAIL**：`flutter test test/data/defs/boss_phase_def_test.dart` → FAIL（boss_phase_def.dart not found）

- [ ] **Step 3: 实现**

```dart
import '../../core/domain/enums.dart';

/// 转阶段 AI 模式。normal=默认；aggressive=提高强力技/大招优先级；focus=倾向集火破绽。
enum BossAiMode { normal, aggressive, focus }

/// 转阶段一次性 telegraphed 机制。chargeCounter=进蓄力态下回合放阶段大招(复用破招蓄力)。
enum BossPhaseMechanic { chargeCounter }

/// Boss 阶段定义（第七阶段批二 ①）。EnemyDef.bossPhases 内嵌；null=单阶段旧行为。
/// 纯机制/表现切换，**不携带任何属性 buff**（守 §5.4 不数值膨胀）。
class BossPhaseDef {
  /// 进入本阶段的血量上限百分比阈值（降序，首项必为 1.0=满血起始阶段）。
  final double hpThresholdPct;
  /// 进入本阶段并入该单位 availableSkills 的招 id（敌方招，可空）。
  final List<String> unlockSkillIds;
  final BossAiMode aiMode;
  final BossPhaseMechanic? onEnterMechanic;
  /// 转阶段题字 UiStrings key（表现层用，可空=不题字）。
  final String? titleKey;

  const BossPhaseDef({
    required this.hpThresholdPct,
    this.unlockSkillIds = const [],
    this.aiMode = BossAiMode.normal,
    this.onEnterMechanic,
    this.titleKey,
  });

  factory BossPhaseDef.fromYaml(Map<String, dynamic> y) => BossPhaseDef(
        hpThresholdPct: (y['hpThresholdPct'] as num).toDouble(),
        unlockSkillIds: List<String>.from(
            (y['unlockSkillIds'] as List? ?? const []).map((e) => e as String)),
        aiMode: y['aiMode'] == null
            ? BossAiMode.normal
            : BossAiMode.values.byName(y['aiMode'] as String),
        onEnterMechanic: y['onEnterMechanic'] == null
            ? null
            : BossPhaseMechanic.values.byName(y['onEnterMechanic'] as String),
        titleKey: y['titleKey'] as String?,
      );

  /// 解析阶段数组并校验：首项阈值=1.0、阈值严格降序。
  static List<BossPhaseDef> parseList(List<dynamic> raw) {
    final list = raw
        .map((e) => BossPhaseDef.fromYaml(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (list.isEmpty) return list;
    if (list.first.hpThresholdPct != 1.0) {
      throw StateError('bossPhases 首项 hpThresholdPct 必须为 1.0(满血起始阶段)');
    }
    for (var i = 1; i < list.length; i++) {
      if (list[i].hpThresholdPct >= list[i - 1].hpThresholdPct) {
        throw StateError('bossPhases hpThresholdPct 必须严格降序');
      }
    }
    return list;
  }
}
```

- [ ] **Step 4: 跑测确认 PASS**：`flutter test test/data/defs/boss_phase_def_test.dart` → PASS

- [ ] **Step 5: Commit**：`feat(批二①): BossPhaseDef schema + 阈值降序校验`

## Task 2: `EnemyDef.bossPhases` 接入 + game_repository 校验

**Files:** Modify `stage_def.dart:204-263`、`game_repository.dart` · Test `test/data/defs/stage_def_test.dart`（追加）+ `test/data/boss_phase_redline_test.dart`

- [ ] **Step 1: 写失败测试** —— EnemyDef.fromYaml 解析 bossPhases；game_repository 校验 unlockSkillIds 必须在 skills.yaml 存在（仿 `_enforceBossChargeRedLines`）

```dart
test('EnemyDef.fromYaml 解析 bossPhases', () {
  final e = EnemyDef.fromYaml({
    'id': 'boss_x', 'name': '魔头', 'realmTier': 'erLiu', 'realmLayer': 'qiMeng',
    'school': 'gangMeng', 'baseHp': 5000, 'baseAttack': 200, 'baseSpeed': 50,
    'skillIds': ['skill_normal'], 'iconPath': 'x.png', 'isBoss': true,
    'bossPhases': [
      {'hpThresholdPct': 1.0},
      {'hpThresholdPct': 0.5, 'unlockSkillIds': ['skill_rage']},
    ],
  });
  expect(e.bossPhases, isNotNull);
  expect(e.bossPhases!.length, 2);
  expect(e.bossPhases![1].unlockSkillIds, ['skill_rage']);
});
test('bossPhases==null 向后兼容', () {
  final e = EnemyDef.fromYaml(_minimalEnemyYaml());
  expect(e.bossPhases, isNull);
});
```

- [ ] **Step 2: 跑测确认 FAIL**：`flutter test test/data/defs/stage_def_test.dart`

- [ ] **Step 3: 实现** —— EnemyDef 加 `final List<BossPhaseDef>? bossPhases;`（构造默认 null），fromYaml：

```dart
bossPhases: y['bossPhases'] == null
    ? null
    : BossPhaseDef.parseList(y['bossPhases'] as List),
```
game_repository 校验段（沿 `_enforceBossChargeRedLines` 风格，遍历所有 stage.enemyTeam）：每个 enemy.bossPhases 的 `unlockSkillIds` 必须 ∈ skills.yaml id 集合、`chargeCounter` 机制要求该 enemy 有招可蓄（其 skillIds + 各阶段 unlockSkillIds 含至少一个 charge 用招）；否则 throw StateError。

- [ ] **Step 4: 跑测确认 PASS** + `flutter test test/data/boss_phase_redline_test.dart`

- [ ] **Step 5: Commit**：`feat(批二①): EnemyDef.bossPhases + game_repository unlockSkillIds 校验`

## Task 3: `BattleCharacter.bossPhaseIndex` + 转阶段状态机

**Files:** Modify `battle_state.dart`（BattleCharacter 字段 + copyWith；BattleAction 字段）、`default_ground_strategy.dart`、`stage_battle_setup.dart` · Test `test/features/battle/boss_phase_transition_test.dart`

- [ ] **Step 1: 写失败测试** —— 构造带 2 阶段 Boss 的 `BattleState`，打到 hp 跨 50% → 下个结算后 `bossPhaseIndex` 升 1、`unlockSkillIds` 进 availableSkills、actionLog 出现 `bossPhaseTransitionTo==1`

```dart
test('Boss hp 跨阈值升阶段 + 解锁招 + 记事件', () {
  // 用 DefaultGroundStrategy 推进一个 Boss 受伤跨 50% 的确定性场景
  // 断言：transitioned.rightTeam.first.bossPhaseIndex == 1
  //      availableSkills 含 unlockSkillIds 的招
  //      actionLog.any((a) => a.bossPhaseTransitionTo == 1)
});
test('无 bossPhases 的敌人永不升阶(零回归)', () { /* bossPhaseIndex 恒 0 */ });
```

- [ ] **Step 2: 跑测确认 FAIL**

- [ ] **Step 3: 实现**
  - `BattleCharacter` 加 `final int bossPhaseIndex;`（默认 0）+ `final List<BossPhaseDef>? bossPhases;`（默认 null）+ copyWith 两参数（沿现有 `_unset` 模式 for nullable）。
  - `BattleAction` 加 `final int? bossPhaseTransitionTo;` + `final String? bossPhaseTitleKey;`（默认 null，沿 interrupted 体例）。
  - `stage_battle_setup._buildEnemyCharacter`：透传 `bossPhases: enemy.bossPhases`，`bossPhaseIndex: 0`。
  - `default_ground_strategy`：新增私有 `_checkBossPhaseTransition(BattleState s)` —— 伤害结算后调用，对每个 `bossPhases != null` 且未到末阶段的 Boss，若 `currentHp/maxHp <= bossPhases[next].hpThresholdPct` 则升阶：copyWith bossPhaseIndex+1、availableSkills 并入 unlockSkillIds 对应 SkillDef（从 GameRepository skills 查）、append 一条 `BattleAction(bossPhaseTransitionTo: next, bossPhaseTitleKey: phase.titleKey, description: ...)`。aiMode/mechanic 接入留 Task 4。

- [ ] **Step 4: 跑测确认 PASS** + 全量 `flutter test`（零回归）

- [ ] **Step 5: Commit**：`feat(批二①): BattleCharacter.bossPhaseIndex + 转阶段状态机 + 事件记录`

## Task 4: telegraphed（chargeCounter）+ aiMode 接入 `BattleAI`

**Files:** Modify `default_ground_strategy.dart`（升阶时触发 mechanic）、`battle_ai.dart:27-112` · Test `test/features/battle/boss_phase_ai_test.dart`

- [ ] **Step 1: 写失败测试**
  - `chargeCounter`：升阶时该 Boss 进入蓄力态（`chargingSkill != null`、`chargeTicksRemaining > 0`），下回合放阶段大招（复用现成蓄力字段，玩家可破招）。
  - `aiMode=aggressive`：`BattleAI.decide` 在该 Boss 强力技可用时优先于普攻（已有逻辑），断言其 `_pickSkill` 在 aggressive 下不降级到普攻（当强力技 CD/内力够）。
  - `aiMode=focus`：`decide` 优先返回破绽窗口内目标（复用 `_pickFocusTargetId`）。

- [ ] **Step 2: 跑测确认 FAIL**

- [ ] **Step 3: 实现**
  - 升阶 hook 内 `onEnterMechanic==chargeCounter` → 把该 Boss copyWith 进蓄力态（设 chargingSkill=阶段大招、chargeTicksRemaining=numbers 配的蓄力 tick）。复用现成蓄力→破招路径，不新增结算分支。
  - `BattleAI.decide`/`_pickSkill` 读 `actor.bossPhaseIndex` → 取 `actor.bossPhases?[index].aiMode`：`focus` 时把 `_pickFocusTargetId` 提到破招锁定同级优先；`aggressive` 时（当前 `_pickSkill` 已是强力优先）确保不被其他降级。**纯目标/优先级调整，不改伤害**。

- [ ] **Step 4: 跑测确认 PASS** + 全量 test

- [ ] **Step 5: Commit**：`feat(批二①): 转阶段 telegraphed 蓄力反扑 + aiMode 接 BattleAI`

## Task 5: ① 表现层（题字/闪光/立绘抖动变色）+ 内容配置

**Files:** Modify `battle_screen.dart:430-1015`（`_playAction` / 动作回放循环 :1015）、`data/stages.yaml`、`data/numbers.yaml`、`lib/shared/strings.dart` · Test `test/features/battle/boss_phase_presentation_test.dart`

- [ ] **Step 1: 写失败测试** —— widget/单元测：回放含 `bossPhaseTransitionTo!=null` 的 action 时，调用 `_impactGlyphKey` 弹题字（titleKey→UiStrings）+ `_screenFlashKey` 闪光；非转阶段 action 不触发。立绘抖动复用现成 `_shakeCtrl`（断言触发）。

- [ ] **Step 2: 跑测确认 FAIL**

- [ ] **Step 3: 实现**
  - `_playAction`（:430）或回放循环（:1015）：检测 `action.bossPhaseTransitionTo != null` → `_impactGlyphKey.currentState?.show(UiStrings.bossPhaseTitle(action.bossPhaseTitleKey))` + `_screenFlashKey.currentState?.flash(...)` + Boss 立绘 `_shakeCtrl` 抖动/变色。沿 2.4 mounted 守卫。
  - `UiStrings`：加 `bossPhaseTitle(String? key)` 映射（题字文案，如「困兽之斗」）。
  - `numbers.yaml`：加 `combat.boss_phase`（蓄力 tick、闪光时长等表现参数）。
  - `data/stages.yaml`：给 2-3 个大 Boss（章末 + 爬塔 major）配 `bossPhases`（含 unlockSkillIds 指向已存在或新增的阶段招、titleKey）。

- [ ] **Step 4: 跑测确认 PASS** + 全量 test + analyze 0

- [ ] **Step 5: Commit**：`feat(批二①): 转阶段表现层 + 大 Boss 多阶段内容配置`

---

# ② 弱点/抗性

## Task 6: `schoolDamageTakenMult` schema + DamageCalculator 插入

**Files:** Modify `stage_def.dart`（EnemyDef）、`battle_state.dart`（BattleCharacter + BattleAction.weaknessHit）、`damage_calculator.dart:100-206`、`stage_battle_setup.dart`、`numbers.yaml`（值域常量） · Test `test/features/battle/weakness_resistance_test.dart` + `test/data/defs/stage_def_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
test('弱点流派增伤 ×1.25', () {
  final base = DamageCalculator.calculateResolved(/* ...固定 rng, 无弱点 */);
  final weak = DamageCalculator.calculateResolved(/* 同参 + defenderSchoolDamageMult: 1.25 */);
  expect(weak.finalDamage, greaterThan(base.finalDamage));
  // 比例 ≈ 1.25（容忍 toInt 取整）
});
test('抗性流派减伤 ×0.75', () { /* defenderSchoolDamageMult: 0.75 → 更低 */ });
test('默认 1.0 零回归', () { /* 不传该参 → 与旧值相等 */ });
test('EnemyDef.fromYaml 解析 schoolDamageTakenMult', () {
  final e = EnemyDef.fromYaml({..., 'schoolDamageTakenMult': {'lingQiao': 1.25, 'yinRou': 0.75}});
  expect(e.schoolDamageTakenMult![TechniqueSchool.lingQiao], 1.25);
});
test('值域越界[0.5,2.0]抛 StateError', () { /* 2.5 → throw */ });
```

- [ ] **Step 2: 跑测确认 FAIL**

- [ ] **Step 3: 实现**
  - `EnemyDef` 加 `final Map<TechniqueSchool, double>? schoolDamageTakenMult;`，fromYaml 解析 `Map<String,num>` → enum key，校验值 ∈ `numbers.combat.weakness.{minMult,maxMult}`（[0.5,2.0]，进 numbers.yaml 不硬编码）。
  - `BattleCharacter` 加 `final Map<TechniqueSchool, double> schoolDamageTakenMult;`（默认 `const {}`）；`stage_battle_setup._buildEnemyCharacter` 透传 `enemy.schoolDamageTakenMult ?? const {}`。
  - `BattleAction` 加 `final bool weaknessHit;`（默认 false）。
  - `DamageCalculator.calculateResolved` 加参数 `double defenderSchoolDamageMult = 1.0`（沿 `outputMultiplier` 体例），并入 `raw` 乘式（§8 合并处 :198-206 加一项 `* defenderSchoolDamageMult`）。doc 注明默认 1.0 零回归、值由调用方从 defender 传。

- [ ] **Step 4: 跑测确认 PASS** + 全量 test

- [ ] **Step 5: Commit**：`feat(批二②): 弱点/抗性 schema + DamageCalculator 流派乘子`

## Task 7: 会心 glyph（战中发现）+ damage 调用点接线 + 事后可查

**Files:** Modify `default_ground_strategy.dart`（结算处传乘子 + 标 weaknessHit）、`battle_screen.dart`（会心 glyph）、战前信息（`lib/features/loot_preview/` 或 `stage_list_screen`/`tower_floor_card`）、`lib/shared/strings.dart` · Test `test/features/battle/weakness_hit_glyph_test.dart` + 战前信息 widget 测

- [ ] **Step 1: 写失败测试**
  - 结算：attacker 流派命中 defender 弱点（mult>1.0）→ 该 `BattleAction.weaknessHit==true`；非弱点 false。
  - 表现：回放 `weaknessHit` action → `_impactGlyphKey` 弹「会心」单字。
  - 事后可查：stage.id ∈ clearedStageIds 且该 Boss 有弱点配置 → 战前信息出现弱点行；未通关不显。

- [ ] **Step 2: 跑测确认 FAIL**

- [ ] **Step 3: 实现**
  - `default_ground_strategy` 伤害结算处：从 defender 取 `schoolDamageTakenMult[attacker.school] ?? 1.0` 传入 calculator；`>1.0` 时构造的 `BattleAction(weaknessHit: true, ...)`。
  - `battle_screen._playAction`：`action.weaknessHit` → 弹 `UiStrings.weaknessHitGlyph`（「会心」）。
  - 战前信息：在掉落传闻区（主线三 `DropRumorTable` 同层）加一个「弱点/抗性」派生行，gated on `clearedStageIds.contains(stage.id)`；文案进 UiStrings（弱点→「似惧 X 路数」、抗性→「X 路难伤」措辞，避免直白数字）。

- [ ] **Step 4: 跑测确认 PASS** + 全量 test

- [ ] **Step 5: Commit**：`feat(批二②): 会心题字 + 弱点结算接线 + 通关后战前可查`

## Task 8: ② 内容配置 + 红线测

**Files:** Modify `data/stages.yaml`（给大 Boss 配 schoolDamageTakenMult）、`test/balance/full_build_damage_redline_test.dart`、`test/tools/balance_simulator_test.dart`

- [ ] **Step 1: 写失败测试** —— 红线：满 build 极值普攻 × 流派克制 ×1.25 × 弱点 ×1.25（最坏叠乘）`< 1000000`；balance_simulator Boss 弱点路径峰值 `< 1000000`

```dart
test('弱点叠乘满 build 不进百万', () {
  final m = measureMaxBuild(defenderSchoolDamageMult: 1.25); // 最坏叠乘
  expect(m.crit, lessThan(1000000));
});
```

- [ ] **Step 2: 跑测确认**（实现前应已能跑出真实值，断言 <100万 验证设计）

- [ ] **Step 3: 实现** —— 给配了 bossPhases 的大 Boss 同步配 `schoolDamageTakenMult`（弱点 ×1.25 / 抗性 ×0.75，按 Boss 流派叙事设计：刚猛 Boss 惧阴柔等）。red-line test helper `measureMaxBuild` 加可选 `defenderSchoolDamageMult` 参数。

- [ ] **Step 4: 跑测确认 PASS** + 全量 test

- [ ] **Step 5: Commit**：`test(批二②): 弱点叠乘红线断言 + 大 Boss 弱点抗性内容`

---

# ④ 技能书/残页珍稀展示

## Task 9: `SkillDropResult` + service/hook 回传

**Files:** Create `lib/features/cultivation/domain/skill_drop_result.dart` · Modify `skill_unlock_service.dart:29-60`、`stage_skill_drop_hook.dart` · Test `test/features/cultivation/skill_drop_result_test.dart`（用 in-memory Isar，沿现有 skill_unlock_service 测体例）

- [ ] **Step 1: 写失败测试**
  - `grantManual` 首次返回 `manualGranted==skillId`；重复返回 `manualGranted==null`（幂等）。
  - `addFragment` 未集齐返回 `fragmentSkillId==id, fragmentJustUnlocked==false, fragmentCount==n`；达阈值返回 `fragmentJustUnlocked==true`。
  - 两 hook 透传该结果。

- [ ] **Step 2: 跑测确认 FAIL**

- [ ] **Step 3: 实现**

```dart
class SkillDropResult {
  final String? manualGranted;
  final String? fragmentSkillId;
  final int fragmentCount;
  final int fragmentThreshold;
  final bool fragmentJustUnlocked;
  const SkillDropResult({
    this.manualGranted, this.fragmentSkillId,
    this.fragmentCount = 0, this.fragmentThreshold = 0,
    this.fragmentJustUnlocked = false,
  });
  static const none = SkillDropResult();
  bool get isMajor => manualGranted != null || fragmentJustUnlocked;
  bool get isMinorFragment => fragmentSkillId != null && !fragmentJustUnlocked;
}
```
  - `grantManual` 返回 `Future<bool>`（是否新授，幂等查 isUnlocked 前置）；`addFragment` 返回 `Future<SkillDropResult>`（含 count/threshold/justUnlocked）。
  - `stage_skill_drop_hook` 两 hook 改返回 `Future<SkillDropResult>`，组合 manual + fragment 结果（manual 首通 + fragment 概率可同场景，按真解优先合并）。

- [ ] **Step 4: 跑测确认 PASS** + 全量 test

- [ ] **Step 5: Commit**：`feat(批二④): SkillDropResult + service/hook 回传掉落结果`

## Task 10: `skill_treasure_overlay`（重仪式）+ 残页轻提示

**Files:** Create `lib/features/cultivation/presentation/skill_treasure_overlay.dart` · Modify victory dialog（残页行）、`lib/shared/strings.dart` · Test `test/features/cultivation/skill_treasure_overlay_test.dart`

- [ ] **Step 1: 写失败测试** —— `presentSkillTreasure(context, result)`：`isMajor` 时渲染卷轴 overlay（招式名题字 + 心法 cover 图，Image.asset 带 errorBuilder 降级）；widget 测断言显示招式名 + UiStrings 文案。残页轻提示行：`isMinorFragment` 时 victory dialog 末尾出现「得残页 X N/M」。

- [ ] **Step 2: 跑测确认 FAIL**

- [ ] **Step 3: 实现** —— `skill_treasure_overlay.dart`：`Future<void> presentSkillTreasure(BuildContext, SkillDropResult)`，卷轴展开动画（AnimationController 沿英雄镜头/treasure 体例）+ 招式名（从 GameRepository skills 查 name）+ 复用心法 cover 美术路径（带 `errorBuilder` 降级，守 memory `feedback_image_asset_error_builder`）+ 点击/once-guard 自消失。文案进 UiStrings。残页轻提示并入现有 victory dialog drops 段末尾一行。

- [ ] **Step 4: 跑测确认 PASS** + 全量 test

- [ ] **Step 5: Commit**：`feat(批二④): 技能珍稀卷轴 overlay + 残页轻提示行`

## Task 11: 两调用点接线（战后仪式插入）

**Files:** Modify `stage_entry_flow.dart:207-230`、`tower_entry_flow.dart:163` · Test `test/features/mainline/stage_skill_drop_wiring_test.dart`（widget，沿批一英雄镜头接线测体例）

- [ ] **Step 1: 写失败测试** —— 主线 Boss 首通掉真解 → 仪式顺序 `英雄镜头 → presentSkillTreasure(重) → presentVictoryCeremony(装备) → victory dialog`；残页+1 → 不弹重仪式，victory dialog 含轻提示行。爬塔同理（残页路径）。

- [ ] **Step 2: 跑测确认 FAIL**

- [ ] **Step 3: 实现**
  - `stage_entry_flow`：`runStageSkillDropHookAfterVictory` 返回的 `SkillDropResult` 暂存；在 `presentHeroCamera` 之后、`presentVictoryCeremony` 之前插 `if (result.isMajor) await presentSkillTreasure(context, result);`（mounted 守卫沿现有）。残页轻提示数据传入 `showStageVictoryDialog`。
  - `tower_entry_flow`：同样接 `runTowerSkillDropHookAfterVictory` 返回值（爬塔仅残页，集齐才 isMajor），插塔层 victory 流。

- [ ] **Step 4: 跑测确认 PASS** + 全量 `flutter test` + `flutter analyze`（0）

- [ ] **Step 5: Commit**：`feat(批二④): 技能掉落战后仪式接线(英雄镜头→技能珍稀→装备)`

---

## 收尾（全 task 后）

- [ ] 全量 `flutter test`（基线 2442+1 skip，预期净增，零回归）+ `DEVELOPER_DIR=... flutter analyze`（0）
- [ ] 最终 opus 整体 review：红线 §5.4（①无 buff/②叠乘<100万）/§5.5（离线不触发）/§5.6（yaml+UiStrings）/§5.7（弱点先感受）全核
- [ ] 真机 `flutter run -d macos` 打大 Boss：验转阶段题字/闪光/立绘 + 会心 + 技能珍稀卷轴
- [ ] ff-merge main + push；PROGRESS 续27 + session 记录

## Self-Review（spec 覆盖核对）

- ① 多阶段：T1 schema / T2 EnemyDef+校验 / T3 状态机+事件 / T4 telegraphed+aiMode / T5 表现+内容 ✅
- ② 弱点抗性：T6 schema+damage / T7 会心+接线+事后可查 / T8 内容+红线测 ✅
- ④ 技能书展示：T9 result+回传 / T10 overlay+轻提示 / T11 接线 ✅
- 类型一致性：`SkillDropResult.isMajor/isMinorFragment`、`BattleAction.bossPhaseTransitionTo/weaknessHit`、`defenderSchoolDamageMult`、`BossAiMode/BossPhaseMechanic` 全 task 一致；流派枚举统一 `TechniqueSchool`（非 spec 初稿误写的 Style）✅
- 红线：T8 显式断言；T5/T7 表现层不动公式；T6 默认 1.0 零回归 ✅
