import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  group('CycleEvolutionConfig', () {
    test('scale_per_cycle 与 cap 参数', () {
      final ce = GameRepository.instance.numbers.cycleEvolution;
      expect(ce.scalePerCycle, closeTo(0.10, 1e-9)); // 2026-06-26 周目平衡 0.06→0.10
      expect(ce.maxCycleMainline, 3);
      expect(ce.maxCycleTower, 2);
      expect(ce.defenseRateCap, closeTo(0.6, 1e-9));
    });

    test('词条参数 — yuti', () {
      final ce = GameRepository.instance.numbers.cycleEvolution;
      expect(ce.traits.yuti.defenseRateBonusC2, closeTo(0.08, 1e-9));
      expect(ce.traits.yuti.defenseRateBonusC3, closeTo(0.12, 1e-9));
    });

    test('词条参数 — fanzhen', () {
      final ce = GameRepository.instance.numbers.cycleEvolution;
      expect(ce.traits.fanzhen.damagePerTick, 200);
      expect(ce.traits.fanzhen.ticks, 3);
    });

    test('词条参数 — ningjia', () {
      final ce = GameRepository.instance.numbers.cycleEvolution;
      expect(ce.traits.ningjia.critDamageTakenMult, closeTo(0.5, 1e-9));
    });

    test('词条参数 — zhenqi', () {
      final ce = GameRepository.instance.numbers.cycleEvolution;
      expect(ce.traits.zhenqi.internalForcePct, closeTo(0.20, 1e-9));
    });

    test('词条参数 — shipo (charge_skill_id 引用真实存在的蓄力技)', () {
      final ce = GameRepository.instance.numbers.cycleEvolution;
      // 使用 skill_qingshan_qingfeng（青锋绝，stages.yaml chargeSkillId 真实 id）
      expect(ce.traits.shipo.chargeSkillId, 'skill_qingshan_qingfeng');
    });

    group('traitsFor', () {
      test('cycle=1 → 空集(无强化)', () {
        final ce = GameRepository.instance.numbers.cycleEvolution;
        expect(ce.traitsFor(cycle: 1, isBoss: false, isTower: false), isEmpty);
      });

      test('cycle=2 主线普通 → {yuti, zhenqi}（2026-06-26 周目平衡加 zhenqi）', () {
        final ce = GameRepository.instance.numbers.cycleEvolution;
        expect(
          ce.traitsFor(cycle: 2, isBoss: false, isTower: false),
          {'yuti', 'zhenqi'},
        );
      });

      test('cycle=3 主线普通 → {yuti, fanzhen, shipo}', () {
        final ce = GameRepository.instance.numbers.cycleEvolution;
        expect(
          ce.traitsFor(cycle: 3, isBoss: false, isTower: false),
          {'yuti', 'fanzhen', 'shipo'},
        );
      });

      test('cycle=2 爬塔普通 → {yuti, zhenqi}', () {
        final ce = GameRepository.instance.numbers.cycleEvolution;
        expect(
          ce.traitsFor(cycle: 2, isBoss: false, isTower: true),
          {'yuti', 'zhenqi'},
        );
      });

      test('cycle=2 爬塔 Boss → {yuti, fanzhen, shipo, ningjia}', () {
        final ce = GameRepository.instance.numbers.cycleEvolution;
        expect(
          ce.traitsFor(cycle: 2, isBoss: true, isTower: true),
          {'yuti', 'fanzhen', 'shipo', 'ningjia'},
        );
      });

      test('cycle=0 → 空集', () {
        final ce = GameRepository.instance.numbers.cycleEvolution;
        expect(ce.traitsFor(cycle: 0, isBoss: false, isTower: false), isEmpty);
      });

      test('未配置的 cycle=3 爬塔普通 → 空集(无对应 entry)', () {
        final ce = GameRepository.instance.numbers.cycleEvolution;
        expect(
          ce.traitsFor(cycle: 3, isBoss: false, isTower: true),
          isEmpty,
        );
      });
    });
  });
}
