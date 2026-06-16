import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  group('Character innerDemonResidueHoursRemaining', () {
    test('Character.create 默认 innerDemonResidueHoursRemaining = 0', () {
      final c = Character.create(
        name: '苦行僧',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026, 6, 16),
      );
      expect(c.innerDemonResidueHoursRemaining, 0);
    });

    test('Character.create 可透传 innerDemonResidueHoursRemaining', () {
      final c = Character.create(
        name: '心魔测试',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026, 6, 16),
        innerDemonResidueHoursRemaining: 8.0,
      );
      expect(c.innerDemonResidueHoursRemaining, 8.0);
    });
  });
}
