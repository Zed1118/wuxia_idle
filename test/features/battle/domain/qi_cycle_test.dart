import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/qi_cycle.dart';

void main() {
  group('QiCycle', () {
    test('opening qi is bounded by max and opening cap', () {
      expect(QiCycle.openingQi(maxQi: 100, openingQi: 40, openingCap: 80), 40);
      expect(QiCycle.openingQi(maxQi: 60, openingQi: 90, openingCap: 80), 60);
    });

    test('positive gain clamps at max and overflow is discarded', () {
      expect(QiCycle.applyDelta(currentQi: 95, maxQi: 100, delta: 20), 100);
    });

    test('negative delta clamps at zero', () {
      expect(QiCycle.applyDelta(currentQi: 20, maxQi: 100, delta: -30), 0);
    });

    test('one action receives at most one school bonus', () {
      expect(
        QiCycle.schoolBonus(
          school: TechniqueSchool.lingQiao,
          event: const QiActionEvent(critical: true, dodged: true),
          bonus: 5,
        ),
        5,
      );
    });

    test('each school recognizes only its approved action events', () {
      expect(
        QiCycle.schoolBonus(
          school: TechniqueSchool.gangMeng,
          event: const QiActionEvent(receivedHit: true),
          bonus: 5,
        ),
        5,
      );
      expect(
        QiCycle.schoolBonus(
          school: TechniqueSchool.yinRou,
          event: const QiActionEvent(appliedControlOrDot: true),
          bonus: 5,
        ),
        5,
      );
      expect(
        QiCycle.schoolBonus(
          school: TechniqueSchool.lingQiao,
          event: const QiActionEvent(landedHit: true),
          bonus: 5,
        ),
        0,
      );
    });

    test('cost reduction is capped and never turns a cost negative', () {
      expect(
        QiCycle.effectiveCost(
          baseCost: 60,
          reductionPct: 0.80,
          reductionCap: 0.20,
        ),
        48,
      );
      expect(
        QiCycle.effectiveCost(
          baseCost: 0,
          reductionPct: 0.20,
          reductionCap: 0.20,
        ),
        0,
      );
    });

    test('chain recovery is based on max qi and clamps at max', () {
      expect(
        QiCycle.recoverBetweenWaves(
          currentQi: 90,
          maxQi: 100,
          recoveryPct: 0.25,
        ),
        100,
      );
      expect(
        QiCycle.recoverBetweenWaves(
          currentQi: 20,
          maxQi: 100,
          recoveryPct: 0.25,
        ),
        45,
      );
    });

    test('disorder reduces effective inner force linearly within cap', () {
      expect(
        QiCycle.effectiveInnerForce(
          actualInnerForce: 1000,
          disorderHours: 6,
          disorderMaxHours: 12,
          maxPenaltyPct: 0.20,
        ),
        900,
      );
      expect(
        QiCycle.effectiveInnerForce(
          actualInnerForce: 1000,
          disorderHours: 99,
          disorderMaxHours: 12,
          maxPenaltyPct: 0.20,
        ),
        800,
      );
    });

    test('disorder reduces opening qi linearly within cap', () {
      expect(
        QiCycle.disorderOpeningQiPenalty(
          disorderHours: 6,
          disorderMaxHours: 12,
          maxPenalty: 20,
        ),
        10,
      );
      expect(
        QiCycle.disorderOpeningQiPenalty(
          disorderHours: 99,
          disorderMaxHours: 12,
          maxPenalty: 20,
        ),
        20,
      );
    });
  });

  group('qi configuration', () {
    test('parses bounded combat qi values', () {
      final config = QiConfig.fromYaml(const {
        'base_max': 100,
        'opening_qi': 40,
        'enemy_opening_qi': 20,
        'boss_opening_bonus': 20,
        'tower_boss_opening_bonus': 40,
        'opening_cap': 80,
        'min_max': 80,
        'max_cap': 140,
        'school_bonus': 5,
        'chain_recovery_pct': 0.25,
        'gain_multiplier_cap': 1.5,
        'cost_reduction_cap': 0.2,
        'delta_abs_cap': 100,
      });

      expect(config.baseMax, 100);
      expect(config.openingQi, 40);
      expect(config.enemyOpeningQi, 20);
      expect(config.bossOpeningBonus, 20);
      expect(config.towerBossOpeningBonus, 40);
      expect(config.maxCap, 140);
      expect(config.chainRecoveryPct, 0.25);
    });

    test('rejects an opening cap above the qi hard cap', () {
      expect(
        () => QiConfig.fromYaml(const {
          'base_max': 100,
          'opening_qi': 40,
          'enemy_opening_qi': 20,
          'boss_opening_bonus': 20,
          'tower_boss_opening_bonus': 40,
          'opening_cap': 160,
          'min_max': 80,
          'max_cap': 140,
          'school_bonus': 5,
          'chain_recovery_pct': 0.25,
          'gain_multiplier_cap': 1.5,
          'cost_reduction_cap': 0.2,
          'delta_abs_cap': 100,
        }),
        throwsStateError,
      );
    });

    test('parses bounded inner-breath disorder values', () {
      final config = InnerBreathDisorderConfig.fromYaml(const {
        'max_hours': 12.0,
        'max_inner_force_penalty_pct': 0.2,
        'max_opening_qi_penalty': 20,
        'battle_recovery_hours': 1.0,
        'dispel_hours': 6.0,
        'boss_defeat_hours': 8.0,
        'inner_demon_hours': 12.0,
      });

      expect(config.maxHours, 12);
      expect(config.battleRecoveryHours, 1);
      expect(config.innerDemonHours, 12);
    });
  });
}
