import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/equipment/domain/treasure_highlight.dart';
import 'package:wuxia_idle/features/equipment/presentation/treasure_drop_overlay.dart';

TreasureHighlight _h(EquipmentTier tier) => TreasureHighlight(
      defId: 'd', name: '玄铁重剑', tier: tier,
      slot: EquipmentSlot.weapon, iconPath: 'assets/missing.png');

void main() {
  for (final tier in [EquipmentTier.zhongQi, EquipmentTier.baoWu, EquipmentTier.shenWu]) {
    testWidgets('TreasureDropContent 渲染 $tier 不崩 + 缺图兜底', (t) async {
      // t=1.0:印章已落定、墨团定格;缺图 iconPath 触发 errorBuilder→EquipGlyph 不破。
      await t.pumpWidget(MaterialApp(
        home: Scaffold(body: TreasureDropContent(highlight: _h(tier), t: 1.0)),
      ));
      expect(find.text('玄铁重剑'), findsOneWidget);
      expect(find.text(EnumL10n.equipmentTier(tier)), findsOneWidget);
    });
  }
}
