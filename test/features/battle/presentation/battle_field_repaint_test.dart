import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/widgets/battle_field.dart';

void main() {
  testWidgets('3v3 character slots are isolated by repaint boundaries', (
    tester,
  ) async {
    final (left, right) = BattleDemo.mockTeams();
    final attackControllers = List.generate(
      6,
      (_) => AnimationController(vsync: tester),
    );
    final hitFlashControllers = List.generate(
      6,
      (_) => AnimationController(vsync: tester),
    );
    addTearDown(() {
      for (final controller in [...attackControllers, ...hitFlashControllers]) {
        controller.dispose();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BattleField(
            state: BattleState.initial(leftTeam: left, rightTeam: right),
            attackControllers: attackControllers,
            popups: const {},
            animConfig: AnimationNumbers.defaults,
            chargeMaxTicks: 3,
            beat: const AlwaysStoppedAnimation<double>(0),
            staggerWindowTicks: 3,
            onPopupComplete: (_, _) {},
            hitFlashControllers: hitFlashControllers,
            hitFlashColors: const {},
            onEnemyTap: (_) {},
            pendingActive: false,
            hoveredEnemyId: null,
            onEnemyHover: (_, _) {},
          ),
        ),
      ),
    );

    for (var side = 0; side < 2; side++) {
      for (var slot = 0; slot < 3; slot++) {
        expect(
          find.byKey(ValueKey('battle.characterSlot.repaint.$side.$slot')),
          findsOneWidget,
        );
      }
    }
  });
}
