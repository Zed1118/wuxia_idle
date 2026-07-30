import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_standee_fusion.dart';

/// B3 方案 B(立绘按场景背景明度自适应融合)的守卫。
///
/// 断言写**约束语义**不写瞬时数值:插值公式与登记值将来都可能调,但
/// 「暗场景必须逐值等于基线」「亮场景必须真的动了」「只许动对角与偏移项」
/// 「新背景资产必须登记」这四条是设计红线,改动它们必须是显式决定。
void main() {
  /// 从真生产 yaml 抓所有战斗背景引用(非合成 fixture ——
  /// memory `feedback_redline_test_fixture_vs_production_guard`:
  /// 读不到生产 yaml 的红线测会给假绿)。
  Set<String> productionScenePaths() {
    final paths = <String>{};
    final pattern = RegExp(r'sceneBackgroundPath:\s*(\S+)');
    for (final name in const ['data/stages.yaml', 'data/towers.yaml']) {
      final file = File(name);
      if (!file.existsSync()) continue;
      for (final m in pattern.allMatches(file.readAsStringSync())) {
        paths.add(m.group(1)!);
      }
    }
    return paths;
  }

  group('登记表覆盖棘轮', () {
    test('生产 yaml 引用的每个战斗背景都已登记合成明度', () {
      final referenced = productionScenePaths();
      expect(referenced, isNotEmpty, reason: '一个都没抓到 → 正则或 yaml 字段名漂移了,此测已失效');
      final missing =
          referenced
              .where((p) => !battleSceneCompositeLuminance.containsKey(p))
              .toList()
            ..sort();
      expect(
        missing,
        isEmpty,
        reason:
            '新背景资产未登记合成明度 → 会静默回落基线档、拿不到自适应融合。'
            '按 battle_standee_fusion.dart 头注的取样带实测后补登记:$missing',
      );
    });

    test('登记表不留已从生产摘掉的死条目', () {
      final referenced = productionScenePaths();
      final stale =
          battleSceneCompositeLuminance.keys
              .where((p) => !referenced.contains(p))
              .toList()
            ..sort();
      expect(stale, isEmpty, reason: '登记表有生产已不引用的资产,应删:$stale');
    });

    test('登记明度都在合法灰度域内', () {
      for (final entry in battleSceneCompositeLuminance.entries) {
        expect(
          entry.value,
          inInclusiveRange(0, 255),
          reason: '${entry.key} 明度越界',
        );
      }
    });
  });

  group('基线回落(零回归面)', () {
    test('scenePath 为 null / 空串 → 逐值等于基线', () {
      expect(
        battleStandeeFusionFor(scenePath: null),
        BattleStandeeFusion.baseline,
      );
      expect(
        battleStandeeFusionFor(scenePath: ''),
        BattleStandeeFusion.baseline,
      );
    });

    test('未登记的资产 → 逐值等于基线(不对没量过的背景瞎调)', () {
      expect(
        battleStandeeFusionFor(scenePath: 'assets/scenes/battle_不存在.png'),
        BattleStandeeFusion.baseline,
      );
    });

    test('基线档的矩阵与 opacity 就是自适应前的常量', () {
      expect(BattleStandeeFusion.baseline.matrix, battleStandeeFusionMatrix);
      expect(BattleStandeeFusion.baseline.opacity, battleStandeeFusionOpacity);
      expect(BattleStandeeFusion.baseline.strength, 0);
    });

    test('强度 0 → 逐值等于基线', () {
      expect(battleStandeeFusionAtStrength(0), BattleStandeeFusion.baseline);
    });
  });

  group('暗场景钳位(评估文档 §七#3 的下限要求)', () {
    test('明度不高于下沿的登记资产一律走基线档', () {
      final dark = battleSceneCompositeLuminance.entries
          .where((e) => e.value <= battleStandeeFusionLuminanceFloor)
          .toList();
      expect(dark, isNotEmpty, reason: '没有任何资产落在下沿之下 → 下沿设得太低,暗场景失去保护');
      for (final entry in dark) {
        final fusion = battleStandeeFusionFor(scenePath: entry.key);
        expect(
          fusion,
          BattleStandeeFusion.baseline,
          reason: '${entry.key}(L=${entry.value})在下沿之下,必须零改动',
        );
      }
    });

    test('塔境/心魔共用的 innerrealm 必须落在基线档', () {
      // 塔与心魔是全仓最暗的战斗场景,融合在这里只会把人物埋进背景。
      const innerRealm = 'assets/scenes/battle_innerrealm.png';
      expect(battleSceneCompositeLuminance.containsKey(innerRealm), isTrue);
      expect(
        battleStandeeFusionFor(scenePath: innerRealm),
        BattleStandeeFusion.baseline,
      );
    });
  });

  group('亮场景确实生效(防自适应退化成 no-op)', () {
    test('至少一个登记资产落在满档区(强度 ≥ 0.9)', () {
      final strengths = battleSceneCompositeLuminance.values
          .map(battleStandeeFusionStrengthForLuminance)
          .toList();
      expect(
        strengths.where((s) => s >= 0.9),
        isNotEmpty,
        reason: '没有资产接近满档 → 上沿设得太高,最亮场景也没被处理',
      );
    });

    test('最亮资产的 opacity 低于基线且不破满档下限', () {
      final brightest = battleSceneCompositeLuminance.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      final fusion = battleStandeeFusionFor(scenePath: brightest.key);
      expect(fusion.opacity, lessThan(battleStandeeFusionOpacity));
      expect(
        fusion.opacity,
        greaterThanOrEqualTo(battleStandeeFusionOpacityAtFull),
      );
      expect(fusion.strength, greaterThan(0));
    });

    test('满档:黑位抬高、对角压低(方向与评估文档一致)', () {
      final full = battleStandeeFusionAtStrength(1);
      for (final i in const [4, 9, 14]) {
        expect(
          full.matrix[i],
          greaterThan(battleStandeeFusionMatrix[i]),
          reason: '偏移项 $i 应抬黑位',
        );
      }
      for (final i in const [0, 6, 12]) {
        expect(
          full.matrix[i],
          lessThan(battleStandeeFusionMatrix[i]),
          reason: '对角项 $i 应压对比',
        );
      }
      expect(full.opacity, battleStandeeFusionOpacityAtFull);
    });
  });

  group('全域不变量', () {
    test('任何强度下只许动对角与偏移项,其余逐值不变', () {
      const mutable = {0, 6, 12, 4, 9, 14};
      for (final t in const [0.0, 0.15, 0.5, 0.83, 1.0]) {
        final fusion = battleStandeeFusionAtStrength(t);
        expect(fusion.matrix, hasLength(battleStandeeFusionMatrix.length));
        for (var i = 0; i < battleStandeeFusionMatrix.length; i++) {
          if (mutable.contains(i)) continue;
          expect(
            fusion.matrix[i],
            battleStandeeFusionMatrix[i],
            reason: '强度 $t 下第 $i 项被动了(含 alpha 行 18,不参与自适应)',
          );
        }
      }
    });

    test('opacity 随强度单调不增,且始终落在 [满档下限, 基线] 内', () {
      var previous = double.infinity;
      for (final t in const [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]) {
        final opacity = battleStandeeFusionAtStrength(t).opacity;
        expect(opacity, lessThanOrEqualTo(previous));
        expect(
          opacity,
          inInclusiveRange(
            battleStandeeFusionOpacityAtFull,
            battleStandeeFusionOpacity,
          ),
        );
        previous = opacity;
      }
    });

    test('背景越亮融合强度不减(单调)', () {
      final sorted = battleSceneCompositeLuminance.values.toList()..sort();
      var previous = -1.0;
      for (final luminance in sorted) {
        final strength = battleStandeeFusionStrengthForLuminance(luminance);
        expect(strength, greaterThanOrEqualTo(previous));
        expect(strength, inInclusiveRange(0, 1));
        previous = strength;
      }
    });

    test('强度入参越界被钳住,不抛也不外溢', () {
      expect(battleStandeeFusionAtStrength(-5), BattleStandeeFusion.baseline);
      expect(battleStandeeFusionAtStrength(9).strength, 1);
      expect(battleStandeeFusionStrengthForLuminance(-100), 0);
      expect(battleStandeeFusionStrengthForLuminance(1000), 1);
    });
  });
}
