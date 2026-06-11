import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  group('TreasureDropConfig', () {
    test('解析 min_tier', () {
      final c = TreasureDropConfig.fromYaml({'min_tier': 'zhongQi'});
      expect(c.minTier, EquipmentTier.zhongQi);
    });
    test('空/缺字段兜底重器', () {
      expect(TreasureDropConfig.fromYaml(null).minTier, EquipmentTier.zhongQi);
      expect(TreasureDropConfig.fromYaml({}).minTier, EquipmentTier.zhongQi);
    });
    test('非法 tier 名抛 ArgumentError(yaml typo 不静默)', () {
      expect(
        () => TreasureDropConfig.fromYaml({'min_tier': 'zhongqi'}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
