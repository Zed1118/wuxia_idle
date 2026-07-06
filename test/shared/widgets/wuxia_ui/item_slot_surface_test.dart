import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/dark_parchment_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/item_slot.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart';

Color? _textColor(WidgetTester t, String s) =>
    t.widget<Text>(find.text(s)).style?.color;

Widget wrap(Widget c) => MaterialApp(home: Material(child: c));

// 物品名标签（非 highTier 时原 WuxiaUi.ink）读所在面板 surface.primary；
// highTier 金框名保持 gold，tier/status/lock 角标（paper on 彩底）不迁移。
const _component = ItemSlot(
  imagePath: null,
  name: '青锋剑',
  tierColor: WuxiaUi.qing,
  equipmentSlot: EquipmentSlot.weapon,
);

void main() {
  testWidgets('浅底物品名取 ink', (t) async {
    await t.pumpWidget(wrap(const LightPaperPanel(child: _component)));
    expect(_textColor(t, '青锋剑'), WuxiaUi.ink);
  });

  testWidgets('深底物品名取 textPrimary', (t) async {
    await t.pumpWidget(wrap(const DarkParchmentPanel(child: _component)));
    expect(_textColor(t, '青锋剑'), WuxiaColors.textPrimary);
  });
}
