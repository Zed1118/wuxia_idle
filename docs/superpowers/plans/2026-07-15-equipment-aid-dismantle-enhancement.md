# Equipment Aid, Dismantling, and High-Level Enhancement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Build the approved duplicate/junk-equipment aid system, probabilistic crystal protection, random high-level downgrade, forging dormancy, safe batch dismantling, and realm-based enhancement cap without adding a save migration.

**Architecture:** Move probability, aid eligibility, and downgrade math into focused pure-domain files, then make EnhancementService.attempt the only atomic write path. The UI reads a query context for previews, while the service re-reads and revalidates every input in one Isar transaction. Batch disposal sends exact equipment ids from a deterministic keep-one plan so preview and execution cannot drift.

**Tech Stack:** Flutter Desktop, Dart, Riverpod 3 code generation, Isar Community, YAML configuration, flutter_test.

---

> **2026-07-15 审查订正记录**（跨计划审查 companion 拍板落地，纯计划文档，不改本轮代码）：
> ① 强化真实下限 +10→**+17**（+11~+19 不掉级、仅 +20 起掉级，+19 冲 +20 失败最多回落 +17；删 `currentLevel:10/targetLevel:20` 伪造测试，改真实下限测试）；
> ② 助炼资格/批量处置/强化目标校验接收通用 `reservedEquipmentIds`（Q5 活动占用；Phase A 冻结前默认空集，装备批可独立先行）；
> ③ 仓库强化上限 roster 计入被远征/断魂庄占用的角色（Q7）；
> ④ 真相源同步 step 增补 `AGENTS.md`（反主流红线仍 stale 列「装备分解」）。
> 逐项去向见 `2026-07-15-expedition-equipment-cross-plan-companion.md`。

## 0. Execution prerequisites and file map

Execute from an isolated worktree created with `superpowers:using-git-worktrees`, based on current `main` after this plan document is committed. Before work, verify `git merge-base --is-ancestor fab938cd HEAD`; `fab938cd` is the approved-design anchor, not the branch tip. Suggested branch: `feat/equipment-aid-enhancement`.

Do not edit generated .g.dart files by hand. Regenerate Riverpod output only after provider changes. This implementation intentionally has no Isar schema change.

### New files

- lib/features/equipment/domain/enhancement_rules.dart — success, cap, crystal cost, and downgrade math.
- lib/features/equipment/domain/enhancement_aid.dart — aid modes, eligibility, and bonuses.
- lib/features/equipment/application/enhancement_context_provider.dart — async preview context.
- test/features/equipment/domain/enhancement_rules_test.dart.
- test/features/equipment/domain/enhancement_aid_test.dart.
- test/features/equipment/application/enhancement_atomic_service_test.dart.

### Main modified files

- data/numbers.yaml and lib/data/numbers_config.dart.
- lib/features/equipment/application/enhancement_service.dart.
- lib/features/equipment/application/equipment_service_providers.dart.
- lib/features/equipment/presentation/enhance_dialog.dart.
- lib/features/equipment/presentation/forging_panel.dart.
- lib/features/battle/domain/derived_stats.dart and battle_state.dart.
- lib/features/inventory/application/inventory_organization.dart.
- lib/features/equipment/application/equipment_disposal_service.dart.
- lib/features/inventory/presentation/bulk_disposal_dialog.dart.
- lib/shared/strings.dart, GDD.md, and CLAUDE.md.

### Existing tests that must be migrated

- test/features/equipment/application/enhancement_service_test.dart
- test/features/equipment/application/enhancement_persist_test.dart
- test/features/equipment/presentation/enhance_dialog_test.dart
- test/features/equipment/presentation/forging_panel_test.dart
- test/features/equipment/application/equipment_inventory_invalidation_test.dart
- test/features/battle/domain/derived_stats_forging_aggregate_test.dart
- test/features/battle/domain/battle_character_forging_bake_test.dart
- test/features/inventory/application/inventory_organization_test.dart
- test/features/inventory/presentation/bulk_disposal_dialog_test.dart
- test/features/equipment/application/equipment_disposal_service_test.dart
- test/features/debug/application/phase2_scenarios_test.dart
- test/features/onboarding/onboarding_first_30min_battle_test.dart
- test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart
- test/tools/enhancement_material_supply_test.dart

- [ ] Run the focused baseline.

~~~bash
flutter test --no-pub   test/features/equipment/application/enhancement_service_test.dart   test/features/equipment/application/enhancement_persist_test.dart   test/features/equipment/presentation/enhance_dialog_test.dart   test/features/inventory/application/inventory_organization_test.dart   test/features/inventory/presentation/bulk_disposal_dialog_test.dart
~~~

Expected: all tests pass on fab938cd.

---

### Task 1: Replace the enhancement configuration model

**Files:**
- Modify: data/numbers.yaml:577-648 and 720-726
- Modify: lib/data/numbers_config.dart:782-977
- Test: test/features/equipment/application/enhancement_service_test.dart
- Test: test/tools/enhancement_material_supply_test.dart

- [ ] **Step 1: Write failing configuration contracts**

Replace old materialPenaltyFor, crystalCostToGuarantee, and neverDegrade assertions with:

~~~dart
test('configuration covers the approved curve', () {
  expect(cfg.successRateFor(19), 0.50);
  for (var level = 20; level <= 39; level++) {
    expect(cfg.successRateFor(level), closeTo((69 - level) / 100, 1e-9));
  }
  for (var level = 40; level <= 49; level++) {
    expect(cfg.successRateFor(level), 0.30);
  }
});

test('crystal protection starts at +20 and grows by one', () {
  expect(cfg.crystalProtectionCostFor(19), isNull);
  for (var level = 20; level <= 49; level++) {
    expect(cfg.crystalProtectionCostFor(level), level - 17);
  }
});

test('downgrade ranges and floor come from YAML', () {
  expect(cfg.downgradeRangeFor(19), isNull);
  expect(cfg.downgradeRangeFor(20), const DowngradeRange(1, 2));
  expect(cfg.downgradeRangeFor(30), const DowngradeRange(1, 3));
  expect(cfg.downgradeRangeFor(40), const DowngradeRange(1, 4));
  expect(cfg.downgradeFloorLevel, 17);
});
~~~

- [ ] **Step 2: Run RED**

~~~bash
flutter test --no-pub test/features/equipment/application/enhancement_service_test.dart
~~~

Expected: compile failure because the new config queries do not exist.

- [ ] **Step 3: Replace YAML with the approved shape**

~~~yaml
  enhancement:
    bonus_per_level: 0.05
    max_level: 49
    success_curve:
      - { level_range: [1, 10],  success_rate: 1.00 }
      - { level_range: [11, 13], success_rate: 0.90 }
      - { level_range: [14, 16], success_rate: 0.75 }
      - { level_range: [17, 19], success_rate: 0.50 }
      - { level_range: [20, 39], success_rate: null }
      - { level_range: [40, 49], success_rate: 0.30 }
    linear_success:
      level_range: [20, 39]
      start_rate: 0.49
      decrease_per_level: 0.01
      floor_rate: 0.30
    mojianshi_cost:
      - { level_range: [1, 5], cost: 1 }
      - { level_range: [6, 10], cost: 2 }
      - { level_range: [11, 13], cost: 4 }
      - { level_range: [14, 16], cost: 7 }
      - { level_range: [17, 19], cost: 12 }
      - { level_range: [20, 30], cost: 18 }
      - { level_range: [31, 49], cost: 25 }
    duancai_cost:
      - { level_range: [1, 10], cost: 0 }
      - { level_range: [11, 19], cost: 1 }
      - { level_range: [20, 30], cost: 2 }
      - { level_range: [31, 49], cost: 3 }
    aid:
      unlock_target_level: 11
      disabled_target_level: 49
      max_junk_count: 3
      same_def_bonus: 0.25
      same_tier_bonus: 0.10
      one_tier_lower_bonus: 0.06
      two_or_more_tiers_lower_bonus: 0.03
      max_bonus: 0.25
      normal_success_cap: 0.95
      late_cap:
        start_target_level: 40
        start_rate: 0.525
        decrease_per_level: 0.025
        floor_rate: 0.30
    downgrade:
      floor_level: 17
      ranges:
        - { level_range: [20, 29], min_levels: 1, max_levels: 2 }
        - { level_range: [30, 39], min_levels: 1, max_levels: 3 }
        - { level_range: [40, 49], min_levels: 1, max_levels: 4 }

  xinxue_jiejing:
    gain_per_unprotected_failure: 1
    protection:
      level_range: [20, 49]
      cost_level_offset: 17
~~~

Add keep_one_per_def_default: true under equipment.disposal.

- [ ] **Step 4: Implement typed parsing and validation**

Remove MaterialPenalty, CrystalGuaranteeBracket, the hardcoded fallback formula, and neverDegrade. Add:

~~~dart
class DowngradeRange {
  final int minLevels;
  final int maxLevels;
  const DowngradeRange(this.minLevels, this.maxLevels);

  @override
  bool operator ==(Object other) =>
      other is DowngradeRange &&
      other.minLevels == minLevels &&
      other.maxLevels == maxLevels;

  @override
  int get hashCode => Object.hash(minLevels, maxLevels);
}

class EnhancementAidConfig {
  final int unlockTargetLevel;
  final int disabledTargetLevel;
  final int maxJunkCount;
  final double sameDefBonus;
  final double sameTierBonus;
  final double oneTierLowerBonus;
  final double twoOrMoreTiersLowerBonus;
  final double maxBonus;
  final double normalSuccessCap;
  final int lateCapStartTargetLevel;
  final double lateCapStartRate;
  final double lateCapDecreasePerLevel;
  final double lateCapFloorRate;

  const EnhancementAidConfig({
    required this.unlockTargetLevel,
    required this.disabledTargetLevel,
    required this.maxJunkCount,
    required this.sameDefBonus,
    required this.sameTierBonus,
    required this.oneTierLowerBonus,
    required this.twoOrMoreTiersLowerBonus,
    required this.maxBonus,
    required this.normalSuccessCap,
    required this.lateCapStartTargetLevel,
    required this.lateCapStartRate,
    required this.lateCapDecreasePerLevel,
    required this.lateCapFloorRate,
  });
}
~~~

`EnhancementConfig` must expose these exact queries; `successRateFor` uses the parsed linear parameters rather than Dart literals:

~~~dart
int get maxLevel;
EnhancementAidConfig get aid;
int get downgradeFloorLevel;
int get crystalGainPerUnprotectedFailure;

double successRateFor(int targetLevel);
int mojianshiCostFor(int targetLevel);
int duancaiCostFor(int targetLevel);
DowngradeRange? downgradeRangeFor(int targetLevel);
int? crystalProtectionCostFor(int targetLevel);
~~~

Validate coverage gaps, overlaps, rates outside 0..1, non-positive crystal costs, invalid aid levels, and min downgrade greater than max downgrade.

- [ ] **Step 5: Update the material supply diagnostic**

Every attempt consumes full mojianshiCostFor and duancaiCostFor. Replace guarantee lookup with crystalProtectionCostFor.

- [ ] **Step 6: Run and commit**

~~~bash
flutter test --no-pub   test/features/equipment/application/enhancement_service_test.dart   test/tools/enhancement_material_supply_test.dart
git add data/numbers.yaml lib/data/numbers_config.dart   test/features/equipment/application/enhancement_service_test.dart   test/tools/enhancement_material_supply_test.dart
git commit -m "feat: 配置高段强化风险与助炼曲线"
~~~

---

### Task 2: Add pure success, protection, and downgrade rules

**Files:**
- Create: lib/features/equipment/domain/enhancement_rules.dart
- Create: test/features/equipment/domain/enhancement_rules_test.dart
- Modify: test/features/debug/application/phase2_scenarios_test.dart

- [ ] **Step 1: Write full-table and boundary tests**

Use table-driven assertions for +1 through +49 and the late caps, then deterministic `SequenceRng` values for both inclusive downgrade endpoints:

~~~dart
for (var target = 40; target <= 49; target++) {
  final expectedCap = .525 - (target - 40) * .025;
  expect(
    EnhancementRules.aidSuccessCap(target, config),
    closeTo(expectedCap < .30 ? .30 : expectedCap, 1e-9),
  );
}

test('unprotected +40 failure samples both 1 and 4 inclusively', () {
  expect(
    EnhancementRules.levelAfterFailure(
      currentLevel: 39,
      targetLevel: 40,
      protected: false,
      rng: SequenceRng(ints: [0]),
      config: config,
    ),
    38,
  );
  expect(
    EnhancementRules.levelAfterFailure(
      currentLevel: 39,
      targetLevel: 40,
      protected: false,
      rng: SequenceRng(ints: [3]),
      config: config,
    ),
    35,
  );
});

test('+17 is the real reachable floor and protection holds level', () {
  // 合法流程只有目标 +20 起才掉级：冲 +20 失败最多回落 2 级（+19 → +17），
  // 因此 +17 是真实可达下限；+10 floor 在合法状态流中不可达（详设计 §8）。
  expect(
    EnhancementRules.levelAfterFailure(
      currentLevel: 19,
      targetLevel: 20,
      protected: false,
      rng: SequenceRng(ints: [1]),
      config: config,
    ),
    17,
  );
  // +11~+19 段不掉级：冲 +19 失败维持当前等级。
  expect(
    EnhancementRules.levelAfterFailure(
      currentLevel: 18,
      targetLevel: 19,
      protected: false,
      rng: SequenceRng(),
      config: config,
    ),
    18,
  );
  // 保护时维持当前等级、不执行随机掉级。
  expect(
    EnhancementRules.levelAfterFailure(
      currentLevel: 39,
      targetLevel: 40,
      protected: true,
      rng: SequenceRng(),
      config: config,
    ),
    39,
  );
});
~~~

Define this test-local RNG so every probability and loss roll is explicit:

~~~dart
class SequenceRng implements Rng {
  SequenceRng({List<double> doubles = const [], List<int> ints = const []})
      : _doubles = List.of(doubles),
        _ints = List.of(ints);

  final List<double> _doubles;
  final List<int> _ints;

  @override
  double nextDouble() {
    if (_doubles.isEmpty) throw StateError('Unexpected nextDouble');
    return _doubles.removeAt(0);
  }

  @override
  int nextInt(int max) {
    if (_ints.isEmpty) throw StateError('Unexpected nextInt');
    final value = _ints.removeAt(0);
    if (value < 0 || value >= max) throw StateError('nextInt out of range');
    return value;
  }

  @override
  T pick<T>(List<T> list) => list[nextInt(list.length)];
}
~~~

- [ ] **Step 2: Run RED**

~~~bash
flutter test --no-pub test/features/equipment/domain/enhancement_rules_test.dart
~~~

- [ ] **Step 3: Implement the pure API**

~~~dart
class EnhancementResolution {
  final bool success;
  final int newLevel;
  final double successRate;
  final double rolledRate;
  final int levelsLost;

  const EnhancementResolution({
    required this.success,
    required this.newLevel,
    required this.successRate,
    required this.rolledRate,
    required this.levelsLost,
  });
}

abstract final class EnhancementRules {
  static double aidSuccessCap(int targetLevel, EnhancementConfig config) {
    final aid = config.aid;
    if (targetLevel < aid.lateCapStartTargetLevel) {
      return aid.normalSuccessCap;
    }
    final cap = aid.lateCapStartRate -
        (targetLevel - aid.lateCapStartTargetLevel) *
            aid.lateCapDecreasePerLevel;
    return cap < aid.lateCapFloorRate ? aid.lateCapFloorRate : cap;
  }

  static double finalSuccessRate({
    required int targetLevel,
    required double aidBonus,
    required EnhancementConfig config,
  }) {
    final raw = config.successRateFor(targetLevel) + aidBonus;
    final cap = aidSuccessCap(targetLevel, config);
    return raw > cap ? cap : raw;
  }

  static int levelAfterFailure({
    required int currentLevel,
    required int targetLevel,
    required bool protected,
    required Rng rng,
    required EnhancementConfig config,
  }) {
    if (protected) return currentLevel;
    final range = config.downgradeRangeFor(targetLevel);
    if (range == null) return currentLevel;
    final width = range.maxLevels - range.minLevels + 1;
    final loss = range.minLevels + rng.nextInt(width);
    final next = currentLevel - loss;
    return next < config.downgradeFloorLevel
        ? config.downgradeFloorLevel
        : next;
  }

  static EnhancementResolution resolve({
    required int currentLevel,
    required double aidBonus,
    required bool protected,
    required Rng rng,
    required EnhancementConfig config,
  }) {
    final targetLevel = currentLevel + 1;
    final rate = finalSuccessRate(
      targetLevel: targetLevel,
      aidBonus: aidBonus,
      config: config,
    );
    final roll = rng.nextDouble();
    if (roll < rate) {
      return EnhancementResolution(
        success: true,
        newLevel: targetLevel,
        successRate: rate,
        rolledRate: roll,
        levelsLost: 0,
      );
    }
    final newLevel = levelAfterFailure(
      currentLevel: currentLevel,
      targetLevel: targetLevel,
      protected: protected,
      rng: rng,
      config: config,
    );
    return EnhancementResolution(
      success: false,
      newLevel: newLevel,
      successRate: rate,
      rolledRate: roll,
      levelsLost: currentLevel - newLevel,
    );
  }
}
~~~

- [ ] **Step 4: Migrate debug simulations**

Replace EnhancementService.tryEnhance with EnhancementRules.resolve and update the local level from resolution.newLevel.

- [ ] **Step 5: Run and commit**

~~~bash
flutter test --no-pub   test/features/equipment/domain/enhancement_rules_test.dart   test/features/debug/application/phase2_scenarios_test.dart
git add lib/features/equipment/domain/enhancement_rules.dart   test/features/equipment/domain/enhancement_rules_test.dart   test/features/debug/application/phase2_scenarios_test.dart
git commit -m "feat: 实现强化概率与随机掉级纯规则"
~~~

---

### Task 3: Add aid eligibility and bonus rules

**Files:**
- Create: lib/features/equipment/domain/enhancement_aid.dart
- Create: test/features/equipment/domain/enhancement_aid_test.dart

- [ ] **Step 1: Write one-condition-at-a-time safety tests**

Cover same def +25; junk +10/+6/+3 capped at +25; mixed modes; more than three junk items; wrong slot; higher tier; +0 only; no battle count; no forged fields; no lock, lineage, equipped slot, personal lore, previous owner, protected source, or reservation by an active expedition/gauntlet (`reservedEquipmentIds`; an empty set until Phase A freezes the interface, so the equipment batch can ship independently first). Assert shared definition preset lore is not stored in Equipment.lores and therefore does not block a plain instance.

- [ ] **Step 2: Run RED**

~~~bash
flutter test --no-pub test/features/equipment/domain/enhancement_aid_test.dart
~~~

- [ ] **Step 3: Implement the complete evaluation API**

~~~dart
enum EnhancementAidMode { none, sameDef, junk }

enum EnhancementAidInvalidReason {
  none,
  duplicateId,
  tooMany,
  mixedModes,
  ineligible,
  wrongSlot,
  tierTooHigh,
}

class EnhancementAidEvaluation {
  final EnhancementAidMode mode;
  final EnhancementAidInvalidReason invalidReason;
  final double nominalBonus;
  final double bonus;

  const EnhancementAidEvaluation({
    required this.mode,
    required this.invalidReason,
    required this.nominalBonus,
    required this.bonus,
  });

  bool get isValid => invalidReason == EnhancementAidInvalidReason.none;
}

abstract final class EnhancementAidRules {
  static bool isCandidateEligible({
    required Equipment target,
    required Equipment candidate,
    required Set<int> equippedIds,
    required Set<int> activeFormationEquipmentIds,
    required Set<int> reservedEquipmentIds,
    required Set<String> protectedObtainedFrom,
  }) {
    return candidate.id != target.id &&
        candidate.enhanceLevel == 0 &&
        candidate.battleCount == 0 &&
        candidate.forgingSlots.every((s) =>
            !s.unlocked && s.type == null && s.specialSkillId == null) &&
        !candidate.isLocked &&
        !candidate.isLineageHeritage &&
        candidate.lores.isEmpty &&
        candidate.previousOwnerCharacterIds.isEmpty &&
        !protectedObtainedFrom.contains(candidate.obtainedFrom) &&
        !equippedIds.contains(candidate.id) &&
        !activeFormationEquipmentIds.contains(candidate.id) &&
        !reservedEquipmentIds.contains(candidate.id);
  }

  static EnhancementAidEvaluation evaluate({
    required Equipment target,
    required List<Equipment> selected,
    required Set<int> equippedIds,
    required Set<int> activeFormationEquipmentIds,
    required Set<int> reservedEquipmentIds,
    required Set<String> protectedObtainedFrom,
    required EnhancementAidConfig config,
  }) {
    if (selected.isEmpty) {
      return const EnhancementAidEvaluation(
        mode: EnhancementAidMode.none,
        invalidReason: EnhancementAidInvalidReason.none,
        nominalBonus: 0,
        bonus: 0,
      );
    }
    if (selected.map((e) => e.id).toSet().length != selected.length) {
      return _invalid(EnhancementAidInvalidReason.duplicateId);
    }
    if (selected.any((e) => !isCandidateEligible(
          target: target,
          candidate: e,
          equippedIds: equippedIds,
          activeFormationEquipmentIds: activeFormationEquipmentIds,
          reservedEquipmentIds: reservedEquipmentIds,
          protectedObtainedFrom: protectedObtainedFrom,
        ))) {
      return _invalid(EnhancementAidInvalidReason.ineligible);
    }
    final sameDef = selected.where((e) => e.defId == target.defId).toList();
    if (sameDef.isNotEmpty) {
      if (selected.length != 1) {
        return _invalid(EnhancementAidInvalidReason.mixedModes);
      }
      return EnhancementAidEvaluation(
        mode: EnhancementAidMode.sameDef,
        invalidReason: EnhancementAidInvalidReason.none,
        nominalBonus: config.sameDefBonus,
        bonus: config.sameDefBonus,
      );
    }
    if (selected.length > config.maxJunkCount) {
      return _invalid(EnhancementAidInvalidReason.tooMany);
    }
    if (selected.any((e) => e.slot != target.slot)) {
      return _invalid(EnhancementAidInvalidReason.wrongSlot);
    }
    if (selected.any((e) => e.tier.index > target.tier.index)) {
      return _invalid(EnhancementAidInvalidReason.tierTooHigh);
    }
    final nominal = selected.fold<double>(0, (sum, e) {
      final gap = target.tier.index - e.tier.index;
      return sum + (switch (gap) {
        0 => config.sameTierBonus,
        1 => config.oneTierLowerBonus,
        _ => config.twoOrMoreTiersLowerBonus,
      });
    });
    return EnhancementAidEvaluation(
      mode: EnhancementAidMode.junk,
      invalidReason: EnhancementAidInvalidReason.none,
      nominalBonus: nominal,
      bonus: nominal > config.maxBonus ? config.maxBonus : nominal,
    );
  }

  static EnhancementAidEvaluation _invalid(
    EnhancementAidInvalidReason reason,
  ) => EnhancementAidEvaluation(
    mode: EnhancementAidMode.none,
    invalidReason: reason,
    nominalBonus: 0,
    bonus: 0,
  );
}
~~~

The tests must assert both `nominalBonus` and capped `bonus`, so the UI can explain a three-item selection whose nominal sum exceeds 25 percentage points.

- [ ] **Step 4: Run and commit**

~~~bash
flutter test --no-pub test/features/equipment/domain/enhancement_aid_test.dart
git add lib/features/equipment/domain/enhancement_aid.dart   test/features/equipment/domain/enhancement_aid_test.dart
git commit -m "feat: 定义助炼装备资格与加成"
~~~

---

### Task 4: Replace split persistence with one atomic attempt

**Files:**
- Rewrite: lib/features/equipment/application/enhancement_service.dart
- Modify: lib/features/equipment/application/equipment_service_providers.dart
- Regenerate: lib/features/equipment/application/equipment_service_providers.g.dart
- Create: test/features/equipment/application/enhancement_atomic_service_test.dart
- Delete after migration: test/features/equipment/application/enhancement_persist_test.dart
- Modify: the two onboarding tests and equipment_inventory_invalidation_test.dart

- [ ] **Step 1: Write real-Isar atomic tests**

Required cases: success consumes full base materials and aid; unprotected +40 failure can lose four and gains one crystal; protected failure consumes 23 crystals and aid but loses zero and gains zero; stale aid or insufficient resource causes zero writes; +49 rejects aid; equipped cap uses wearer; warehouse cap uses active plus reserve and excludes inactive founder; old over-cap equipment stays unchanged.

- [ ] **Step 2: Run RED**

~~~bash
flutter test --no-pub test/features/equipment/application/enhancement_atomic_service_test.dart
~~~

- [ ] **Step 3: Define request and result types**

~~~dart
class EnhancementRequest {
  final int equipmentId;
  final List<int> aidEquipmentIds;
  final bool useCrystalProtection;

  const EnhancementRequest({
    required this.equipmentId,
    this.aidEquipmentIds = const [],
    this.useCrystalProtection = false,
  });
}

enum EnhanceOutcome {
  success,
  failure,
  capped,
  equipmentNotFound,
  insufficientMojianshi,
  insufficientDuancai,
  insufficientCrystal,
  protectionUnavailable,
  aidDisabled,
  aidNotFound,
  invalidAid,
}

class EnhanceResult {
  final EnhanceOutcome outcome;
  final int? oldLevel;
  final int? newLevel;
  final int? cap;
  final int mojianshiSpent;
  final int duancaiSpent;
  final int crystalsGained;
  final int crystalsSpent;
  final List<int> aidEquipmentIdsConsumed;
  final double? baseSuccessRate;
  final double? aidBonus;
  final double? finalSuccessRate;
  final double? rolledRate;
  final int levelsLost;
  final bool usedCrystalProtection;

  const EnhanceResult({
    required this.outcome,
    this.oldLevel,
    this.newLevel,
    this.cap,
    this.mojianshiSpent = 0,
    this.duancaiSpent = 0,
    this.crystalsGained = 0,
    this.crystalsSpent = 0,
    this.aidEquipmentIdsConsumed = const [],
    this.baseSuccessRate,
    this.aidBonus,
    this.finalSuccessRate,
    this.rolledRate,
    this.levelsLost = 0,
    this.usedCrystalProtection = false,
  });
}
~~~

- [ ] **Step 4: Implement transaction-local cap resolution**

Find the wearer by Character equipped slot reference, never by ownerCharacterId alone. For warehouse equipment, current roster is SaveData.activeCharacterIds plus characters satisfying isAlive && !isActive && !isFounder. Clamp to config.maxLevel. This excludes an inactive historical founder while retaining active members and reserves. Characters occupied by an expedition or gauntlet stay in these lists (occupancy never mutates activeCharacterIds), so they still count toward the warehouse enhancement cap baseline (Q7).

- [ ] **Step 5: Implement EnhancementService.attempt**

The constructor accepts `Isar`, `EnhancementConfig`, and `EquipmentProtectionPolicy`. Keep `Rng` on the call so tests control both probability and downgrade rolls:

~~~dart
Future<EnhanceResult> attempt(
  EnhancementRequest request, {
  required Rng rng,
});
~~~

Inside one `writeTxn`, in this order:

1. read target, characters, save, and cap;
2. reject cap; reject any aid below `aid.unlockTargetLevel` or at `aid.disabledTargetLevel`; reject missing/invalid aid; reject unavailable protection; reject insufficient inventory;
3. resolve probability and downgrade with EnhancementRules;
4. deduct full mojianshi and duancai;
5. deduct protection crystals when selected;
6. add one crystal only on unprotected failure;
7. delete every aid instance on both success and failure;
8. write the new target level on success or downgrade;
9. advance tutorial only when a success reaches +10;
10. return a fully populated EnhanceResult.

Do not retain tryEnhance, useCrystalToGuarantee, or persistResult as production paths.

Only load or require an inventory row when that resource participates in the attempt. In particular, +1–10 attempts must not fail merely because no duancai or crystal row exists. A crystal row is required only when protection spends crystals or an unprotected failure awards one; create the row transaction-locally for the latter when absent. Every guard return occurs before the first mutation.

- [ ] **Step 6: Inject config and regenerate Riverpod**

~~~dart
return isarInstance == null
    ? null
    : EnhancementService(
        isar: isarInstance,
        config: ref.watch(numbersConfigProvider).enhancement,
        protectionPolicy: defaultEquipmentProtectionPolicy(),
      );
~~~

~~~bash
dart run build_runner build --delete-conflicting-outputs
~~~

Expected: Riverpod generated output changes; no Isar schema output changes.

- [ ] **Step 7: Migrate callers and tests**

Onboarding tests seed all three inventory rows and call attempt. Debug-only probability tests use EnhancementRules. Delete enhancement_persist_test.dart only after every atomic case is present in enhancement_atomic_service_test.dart.

- [ ] **Step 8: Run and commit**

~~~bash
flutter test --no-pub   test/features/equipment/application/enhancement_atomic_service_test.dart   test/features/equipment/application/enhancement_service_test.dart   test/features/onboarding/onboarding_first_30min_battle_test.dart   test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart   test/features/equipment/application/equipment_inventory_invalidation_test.dart
git add \
  lib/features/equipment/application/enhancement_service.dart \
  lib/features/equipment/application/equipment_service_providers.dart \
  lib/features/equipment/application/equipment_service_providers.g.dart \
  test/features/equipment/application/enhancement_atomic_service_test.dart \
  test/features/equipment/application/enhancement_service_test.dart \
  test/features/equipment/application/equipment_inventory_invalidation_test.dart \
  test/features/equipment/application/enhancement_persist_test.dart \
  test/features/onboarding/onboarding_first_30min_battle_test.dart \
  test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart
git commit -m "feat: 原子结算强化助炼与结晶保护"
~~~

---

### Task 5: Make forged slots dormant below thresholds

**Files:**
- Create: lib/features/equipment/domain/forging_slot_activity.dart
- Modify: lib/features/battle/domain/derived_stats.dart:217-257
- Modify: lib/features/battle/domain/battle_state.dart:473-487
- Modify: lib/features/equipment/presentation/forging_panel.dart:237-273
- Modify: lib/shared/strings.dart
- Test: three existing forging tests

- [ ] **Step 1: Add failing dormancy tests**

A forged attack slot below +10 contributes no forging bonus but keeps `unlocked == true`; it reactivates at +10. A forged special skill is absent below +19 and returns at +19. The panel shows retained type plus `forgingDormantHint`:

~~~dart
test('forged attack slot sleeps below threshold and reactivates', () {
  final eq = forgedEquipment(level: 9, slotIndex: 1, bonus: 20);
  expect(DerivedStats.effectiveEquipmentAttack(eq, numbers), eq.baseAttack);
  expect(eq.forgingSlots.first.unlocked, isTrue);
  eq.enhanceLevel = 10;
  expect(
    DerivedStats.effectiveEquipmentAttack(eq, numbers),
    (eq.baseAttack * 1.5 * 1.2).toInt(),
  );
});

test('special skill sleeps below +19 and returns at +19', () {
  expect(skillIdsFor(forgedSpecialSkillEquipment(level: 18)),
      isNot(contains('forged_skill')));
  expect(skillIdsFor(forgedSpecialSkillEquipment(level: 19)),
      contains('forged_skill'));
});
~~~

- [ ] **Step 2: Run RED**

~~~bash
flutter test --no-pub   test/features/battle/domain/derived_stats_forging_aggregate_test.dart   test/features/battle/domain/battle_character_forging_bake_test.dart   test/features/equipment/presentation/forging_panel_test.dart
~~~

- [ ] **Step 3: Add one shared predicate**

~~~dart
bool isForgingSlotActive(
  Equipment equipment,
  ForgingSlot slot,
  NumbersConfig numbers,
) {
  if (!slot.unlocked) return false;
  final threshold =
      numbers.forging.slotByIndex(slot.slotIndex).unlockAtEnhanceLevel;
  return equipment.enhanceLevel >= threshold;
}
~~~

Import this file from both battle domain files. Pass `NumbersConfig` into `_forgingBonusPct` and `forgingAggregatePct`, migrate every caller, and apply the predicate to single-item attack/speed bonuses, aggregate pierce/lifesteal, and `battle_state` special-skill baking.

- [ ] **Step 4: Render a dormant state**

In ForgingPanel, forged && !thresholdReached must be checked before forged. _DormantBody shows the retained type or skill plus UiStrings.forgingDormantHint, and exposes no forge action.

- [ ] **Step 5: Run and commit**

~~~bash
flutter test --no-pub   test/features/battle/domain/derived_stats_forging_aggregate_test.dart   test/features/battle/domain/battle_character_forging_bake_test.dart   test/features/equipment/presentation/forging_panel_test.dart
git add \
  lib/features/equipment/domain/forging_slot_activity.dart \
  lib/features/battle/domain/derived_stats.dart \
  lib/features/battle/domain/battle_state.dart \
  lib/features/equipment/presentation/forging_panel.dart \
  lib/shared/strings.dart \
  test/features/battle/domain/derived_stats_forging_aggregate_test.dart \
  test/features/battle/domain/battle_character_forging_bake_test.dart \
  test/features/equipment/presentation/forging_panel_test.dart
git commit -m "feat: 强化掉级后休眠开锋词条"
~~~

---

### Task 6: Provide enhancement preview context

**Files:**
- Create: lib/features/equipment/application/enhancement_context_provider.dart
- Generate: enhancement_context_provider.g.dart
- Modify: enhancement_service.dart
- Test: enhancement_atomic_service_test.dart

- [ ] **Step 1: Add a failing context test**

loadContext returns the same cap as attempt, separates same-def and junk candidates, excludes every cultivated/protected item, and returns no aid candidates at target +49.

- [ ] **Step 2: Add immutable context**

~~~dart
class EnhancementContext {
  final int cap;
  final int targetLevel;
  final List<Equipment> sameDefCandidates;
  final List<Equipment> junkCandidates;

  const EnhancementContext({
    required this.cap,
    required this.targetLevel,
    required this.sameDefCandidates,
    required this.junkCandidates,
  });
}
~~~

loadContext is read-only and reuses cap and aid rules. Sort candidates by tier descending, defId, then id ascending.

- [ ] **Step 3: Add the provider family**

~~~dart
@riverpod
Future<EnhancementContext> enhancementContext(
  Ref ref,
  int equipmentId,
) async {
  final service = ref.watch(enhancementServiceProvider);
  if (service == null) {
    throw StateError('Isar not initialized for enhancement context');
  }
  return service.loadContext(equipmentId);
}
~~~

- [ ] **Step 4: Generate, test, and commit**

~~~bash
dart run build_runner build --delete-conflicting-outputs
flutter test --no-pub   test/features/equipment/application/enhancement_atomic_service_test.dart
git add lib/features/equipment/application   test/features/equipment/application/enhancement_atomic_service_test.dart
git commit -m "feat: 提供强化上限与助炼候选上下文"
~~~

---

### Task 7: Redesign the enhancement interaction

**Files:**
- Modify: lib/features/equipment/presentation/enhance_dialog.dart
- Modify: equipment_inventory_invalidation.dart
- Modify: lib/shared/strings.dart
- Test: enhance_dialog_test.dart

- [ ] **Step 1: Write interaction tests**

Assert separate base/aid/cap/final rates, mutually exclusive modes, selected aid names and “成败均消耗”, exact crystal cost, random loss preview, protected failure preview, +49 disabled aid, confirmation at +20+, confirmation at +11–19 only when aid is used, and result text for lost levels/protected failure.

Preserve fast widget tests without opening Isar by adding two narrow constructor seams. Production callers omit both:

~~~dart
typedef EnhancementAttemptOverride = Future<EnhanceResult> Function(
  EnhancementRequest request,
  Rng rng,
);

final EnhancementContext? contextOverride;
final EnhancementAttemptOverride? attemptOverride;
~~~

Each submit test supplies a fixed context, a `_StubRng`, and an override that records the exact request and returns a chosen result. Keep real transaction behavior exclusively in `enhancement_atomic_service_test.dart`.

- [ ] **Step 2: Run RED**

~~~bash
flutter test --no-pub test/features/equipment/presentation/enhance_dialog_test.dart
~~~

- [ ] **Step 3: Replace local state and submit path**

~~~dart
EnhancementAidMode _aidMode = EnhancementAidMode.none;
final Set<int> _selectedAidIds = {};
bool _useCrystalProtection = false;
bool _busy = false;
EnhanceResult? _lastResult;
~~~

Use `widget.contextOverride` when non-null; otherwise watch `enhancementContextProvider(widget.equipment.id)`. Derive selected instances and evaluate their effective bonus. Replace separate normal/guarantee buttons with one submit method. It obtains `rngProvider`, calls `attemptOverride(request, rng)` in tests or `service.attempt(request, rng: rng)` in production, updates `widget.equipment.enhanceLevel` from `result.newLevel!` only for success/failure outcomes, clears only ids reported in `aidEquipmentIdsConsumed`, invalidates inventory and context, and prevents duplicate clicks.

- [ ] **Step 4: Add focused widgets**

Create private _SuccessBreakdown, _AidSelector, _CrystalProtectionToggle, _FailureRiskLine, and _AttemptCostSummary widgets. The PaperDialog confirmation lists exact materials, crystal cost, aid names, final rate, and failure result. Do not add a “do not show again” option.

- [ ] **Step 5: Centralize guard copy**

Add UiStrings.enhanceOutcomeMessage(EnhanceOutcome). No Chinese literals belong in enhance_dialog.dart. A guard result keeps selection, refreshes providers, and shows the reason.

- [ ] **Step 6: Run and commit**

~~~bash
flutter test --no-pub   test/features/equipment/presentation/enhance_dialog_test.dart   test/features/equipment/application/equipment_inventory_invalidation_test.dart
git add lib/features/equipment/presentation/enhance_dialog.dart   lib/features/equipment/application/equipment_inventory_invalidation.dart   lib/shared/strings.dart   test/features/equipment/presentation/enhance_dialog_test.dart   test/features/equipment/application/equipment_inventory_invalidation_test.dart
git commit -m "feat: 接入助炼与结晶保护强化界面"
~~~

---

### Task 8: Build deterministic keep-one plans and exact-id batch transactions

**Files:**
- Modify: lib/features/equipment/domain/equipment_disposal.dart
- Modify: lib/features/inventory/application/inventory_organization.dart
- Modify: lib/features/equipment/application/equipment_disposal_service.dart
- Test: inventory_organization_test.dart and equipment_disposal_service_test.dart

- [ ] **Step 1: Add failing keep-one and stale-selection tests**

A protected same-def copy satisfies keep-one. Without one, retain by enhancement, forged-slot count, battleCount, base stat sum, earlier obtainedAt, then smaller id. If any exact selected id becomes missing or protected before execution, expect staleSelection with zero deletion and zero reward.

- [ ] **Step 2: Run RED**

~~~bash
flutter test --no-pub   test/features/inventory/application/inventory_organization_test.dart   test/features/equipment/application/equipment_disposal_service_test.dart
~~~

- [ ] **Step 3: Extend config and plan**

EquipmentDisposalConfig gains keepOnePerDefDefault, default true in direct test constructors and parsed from YAML.

~~~dart
class BulkDisposalPlan {
  final Map<EquipmentTier, List<Equipment>> _byTier;
  final List<EquipmentTier> tiers;
  final Set<int> candidateIds;
  final Set<int> retainedIds;
  final Set<int> protectedIds;

  const BulkDisposalPlan._({
    required Map<EquipmentTier, List<Equipment>> byTier,
    required this.tiers,
    required this.candidateIds,
    required this.retainedIds,
    required this.protectedIds,
  }) : _byTier = byTier;

  List<Equipment> itemsFor(EquipmentTier tier) =>
      List.unmodifiable(_byTier[tier] ?? const []);

  bool get isEmpty => tiers.isEmpty;
}
~~~

`buildBulkDisposalPlan` gains `required bool keepOnePerDef`. First classify every instance as protected or freely disposable, then group by `defId`. A protected instance satisfies keep-one for its whole group. Otherwise retain exactly the first free instance under this comparator and make every remaining free instance a candidate:

~~~dart
int compareKeepPriority(Equipment a, Equipment b) {
  var result = b.enhanceLevel.compareTo(a.enhanceLevel);
  if (result != 0) return result;
  final aForged = a.forgingSlots.where((s) => s.unlocked).length;
  final bForged = b.forgingSlots.where((s) => s.unlocked).length;
  result = bForged.compareTo(aForged);
  if (result != 0) return result;
  result = b.battleCount.compareTo(a.battleCount);
  if (result != 0) return result;
  final aBase = a.baseAttack + a.baseHealth + a.baseSpeed;
  final bBase = b.baseAttack + b.baseHealth + b.baseSpeed;
  result = bBase.compareTo(aBase);
  if (result != 0) return result;
  result = a.obtainedAt.compareTo(b.obtainedAt);
  if (result != 0) return result;
  return a.id.compareTo(b.id);
}
~~~

When `keepOnePerDef` is false, all free instances are candidates and `retainedIds` is empty. `protectedIds` always remains non-selectable. Sort candidate rows with the existing inventory sort only after keep priority has chosen the retained instance.

- [ ] **Step 4: Replace tier-wide APIs**

~~~dart
enum BulkDisposalStatus { success, staleSelection }

class BulkDisposalResult {
  final BulkDisposalStatus status;
  final int count;
  final int totalSilver;
  final int totalMojianshi;
  final int totalXinxuejiejing;

  const BulkDisposalResult({
    required this.status,
    this.count = 0,
    this.totalSilver = 0,
    this.totalMojianshi = 0,
    this.totalXinxuejiejing = 0,
  });
}
~~~

Implement these exact signatures:

~~~dart
Future<BulkDisposalResult> sellBatch(Set<int> equipmentIds);
Future<BulkDisposalResult> disassembleBatch(Set<int> equipmentIds);
~~~

In one `writeTxn`, reject an empty set as a successful zero-result no-op; load every id; recompute equipped/current-formation/protection state; and return `staleSelection` before any deletion if the loaded count differs or any instance is protected. Only after the complete validation pass, calculate rewards from those exact instances, update inventory rows, and delete those ids. Delete `sellAllOfTier`/`disassembleAllOfTier` after callers migrate.

- [ ] **Step 5: Run and commit**

~~~bash
flutter test --no-pub   test/features/inventory/application/inventory_organization_test.dart   test/features/equipment/application/equipment_disposal_service_test.dart
git add \
  lib/features/equipment/domain/equipment_disposal.dart \
  lib/features/inventory/application/inventory_organization.dart \
  lib/features/equipment/application/equipment_disposal_service.dart \
  test/features/inventory/application/inventory_organization_test.dart \
  test/features/equipment/application/equipment_disposal_service_test.dart
git commit -m "feat: 批量整理默认保留同名装备"
~~~

---

### Task 9: Add batch dismantling and checklist previews

**Files:**
- Modify: bulk_disposal_dialog.dart
- Modify: lib/shared/strings.dart
- Test: bulk_disposal_dialog_test.dart

- [ ] **Step 1: Replace the obsolete no-dismantle test**

Assert sale and dismantle actions, keep-one enabled by default, retained rows shown but not selectable, candidate checkboxes only remove candidates, and exact selected totals.

- [ ] **Step 2: Run RED**

~~~bash
flutter test --no-pub   test/features/inventory/presentation/bulk_disposal_dialog_test.dart
~~~

- [ ] **Step 3: Convert to stateful selection**

Use ConsumerStatefulWidget with:

~~~dart
bool _keepOnePerDef = true;
final Set<int> _deselectedIds = {};
~~~

Rebuild the pure plan from provider data. Protected and retained rows are explanatory only. Candidate state is selected unless its id is in _deselectedIds.

- [ ] **Step 4: Add exact sale and dismantle handlers**

Both handlers derive exact selected ids and call sellBatch or disassembleBatch. Confirmation lists instance name/level and totals. staleSelection refreshes providers, keeps the dialog open, and shows UiStrings.bulkSelectionChanged.

- [ ] **Step 5: Run and commit**

~~~bash
flutter test --no-pub   test/features/inventory/presentation/bulk_disposal_dialog_test.dart
git add lib/features/inventory/presentation/bulk_disposal_dialog.dart   lib/shared/strings.dart   test/features/inventory/presentation/bulk_disposal_dialog_test.dart
git commit -m "feat: 增加安全批量分解清单"
~~~

---

### Task 10: Synchronize truth sources and perform completion verification

**Files:**
- Modify: GDD.md:60-72 and 414-443 (verify line anchors before editing; they may have drifted)
- Modify: CLAUDE.md version summary and section 5.1
- Modify: AGENTS.md anti-mainstream redline (still stale-lists 装备分解, retired 2026-06-26; also carries old no-downgrade wording)
- Modify: approved design spec status

- [ ] **Step 1: Update GDD**

Record the dated reversal. Replace old success, no-downgrade, and direct-guarantee text with the complete approved curve, aid use/consumption, random ranges, +17 real reachable floor (downgrade only from +20, so +19→+17 is the true lower bound; +10 is unreachable in a legal flow), no decade checkpoints, linear crystal protection, and forging dormancy.

- [ ] **Step 2: Update CLAUDE**

Add a 2026-07-15 version summary. Remove enhancement downgrade from the forbidden list and document YAML ownership plus atomic write requirements.

- [ ] **Step 3: Mark the design implemented only after verification**

Do not change the spec status before all commands below pass.

- [ ] **Step 4: Search for stale APIs and language**

~~~bash
rg -n "tryEnhance|useCrystalToGuarantee|neverDegrade|never_degrade|materialPenaltyFor|guaranteed_success_costs" lib test data
rg -n "直接成功|永不破防降级|不会破防降级" GDD.md CLAUDE.md AGENTS.md
rg -n "装备分解" AGENTS.md   # 反主流清单不应再正列（2026-06-26 已推翻），仅允许带日期的退役 changelog 句
~~~

Expected: the API search has no references. The documentation search has no active normative statement retaining the old behavior; a dated changelog sentence that explicitly says the rule was retired is acceptable. Do not rewrite `docs/_archive`.

- [ ] **Step 5: Format and run targeted tests**

~~~bash
git diff fab938cd --name-only --diff-filter=ACM -- '*.dart' | xargs dart format
flutter test --no-pub   test/features/equipment/domain/enhancement_rules_test.dart   test/features/equipment/domain/enhancement_aid_test.dart   test/features/equipment/application/enhancement_atomic_service_test.dart   test/features/equipment/application/enhancement_service_test.dart   test/features/equipment/presentation/enhance_dialog_test.dart   test/features/equipment/presentation/forging_panel_test.dart   test/features/battle/domain/derived_stats_forging_aggregate_test.dart   test/features/battle/domain/battle_character_forging_bake_test.dart   test/features/inventory/application/inventory_organization_test.dart   test/features/inventory/presentation/bulk_disposal_dialog_test.dart   test/features/equipment/application/equipment_disposal_service_test.dart   test/tools/enhancement_material_supply_test.dart
~~~

- [ ] **Step 6: Run one completion-level gate**

~~~bash
flutter analyze
flutter test --no-pub
git diff --check
git status --short
~~~

Expected: no analysis issues, zero test failures, no whitespace errors, and only intended final docs before commit.

- [ ] **Step 7: Perform one macOS interaction pass**

~~~bash
flutter run -d macos
~~~

Verify once: unprotected +20 loss and crystal gain; protected failure cost/no loss; aid deletion on both outcomes; late cap and +49 disable; forging dormancy/reactivation; batch keep-one and reward preview.

- [ ] **Step 8: Final ready commit**

~~~bash
git add GDD.md CLAUDE.md   docs/superpowers/specs/2026-07-15-equipment-aid-dismantle-enhancement-design.md
git commit -m "[READY] docs: 同步装备强化风险设计真相源"
git status --short
~~~

Expected: clean task worktree. Report unrelated pre-existing files without staging them.

## Handoff boundary

This plan is for Claude Code execution. Codex must not execute implementation tasks unless the user explicitly changes that assignment. Claude should use superpowers:executing-plans in the isolated worktree, stop on any failed red/green expectation, and preserve the small commits above for recovery.
