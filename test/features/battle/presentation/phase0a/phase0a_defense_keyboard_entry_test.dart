import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_defense_tuning.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

final class _DefenseScreenHarness {
  const _DefenseScreenHarness({required this.controller, required this.tuning});

  final Phase0aBattleController controller;
  final Phase0aDefenseTuning tuning;
}

void main() {
  late GameRepository repository;

  setUpAll(() async => repository = await loadTestGameRepository());

  Future<_DefenseScreenHarness> pumpProductionScreen(
    WidgetTester tester,
  ) async {
    final numbers = repository.numbers;
    final mapping = Phase0aStageContentMapper.map(
      stage: repository.getStage('stage_01_01'),
      playerSnapshot: testCombatantSnapshot(
        name: 'keyboard defense entry',
        includeProductionBasicAttack: true,
      ),
      numbers: numbers,
    );
    final tuning = mapping.playerAdapter.defenseTuning;
    expect(tuning, isNotNull, reason: '生产 Phase 0A mapping 必须装配防御 tuning');
    final flow = Phase0aProductionFlowAssembler.assemble(
      initialState: mapping.initialState,
      waves: mapping.waves,
      combatants: mapping.combatants,
      moveBindings: mapping.moveBindings,
      numbers: numbers,
      rng: Random(20260827),
      playerAdapter: mapping.playerAdapter,
      enemyAiAdapter: mapping.enemyAiAdapter,
    );
    final controller = Phase0aBattleController(
      flow: flow,
      roster: Phase0aVisualRoster.fromMapping(mapping),
      fixedDeltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(
          controller: controller,
          autoStep: false,
          feedbackHoldSeconds: 5,
        ),
      ),
    );
    await tester.pump();
    return _DefenseScreenHarness(controller: controller, tuning: tuning!);
  }

  void expectDefenseStartedVisible(WidgetTester tester) {
    final feedback = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('phase0a_defense_start_');
    });
    expect(feedback, findsOneWidget);
    expect(tester.getSize(feedback).width, greaterThan(0));
    expect(tester.getSize(feedback).height, greaterThan(0));
    expect(
      find.descendant(
        of: feedback,
        matching: find.text(UiStrings.phase0aDefenseStarted),
      ),
      findsOneWidget,
    );
  }

  testWidgets('E 从真实战斗屏入口进入 shield 并显示护盾反馈', (tester) async {
    final harness = await pumpProductionScreen(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    final events = harness.controller.step();
    await tester.pump();

    final started = events.whereType<Phase0aDefenseStarted>().single;
    expect(started.action, Phase0aDefenseAction.shield);
    expect(started.windowTicks, harness.tuning.shieldDurationTicks);
    expect(started.shieldAbsorption, harness.tuning.shieldAbsorption);
    expect(
      harness.controller.state.player.shieldRemaining,
      harness.tuning.shieldAbsorption,
    );
    expect(
      harness.controller.state.player.shieldTicksRemaining,
      harness.tuning.shieldDurationTicks,
    );
    expect(
      tester
          .widget<Text>(find.text(UiStrings.phase0aDefenseShieldKey))
          .style
          ?.color,
      WuxiaUi.qing,
    );
    expect(
      find.text(
        '${UiStrings.phase0aDefenseAbsorbPrefix} '
        '${harness.tuning.shieldAbsorption.round()}',
      ),
      findsOneWidget,
    );
    expectDefenseStartedVisible(tester);
  });

  testWidgets('F 从真实战斗屏入口进入 parry 并点亮化解反馈', (tester) async {
    final harness = await pumpProductionScreen(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    final events = harness.controller.step();
    await tester.pump();

    final started = events.whereType<Phase0aDefenseStarted>().single;
    expect(started.action, Phase0aDefenseAction.parry);
    expect(started.windowTicks, harness.tuning.parryWindowTicks);
    expect(
      harness.controller.state.player.parryTicksRemaining,
      harness.tuning.parryWindowTicks,
    );
    expect(
      harness.controller.state.player.parryCounterBudgetRemaining,
      harness.tuning.counterUpperBound,
    );
    expect(
      tester
          .widget<Text>(find.text(UiStrings.phase0aDefenseParryKey))
          .style
          ?.color,
      WuxiaUi.gold,
    );
    expectDefenseStartedVisible(tester);
  });

  testWidgets('Z 从真实战斗屏入口进入 dodge 并显示位移反馈', (tester) async {
    final harness = await pumpProductionScreen(tester);
    final before = harness.controller.state.player.position;

    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    final events = harness.controller.step();
    await tester.pump();

    final started = events.whereType<Phase0aDefenseStarted>().single;
    final after = harness.controller.state.player.position;
    expect(started.action, Phase0aDefenseAction.dodge);
    expect(started.fromPosition, before);
    expect(started.toPosition, after);
    expect(started.windowTicks, harness.tuning.dodgeIframeTicks);
    expect((after - before).length, harness.tuning.dodgeDistance);
    expect(
      harness.controller.state.player.dodgeTicksRemaining,
      harness.tuning.dodgeIframeTicks,
    );
    expect(
      tester
          .widget<Text>(find.text(UiStrings.phase0aDefenseDodgeKey))
          .style
          ?.color,
      WuxiaUi.qing,
    );
    expectDefenseStartedVisible(tester);
  });
}
