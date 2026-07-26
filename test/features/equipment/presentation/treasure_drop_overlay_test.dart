import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/domain/treasure_highlight.dart';
import 'package:wuxia_idle/features/equipment/presentation/treasure_drop_overlay.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('TreasureDropOverlay 动画跑完停留(不自动回调) + 轻触才继续', (t) async {
    var done = false;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TreasureDropOverlay(
            highlight: const TreasureHighlight(
              defId: 'd',
              name: '倚天神剑',
              tier: EquipmentTier.shenWu,
              slot: EquipmentSlot.weapon,
              iconPath: 'm.png',
            ),
            onDone: () => done = true,
          ),
        ),
      ),
    );
    expect(find.text('倚天神剑'), findsOneWidget);
    // 动画跑完(1.3s)后停留:不自动回调,显「轻触继续」
    await t.pump(const Duration(milliseconds: 1500));
    expect(done, isFalse);
    expect(find.text('轻触继续'), findsOneWidget);
    // 轻触 → 继续回调
    await t.tap(find.byType(TreasureDropOverlay));
    await t.pump();
    expect(done, isTrue);
  });

  testWidgets('爆品停留态具继续按钮语义并支持 Enter', (t) async {
    final semantics = t.ensureSemantics();
    var done = false;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TreasureDropOverlay(
            highlight: const TreasureHighlight(
              defId: 'd',
              name: '倚天神剑',
              tier: EquipmentTier.shenWu,
              slot: EquipmentSlot.weapon,
              iconPath: 'm.png',
            ),
            onDone: () => done = true,
          ),
        ),
      ),
    );
    await t.pump();

    final overlaySemantics = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label ==
              UiStrings.treasureDropContinueSemanticLabel('倚天神剑'),
    );
    expect(
      t.getSemantics(overlaySemantics),
      isSemantics(
        label: UiStrings.treasureDropContinueSemanticLabel('倚天神剑'),
        isButton: true,
        isLiveRegion: true,
        hasTapAction: true,
      ),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(done, isTrue);
    semantics.dispose();
  });
}
