import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/services/enhancement_service.dart';
import 'package:wuxia_idle/utils/rng.dart';

/// T20 EnhancementService 验收（phase2_tasks T20 §187-219）。
void main() {
  late EnhancementConfig cfg;

  setUpAll(() async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    cfg = repo.numbers.enhancement;
  });

  Equipment newEq({int enhanceLevel = 0}) => Equipment.create(
        defId: 'test',
        tier: EquipmentTier.haoJiaHuo,
        slot: EquipmentSlot.weapon,
        baseAttack: 100,
        baseHealth: 0,
        baseSpeed: 10,
        enhanceLevel: enhanceLevel,
        obtainedAt: DateTime(2026, 5, 11),
        obtainedFrom: 'test',
      );

  /// 注入式 rng：`nextDouble` 永远返回固定值 [fixed]。
  /// 测试时用 0.0 强制成功 / 0.999 强制失败。
  Rng rngFixed(double fixed) => _FixedRng(fixed);

  // ────────────────────────────────────────────────────────────────────────────
  // EnhancementConfig 查询表（10 个用例）
  // ────────────────────────────────────────────────────────────────────────────

  group('EnhancementConfig 查询表', () {
    test('successRateFor 4 段静态 + +20-49 公式段', () {
      // +1-10 段 100% 成功
      expect(cfg.successRateFor(1), 1.0);
      expect(cfg.successRateFor(10), 1.0);
      // +11-13 段 90%
      expect(cfg.successRateFor(11), 0.90);
      expect(cfg.successRateFor(13), 0.90);
      // +14-16 段 75%
      expect(cfg.successRateFor(15), 0.75);
      // +17-19 段 50%
      expect(cfg.successRateFor(18), 0.50);
      // +20-49 段公式 max(0.30, 0.50 - 0.02 × (level - 19))
      expect(cfg.successRateFor(20), closeTo(0.48, 0.001));
      expect(cfg.successRateFor(25), closeTo(0.38, 0.001));
      expect(cfg.successRateFor(29), closeTo(0.30, 0.001)); // 0.50 - 0.20 = 0.30
      expect(cfg.successRateFor(35), 0.30); // floor 0.30
      expect(cfg.successRateFor(49), 0.30);
    });

    test('mojianshiCostFor 7 段曲线', () {
      expect(cfg.mojianshiCostFor(1), 1);
      expect(cfg.mojianshiCostFor(5), 1);
      expect(cfg.mojianshiCostFor(6), 2);
      expect(cfg.mojianshiCostFor(10), 2);
      expect(cfg.mojianshiCostFor(12), 4);
      expect(cfg.mojianshiCostFor(15), 7);
      expect(cfg.mojianshiCostFor(18), 12);
      expect(cfg.mojianshiCostFor(25), 18);
      expect(cfg.mojianshiCostFor(35), 25);
      expect(cfg.mojianshiCostFor(49), 25);
    });

    test('crystalCostToGuarantee：+1-13 段无保底，+14/17/20 段三档', () {
      expect(cfg.crystalCostToGuarantee(1), isNull);
      expect(cfg.crystalCostToGuarantee(13), isNull);
      expect(cfg.crystalCostToGuarantee(14), 3);
      expect(cfg.crystalCostToGuarantee(16), 3);
      expect(cfg.crystalCostToGuarantee(17), 5);
      expect(cfg.crystalCostToGuarantee(19), 5);
      expect(cfg.crystalCostToGuarantee(20), 8);
      expect(cfg.crystalCostToGuarantee(49), 8);
    });

    test('materialPenaltyFor：+1-10 none / +11-13 half / +14+ full', () {
      expect(cfg.materialPenaltyFor(5), MaterialPenalty.none);
      expect(cfg.materialPenaltyFor(12), MaterialPenalty.half);
      expect(cfg.materialPenaltyFor(15), MaterialPenalty.full);
      expect(cfg.materialPenaltyFor(18), MaterialPenalty.full);
      expect(cfg.materialPenaltyFor(25), MaterialPenalty.full);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // tryEnhance 行为
  // ────────────────────────────────────────────────────────────────────────────

  group('tryEnhance', () {
    test('+1 段必成（rng=0.999 也成）', () {
      final eq = newEq(enhanceLevel: 0);
      final r = EnhancementService.tryEnhance(
        eq: eq,
        characterAbsoluteLevel: 14,
        rng: rngFixed(0.999),
        currentMojianshi: 100,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.success);
      expect(eq.enhanceLevel, 1);
      expect(r.mojianshiSpent, 1);
      expect(r.crystalsGained, 0);
      expect(r.successRate, 1.0);
    });

    test('+12 段 roll=0.85 成功，扣磨剑石 4', () {
      final eq = newEq(enhanceLevel: 11);
      final r = EnhancementService.tryEnhance(
        eq: eq,
        characterAbsoluteLevel: 14,
        rng: rngFixed(0.85),
        currentMojianshi: 100,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.success);
      expect(eq.enhanceLevel, 12);
      expect(r.mojianshiSpent, 4);
      expect(r.successRate, 0.90);
    });

    test('+12 段 roll=0.95 失败：penalty=half → 扣 2，结晶 +1，等级不变', () {
      final eq = newEq(enhanceLevel: 11);
      final r = EnhancementService.tryEnhance(
        eq: eq,
        characterAbsoluteLevel: 14,
        rng: rngFixed(0.95),
        currentMojianshi: 100,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.failure);
      expect(eq.enhanceLevel, 11); // 永不破防降级
      expect(r.mojianshiSpent, 2); // half of 4
      expect(r.crystalsGained, 1);
    });

    test('+15 段 roll=0.99 失败：penalty=full → 扣 7，结晶 +1', () {
      final eq = newEq(enhanceLevel: 14);
      final r = EnhancementService.tryEnhance(
        eq: eq,
        characterAbsoluteLevel: 19,
        rng: rngFixed(0.99),
        currentMojianshi: 100,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.failure);
      expect(eq.enhanceLevel, 14);
      expect(r.mojianshiSpent, 7); // full of 7
      expect(r.crystalsGained, 1);
    });

    test('+20 段公式 0.48：roll=0.40 成功', () {
      final eq = newEq(enhanceLevel: 19);
      final r = EnhancementService.tryEnhance(
        eq: eq,
        characterAbsoluteLevel: 30,
        rng: rngFixed(0.40),
        currentMojianshi: 100,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.success);
      expect(eq.enhanceLevel, 20);
      expect(r.successRate, closeTo(0.48, 0.001));
    });

    test('capped：角色 absoluteLevel=10，eq=+10 → outcome=capped，不扣材料', () {
      final eq = newEq(enhanceLevel: 10);
      final r = EnhancementService.tryEnhance(
        eq: eq,
        characterAbsoluteLevel: 10,
        rng: rngFixed(0.0),
        currentMojianshi: 100,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.capped);
      expect(eq.enhanceLevel, 10);
      expect(r.mojianshiSpent, 0);
    });

    test('capped：eq=+49（绝对上限）→ capped 即使角色满级', () {
      final eq = newEq(enhanceLevel: 49);
      final r = EnhancementService.tryEnhance(
        eq: eq,
        characterAbsoluteLevel: 49,
        rng: rngFixed(0.0),
        currentMojianshi: 100,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.capped);
    });

    test('insufficientMojianshi：磨剑石 0 → 不扣不变 outcome=insufficient', () {
      final eq = newEq(enhanceLevel: 11);
      final r = EnhancementService.tryEnhance(
        eq: eq,
        characterAbsoluteLevel: 14,
        rng: rngFixed(0.0),
        currentMojianshi: 0,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.insufficientMojianshi);
      expect(eq.enhanceLevel, 11);
      expect(r.mojianshiSpent, 0);
    });

    test('蒙特卡洛 1000 次 +12（90%），实际成功率落 [85%, 95%]', () {
      final rng = DefaultRng(seed: 42);
      var successCount = 0;
      for (var i = 0; i < 1000; i++) {
        final eq = newEq(enhanceLevel: 11);
        final r = EnhancementService.tryEnhance(
          eq: eq,
          characterAbsoluteLevel: 14,
          rng: rng,
          currentMojianshi: 100,
          config: cfg,
        );
        if (r.outcome == EnhanceOutcome.success) successCount++;
      }
      expect(successCount, inInclusiveRange(850, 950),
          reason: '90% 期望 ±5%，实测 $successCount/1000');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // useCrystalToGuarantee 行为
  // ────────────────────────────────────────────────────────────────────────────

  group('useCrystalToGuarantee', () {
    test('+14 段消耗 3 颗 → 成功 +1', () {
      final eq = newEq(enhanceLevel: 13);
      final r = EnhancementService.useCrystalToGuarantee(
        eq: eq,
        characterAbsoluteLevel: 19,
        currentCrystals: 5,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.success);
      expect(eq.enhanceLevel, 14);
      expect(r.crystalsSpent, 3);
    });

    test('+17 段消耗 5 颗', () {
      final eq = newEq(enhanceLevel: 16);
      final r = EnhancementService.useCrystalToGuarantee(
        eq: eq,
        characterAbsoluteLevel: 19,
        currentCrystals: 5,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.success);
      expect(r.crystalsSpent, 5);
    });

    test('+20 段消耗 8 颗', () {
      final eq = newEq(enhanceLevel: 19);
      final r = EnhancementService.useCrystalToGuarantee(
        eq: eq,
        characterAbsoluteLevel: 30,
        currentCrystals: 10,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.success);
      expect(r.crystalsSpent, 8);
    });

    test('+5 段无保底 → noGuaranteeAvailable，等级不变', () {
      final eq = newEq(enhanceLevel: 4);
      final r = EnhancementService.useCrystalToGuarantee(
        eq: eq,
        characterAbsoluteLevel: 14,
        currentCrystals: 100,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.noGuaranteeAvailable);
      expect(eq.enhanceLevel, 4);
      expect(r.crystalsSpent, 0);
    });

    test('+14 段 currentCrystals=2 → insufficientCrystal', () {
      final eq = newEq(enhanceLevel: 13);
      final r = EnhancementService.useCrystalToGuarantee(
        eq: eq,
        characterAbsoluteLevel: 19,
        currentCrystals: 2,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.insufficientCrystal);
      expect(eq.enhanceLevel, 13);
    });

    test('capped 时 useCrystalToGuarantee 也守卫', () {
      final eq = newEq(enhanceLevel: 10);
      final r = EnhancementService.useCrystalToGuarantee(
        eq: eq,
        characterAbsoluteLevel: 10,
        currentCrystals: 100,
        config: cfg,
      );
      expect(r.outcome, EnhanceOutcome.capped);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 配置非法守卫
  // ────────────────────────────────────────────────────────────────────────────

  test('neverDegrade=false 抛 StateError', () {
    final badConfig = EnhancementConfig(
      successCurve: cfg.successCurve,
      mojianshiCost: cfg.mojianshiCost,
      crystalGuarantees: cfg.crystalGuarantees,
      crystalGainPerFailure: cfg.crystalGainPerFailure,
      neverDegrade: false,
    );
    expect(
      () => EnhancementService.tryEnhance(
        eq: newEq(),
        characterAbsoluteLevel: 14,
        rng: rngFixed(0.0),
        currentMojianshi: 100,
        config: badConfig,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

/// 注入用 rng：[nextDouble] 永远返回固定值，方便强制成功 / 失败分支。
class _FixedRng implements Rng {
  final double fixed;
  _FixedRng(this.fixed);

  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => fixed;

  @override
  T pick<T>(List<T> list) => list.first;
}
