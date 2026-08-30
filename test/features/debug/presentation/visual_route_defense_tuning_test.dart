import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';

import '../../../support/test_data.dart';

void main() {
  const viewports = <Size>[Size(1280, 720), Size(1440, 900)];
  const keyCases =
      <({LogicalKeyboardKey key, Phase0aDefenseAction action, String label})>[
        (
          key: LogicalKeyboardKey.space,
          action: Phase0aDefenseAction.dodge,
          label: 'Space/dodge',
        ),
      ];

  late Phase0aDebugBattleFixture baseFixture;

  setUpAll(() async {
    await loadTestGameRepository();
    baseFixture = await Phase0aDebugBattleFixture.load(
      assetLoader: loadTestAsset,
      numbers: GameRepository.instance.numbers,
    );
  });
  tearDownAll(GameRepository.resetForTest);

  for (final viewport in viewports) {
    testWidgets(
      'visual route fixture 在 ${viewport.width.toInt()}x${viewport.height.toInt()} '
      '从真实键盘入口启动防御',
      (tester) async {
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        for (final keyCase in keyCases) {
          final fixture = baseFixture.fresh();
          final tuning = fixture.playerAdapter.defenseTuning;
          expect(
            tuning,
            isNotNull,
            reason: '${keyCase.label} 缺 defense tuning',
          );
          final controller = Phase0aBattleController(
            flow: fixture.flow,
            roster: fixture.roster,
            fixedDeltaSeconds: fixture.fixedDeltaSeconds,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Phase0aBattleScreen(
                controller: controller,
                autoStep: false,
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: keyCase.label);

          await tester.sendKeyEvent(keyCase.key);
          final events = controller.step();
          await tester.pump();

          final started = events.whereType<Phase0aDefenseStarted>().single;
          expect(started.action, keyCase.action, reason: keyCase.label);
          expect(tester.takeException(), isNull, reason: keyCase.label);

          controller.dispose();
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }

  testWidgets('visual route fixture 的敌方攻击消费同一 tuning 并触发护盾结算', (tester) async {
    final fixture = baseFixture.fresh();
    final tuning = fixture.playerAdapter.defenseTuning!;
    final controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (var tick = 0; tick < 16; tick++) {
      controller.step();
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: controller, autoStep: false),
      ),
    );
    await tester.pump();
    controller.enqueue(
      const Phase0aPlayerCommand(defenseAction: Phase0aDefenseAction.shield),
    );

    final observed = <Phase0aEvent>[];
    for (var tick = 0; tick < tuning.shieldDurationTicks; tick++) {
      observed.addAll(controller.step());
      await tester.pump();
      if (observed.whereType<Phase0aDefenseResolved>().isNotEmpty) break;
    }

    expect(
      observed.whereType<Phase0aDefenseStarted>().single.action,
      Phase0aDefenseAction.shield,
    );
    expect(
      observed.whereType<Phase0aDefenseResolved>(),
      isNotEmpty,
      reason: '敌方 adapter 必须携带 defense flags，不得绕过护盾结算',
    );
    expect(
      controller.state.player.shieldRemaining,
      lessThan(tuning.shieldAbsorption),
    );
    expect(tester.takeException(), isNull);
  });
}
