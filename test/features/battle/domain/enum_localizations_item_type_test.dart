import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';

/// W15 #30 P3 后续 A · 物料 Tab：EnumL10n.itemType 5 映射单测。
void main() {
  group('EnumL10n.itemType 5 映射', () {
    test('moJianShi → 磨剑石', () {
      expect(EnumL10n.itemType(ItemType.moJianShi), '磨剑石');
    });

    test('xinXueJieJing → 心血结晶', () {
      expect(EnumL10n.itemType(ItemType.xinXueJieJing), '心血结晶');
    });

    test('jingYanDan → 经验丹', () {
      expect(EnumL10n.itemType(ItemType.jingYanDan), '经验丹');
    });

    test('techniqueScroll → 心法秘籍', () {
      expect(EnumL10n.itemType(ItemType.techniqueScroll), '心法秘籍');
    });

    test('miscMaterial → 杂项材料', () {
      expect(EnumL10n.itemType(ItemType.miscMaterial), '杂项材料');
    });

    test('ItemType.silver 显示名为 银两', () {
      expect(EnumL10n.itemType(ItemType.silver), '银两');
    });

    test('所有 ItemType enum 值都有非空映射(全覆盖红线)', () {
      for (final t in ItemType.values) {
        expect(
          EnumL10n.itemType(t),
          isNotEmpty,
          reason: '$t 缺少中文映射',
        );
      }
    });
  });
}
