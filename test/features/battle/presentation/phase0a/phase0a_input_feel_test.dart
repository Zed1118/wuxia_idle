import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_defense_tuning.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_stage.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

final class _InputFeelHarness {
  const _InputFeelHarness({
    required this.controller,
    required this.tuning,
    this.nearestEnemyId,
    this.pointerEnemyId,
  });

  final Phase0aBattleController controller;
  final Phase0aDefenseTuning tuning;
  final String? nearestEnemyId;
  final String? pointerEnemyId;
}

void main() {
  const viewports = [Size(1280, 720), Size(1440, 900)];
  late GameRepository repository;

  setUpAll(() async => repository = await loadTestGameRepository());

  Finder defenseStatus(String action) =>
      find.byKey(ValueKey<String>('phase0a_defense_status_$action'));

  Future<_InputFeelHarness> pumpProductionScreen(
    WidgetTester tester, {
    Size viewport = const Size(1280, 720),
    bool arrangeAimScenario = false,
  }) async {
    final numbers = repository.numbers;
    final mapping = Phase0aStageContentMapper.map(
      stage: repository.getStage(
        arrangeAimScenario ? 'stage_light_foot_01' : 'stage_01_01',
      ),
      playerSnapshot: testCombatantSnapshot(
        name: 'input feel entry',
        includeProductionBasicAttack: true,
      ),
      numbers: numbers,
    );
    final tuning = mapping.playerAdapter.defenseTuning;
    expect(tuning, isNotNull, reason: '生产 Phase 0A mapping 必须装配防御 tuning');

    var initialState = mapping.initialState;
    var waves = mapping.waves;
    String? nearestEnemyId;
    String? pointerEnemyId;
    if (arrangeAimScenario) {
      expect(initialState.enemies, hasLength(3));
      final enemies = <Phase0aActor>[
        initialState.enemies[0].copyWith(position: const ArenaVector(-40, 0)),
        initialState.enemies[1].copyWith(position: const ArenaVector(120, 0)),
        initialState.enemies[2].copyWith(position: const ArenaVector(0, 200)),
      ];
      nearestEnemyId = enemies[0].id;
      pointerEnemyId = enemies[2].id;
      initialState = Phase0aArenaState(
        tick: initialState.tick,
        nextSeq: initialState.nextSeq,
        player: initialState.player.copyWith(
          position: ArenaVector.zero,
          facing: const ArenaVector(1, 0),
        ),
        enemies: enemies,
        skillSlots: initialState.skillSlots,
        winCondition: initialState.winCondition,
      );
      waves = <Phase0aWave>[Phase0aWave(enemies: enemies)];
    }

    final flow = Phase0aProductionFlowAssembler.assemble(
      initialState: initialState,
      waves: waves,
      combatants: mapping.combatants,
      moveBindings: mapping.moveBindings,
      numbers: numbers,
      rng: Random(20260828),
      playerAdapter: mapping.playerAdapter,
      enemyAiAdapter: mapping.enemyAiAdapter,
    );
    final controller = Phase0aBattleController(
      flow: flow,
      roster: Phase0aVisualRoster.fromMapping(mapping),
      fixedDeltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: controller, autoStep: false),
      ),
    );
    await tester.pump();
    return _InputFeelHarness(
      controller: controller,
      tuning: tuning!,
      nearestEnemyId: nearestEnemyId,
      pointerEnemyId: pointerEnemyId,
    );
  }

  Phase0aHitLanded playerHit(List<Phase0aEvent> events) => events
      .whereType<Phase0aHitLanded>()
      .singleWhere((event) => event.actor == 'player');

  testWidgets('J 不移动也会转向并命中侧后方最近存活敌人', (tester) async {
    final harness = await pumpProductionScreen(
      tester,
      arrangeAimScenario: true,
    );
    final before = harness.controller.state.player.position;

    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    final events = harness.controller.step();
    await tester.pump();

    expect(harness.controller.state.player.position, before);
    expect(playerHit(events).target, harness.nearestEnemyId);
    expect(harness.controller.state.player.facing.x, lessThan(0));
  });

  testWidgets('鼠标仍按指针方向命中而不被最近敌人覆盖', (tester) async {
    final harness = await pumpProductionScreen(
      tester,
      arrangeAimScenario: true,
    );
    final pointerEnemy = harness.controller.state.enemies.singleWhere(
      (enemy) => enemy.id == harness.pointerEnemyId,
    );
    final stage = Phase0aStage(viewport: const Size(1280, 720));

    await tester.tapAt(stage.worldToScreen(pointerEnemy.position));
    await tester.pump();
    final events = harness.controller.step();
    await tester.pump();

    expect(playerHit(events).target, harness.pointerEnemyId);
    expect(harness.controller.state.player.facing.y, greaterThan(0));
  });

  testWidgets('Space 是聚焦战斗屏唯一闪避入口', (tester) async {
    final harness = await pumpProductionScreen(tester);
    final before = harness.controller.state.player.position;
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'phase0a-battle-input',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
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
  });

  for (final (key, label) in [
    (LogicalKeyboardKey.keyE, 'E'),
    (LogicalKeyboardKey.keyF, 'F'),
    (LogicalKeyboardKey.keyZ, 'Z'),
  ]) {
    testWidgets('$label 不再从玩家战斗屏发出防御动作', (tester) async {
      final harness = await pumpProductionScreen(tester);
      final before = harness.controller.state.player;

      await tester.sendKeyEvent(key);
      final events = harness.controller.step();
      await tester.pump();

      expect(events.whereType<Phase0aDefenseStarted>(), isEmpty);
      expect(harness.controller.state.player.position, before.position);
      expect(harness.controller.state.player.shieldRemaining, 0);
      expect(harness.controller.state.player.parryTicksRemaining, 0);
      expect(harness.controller.state.player.dodgeTicksRemaining, 0);
    });
  }

  for (final viewport in viewports) {
    testWidgets('$viewport 只显示 Space 闪避状态', (tester) async {
      await pumpProductionScreen(tester, viewport: viewport);

      final status = defenseStatus('dodge');
      expect(status, findsOneWidget);
      expect(tester.widget<Text>(status).data, UiStrings.skillReady);
      expect(tester.getSize(status).width, greaterThan(0));
      expect(tester.getSize(status).height, greaterThan(0));
      expect(defenseStatus('shield'), findsNothing);
      expect(defenseStatus('parry'), findsNothing);
      expect(find.text(UiStrings.phase0aDefenseDodgeKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Space 闪避后只有闪避状态显示冷却', (tester) async {
    final harness = await pumpProductionScreen(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    harness.controller.step();
    await tester.pump();

    final remaining = harness.controller.state.player.defenseCooldownRemaining;
    expect(remaining, greaterThan(0));
    final expected = UiStrings.phase0aSealCooldown(remaining);
    expect(tester.widget<Text>(defenseStatus('dodge')).data, expected);
    expect(defenseStatus('shield'), findsNothing);
    expect(defenseStatus('parry'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
