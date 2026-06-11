import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/domain/treasure_highlight.dart';
import 'package:wuxia_idle/features/equipment/presentation/treasure_drop_overlay.dart';

void main() {
  testWidgets('TreasureDropOverlay 动画跑完自动结束回调', (t) async {
    var done = false;
    await t.pumpWidget(MaterialApp(home: Scaffold(body: TreasureDropOverlay(
      highlight: TreasureHighlight(defId: 'd', name: '倚天神剑',
          tier: EquipmentTier.shenWu, slot: EquipmentSlot.weapon, iconPath: 'm.png'),
      onDone: () => done = true,
    ))));
    expect(find.text('倚天神剑'), findsOneWidget);
    await t.pumpAndSettle(const Duration(seconds: 2));
    expect(done, isTrue);
  });
}
