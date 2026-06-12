import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/equipment/domain/treasure_highlight.dart';
import 'package:wuxia_idle/features/equipment/presentation/treasure_drop_overlay.dart';

TreasureHighlight _h(EquipmentTier tier,
        {String? tagline = '剑身刻十七问，皆问天而天未答。'}) =>
    TreasureHighlight(
      defId: 'd',
      name: '玄铁重剑',
      tier: tier,
      slot: EquipmentSlot.weapon,
      iconPath: 'assets/missing.png',
      attack: 1840,
      health: 280,
      speed: 88,
      tagline: tagline,
    );

void main() {
  for (final tier in [
    EquipmentTier.zhongQi,
    EquipmentTier.baoWu,
    EquipmentTier.shenWu
  ]) {
    testWidgets('TreasureDropContent 渲染 $tier 不崩 + 缺图兜底 + 属性 + 典故',
        (t) async {
      // t=1.0:印章已落定、内容已渐入;缺图 iconPath 触发 errorBuilder→EquipGlyph 不破。
      await t.pumpWidget(MaterialApp(
        home: Scaffold(body: TreasureDropContent(highlight: _h(tier), t: 1.0)),
      ));
      expect(find.text('玄铁重剑'), findsOneWidget);
      expect(find.text(EnumL10n.equipmentTier(tier)), findsOneWidget);
      // 属性数值(RichText _AttrChip)
      expect(find.textContaining('1840', findRichText: true), findsWidgets);
      expect(find.textContaining('280', findRichText: true), findsWidgets);
      expect(find.textContaining('88', findRichText: true), findsWidgets);
      // 典故金句
      expect(find.text('剑身刻十七问，皆问天而天未答。'), findsOneWidget);
    });
  }

  testWidgets('tagline 为 null 时不渲染典故区(兜底)', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
          body: TreasureDropContent(
              highlight: _h(EquipmentTier.shenWu, tagline: null), t: 1.0)),
    ));
    expect(find.text('玄铁重剑'), findsOneWidget);
    // 属性仍在;典故句不出现
    expect(find.textContaining('1840', findRichText: true), findsWidgets);
    expect(find.text('剑身刻十七问，皆问天而天未答。'), findsNothing);
  });
}
