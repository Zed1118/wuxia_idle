import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';

/// Batch4 #6 · enum 映射归 EnumL10n：attributeKey + terrainBiome 映射单测。
void main() {
  group('EnumL10n.attributeKey 4 映射', () {
    test('constitution → 根骨', () {
      expect(EnumL10n.attributeKey(AttributeKey.constitution), '根骨');
    });

    test('enlightenment → 悟性', () {
      expect(EnumL10n.attributeKey(AttributeKey.enlightenment), '悟性');
    });

    test('agility → 身法', () {
      expect(EnumL10n.attributeKey(AttributeKey.agility), '身法');
    });

    test('fortune → 机缘', () {
      expect(EnumL10n.attributeKey(AttributeKey.fortune), '机缘');
    });

    test('所有 AttributeKey enum 值都有非空映射(全覆盖红线)', () {
      for (final k in AttributeKey.values) {
        expect(
          EnumL10n.attributeKey(k),
          isNotEmpty,
          reason: '$k 缺少中文映射',
        );
      }
    });
  });

  group('EnumL10n.terrainBiome 映射(含 null=平地)', () {
    test('water → 水面', () {
      expect(EnumL10n.terrainBiome(TerrainBiome.water), '水面');
    });

    test('rooftop → 屋脊', () {
      expect(EnumL10n.terrainBiome(TerrainBiome.rooftop), '屋脊');
    });

    test('bamboo → 竹林', () {
      expect(EnumL10n.terrainBiome(TerrainBiome.bamboo), '竹林');
    });

    test('null → 平地', () {
      expect(EnumL10n.terrainBiome(null), '平地');
    });

    test('所有 TerrainBiome enum 值都有非空映射(全覆盖红线)', () {
      for (final b in TerrainBiome.values) {
        expect(
          EnumL10n.terrainBiome(b),
          isNotEmpty,
          reason: '$b 缺少中文映射',
        );
      }
    });
  });
}
