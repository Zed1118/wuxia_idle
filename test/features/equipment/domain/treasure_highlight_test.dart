import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/domain/treasure_highlight.dart';

TreasureHighlight _c(String id, EquipmentTier tier) => TreasureHighlight(
      defId: id,
      name: id,
      tier: tier,
      slot: EquipmentSlot.weapon,
      iconPath: 'x.png',
    );

void main() {
  group('pickTreasureHighlight', () {
    const min = EquipmentTier.zhongQi;

    test('空候选 → null', () {
      expect(pickTreasureHighlight(const [], min), isNull);
    });

    test('全低阶(利器) → null', () {
      expect(pickTreasureHighlight([_c('a', EquipmentTier.liQi)], min), isNull);
    });

    test('重器边界 → 触发', () {
      expect(
        pickTreasureHighlight([_c('a', EquipmentTier.zhongQi)], min)?.defId,
        'a',
      );
    });

    test('多件取最高 tier', () {
      final r = pickTreasureHighlight(
        [
          _c('a', EquipmentTier.zhongQi),
          _c('b', EquipmentTier.baoWu),
          _c('c', EquipmentTier.liQi),
        ],
        min,
      );
      expect(r?.defId, 'b');
    });

    test('并列最高取首件', () {
      final r = pickTreasureHighlight(
        [
          _c('a', EquipmentTier.shenWu),
          _c('b', EquipmentTier.shenWu),
        ],
        min,
      );
      expect(r?.defId, 'a');
    });
  });
}
