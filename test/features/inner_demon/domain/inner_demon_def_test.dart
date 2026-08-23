import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/inner_demon_def.dart';

void main() {
  group('InnerDemonFailurePenalty', () {
    test('fromYaml 保留主修修炼度系数', () {
      final p = InnerDemonFailurePenalty.fromYaml({
        'main_cultivation_multiplier': 0.90,
      });
      expect(p.mainCultivationMultiplier, 0.90);
    });

    test('fromYaml rejects retired legacy fields', () {
      expect(
        () => InnerDemonFailurePenalty.fromYaml({
          'internal_force_multiplier': 0.85,
          'main_cultivation_multiplier': 0.90,
        }),
        throwsFormatException,
      );
    });

    test('fromYaml rejects missing or out-of-range main multiplier', () {
      expect(
        () => InnerDemonFailurePenalty.fromYaml({}),
        throwsFormatException,
      );
      expect(
        () => InnerDemonFailurePenalty.fromYaml({
          'main_cultivation_multiplier': 1.1,
        }),
        throwsFormatException,
      );
    });
  });
}
