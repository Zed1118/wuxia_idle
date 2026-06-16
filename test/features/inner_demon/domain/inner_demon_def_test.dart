import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_def.dart';

void main() {
  group('InnerDemonFailurePenalty', () {
    test('fromYaml 解析 internal_force_floor_pct', () {
      final p = InnerDemonFailurePenalty.fromYaml({
        'internal_force_multiplier': 0.85,
        'internal_force_floor_pct': 0.50,
      });
      expect(p.internalForceFloorPct, 0.50);
    });

    test('fromYaml 缺字段默认 0.50', () {
      final p = InnerDemonFailurePenalty.fromYaml({});
      expect(p.internalForceFloorPct, 0.50);
    });
  });
}
