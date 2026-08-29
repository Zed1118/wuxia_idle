import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_vfx_controller.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';

import '../../../../support/test_data.dart';

void main() {
  const viewports = [Size(1280, 720), Size(1440, 900)];
  const clearSealKey = ValueKey('phase0a_seal_clear');
  const playerHudKey = ValueKey('phase0a_player_hud');

  late Phase0aBattleController controller;

  setUp(() async {
    await loadTestGameRepository();
    final fixture = await Phase0aDebugBattleFixture.load(
      assetLoader: loadTestAsset,
      numbers: GameRepository.instance.numbers,
    );
    controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
  });

  tearDown(GameRepository.resetForTest);

  for (final viewport in viewports) {
    testWidgets('R 普通群怪下一绘制帧收束为总伤害与命中数 ($viewport)', (tester) async {
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Phase0aBattleScreen(
            controller: controller,
            autoStep: false,
            feedbackHoldSeconds: 20,
          ),
        ),
      );
      await tester.pump();

      for (var step = 0; step < 4; step++) {
        controller.step(const Phase0aPlayerCommand(right: true));
        await tester.pump();
      }
      await tester.tap(find.byKey(clearSealKey));
      await tester.pump();
      final events = controller.step();
      await tester.pump();

      final applied = events.whereType<Phase0aClearApplied>().single;
      final nonZero = applied.outcomes
          .where((outcome) => outcome.resolvedDamage > 0)
          .toList();
      expect(nonZero.length, greaterThan(1), reason: 'fixture 必须命中多个普通敌人');
      expect(
        controller.feedback.where(
          (entry) => entry.kind == Phase0aVfxKind.damagePopup,
        ),
        hasLength(nonZero.length),
        reason: '原始逐目标表现事件必须完整保留',
      );

      await tester.pump();

      final total = nonZero.fold<int>(
        0,
        (sum, outcome) => sum + outcome.resolvedDamage,
      );
      final aggregateKey = ValueKey<String>(
        'phase0a_damage_group_${applied.seq}',
      );
      expect(find.byKey(aggregateKey), findsOneWidget);
      expect(find.text('$total ×${nonZero.length}'), findsOneWidget);

      final popupFinder = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return widget is Positioned &&
            key is ValueKey<String> &&
            key.value.startsWith('phase0a_popup_');
      });
      expect(popupFinder, findsOneWidget, reason: '多目标普通伤害只占一个居民组');

      for (final outcome in nonZero) {
        final semanticKey = outcome.defeated
            ? ValueKey('phase0a_defeat_ink_${outcome.target}')
            : ValueKey('phase0a_hit_flash_${outcome.target}');
        expect(
          find.byKey(semanticKey),
          findsOneWidget,
          reason: '聚合不得掩盖目标 ${outcome.target} 的命中/致死语义',
        );
      }

      final aggregateRect = tester.getRect(find.byKey(aggregateKey));
      final hudRect = tester.getRect(find.byKey(playerHudKey));
      expect(aggregateRect.left, greaterThanOrEqualTo(0));
      expect(aggregateRect.top, greaterThanOrEqualTo(0));
      expect(aggregateRect.right, lessThanOrEqualTo(viewport.width));
      expect(aggregateRect.bottom, lessThanOrEqualTo(viewport.height));
      expect(
        aggregateRect.overlaps(hudRect),
        isFalse,
        reason: '聚合伤害不得遮挡玩家 HUD',
      );
    });
  }
}
