import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('Character.create 透传 portraitPath,默认 null', () {
    final withPortrait = Character.create(
      name: '竹影客',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime(2026, 5, 31),
      portraitPath: 'assets/characters/sect_candidate_bamboo.png',
    );
    expect(withPortrait.portraitPath,
        'assets/characters/sect_candidate_bamboo.png');

    final without = Character.create(
      name: '无图',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime(2026, 5, 31),
    );
    expect(without.portraitPath, isNull);
  });
}
