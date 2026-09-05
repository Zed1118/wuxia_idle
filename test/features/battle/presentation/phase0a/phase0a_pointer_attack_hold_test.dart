import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';

import '../../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  late String fixtureYaml;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    fixtureYaml = await loadTestAsset(Phase0aDebugBattleFixture.assetPath);
  });

  setUp(() {
    // Asset futures cached in a previous test's fake-async zone must not be
    // reused by the next widget test's freshly created zone.
    rootBundle.evict('data/narratives/phase0a_mouse_attack.yaml');
  });

  Future<Phase0aBattleController> pumpScreen(
    WidgetTester tester, {
    bool nextEnemyInRange = true,
    bool autoStep = true,
    bool quickVictory = false,
  }) async {
    // Keep real adapters, damage and flow; only arrange a deterministic target
    // death and a stationary next target to isolate pointer lifecycle behavior.
    final yaml = parseYamlMap(fixtureYaml);
    final waves = yaml['waves'] as List;
    final firstEnemies = (waves.first as Map)['enemies'] as List;
    (firstEnemies[0] as Map)['max_health'] = 1;
    (firstEnemies[0] as Map)['position'] = [-250.0, -60.0];
    (firstEnemies[1] as Map)['max_health'] = quickVictory ? 1 : 20000;
    if (quickVictory) yaml['waves'] = [waves.first];
    (firstEnemies[1] as Map)['position'] = nextEnemyInRange
        ? [-200.0, 100.0]
        : [300.0, 100.0];
    ((yaml['enemy_templates'] as Map)['normal'] as Map)['move_speed'] = 0.0;
    final fixture = await Phase0aDebugBattleFixture.load(
      numbers: repository.numbers,
      assetLoader: (path) => path == Phase0aDebugBattleFixture.assetPath
          ? Future.value(jsonEncode(yaml))
          : loadTestAsset(path),
    );
    final controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(
          controller: controller,
          autoStep: autoStep,
          retryFlowBuilder: () async => fixture.fresh().flow,
          basicAttackRange: fixture.playerAdapter.attackRange,
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  Future<TestGesture> holdFirstEnemy(WidgetTester tester) =>
      tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('phase0a_actor_visual_wave1_blade')),
        ),
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );

  Future<void> advance(WidgetTester tester, [int frames = 12]) async {
    for (var index = 0; index < frames; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  int attackCount(Phase0aBattleController controller) => controller.events
      .whereType<Phase0aAttackStarted>()
      .where((event) => event.actor == 'player')
      .length;

  final automaticStatus = find.byKey(
    const ValueKey('phase0a_automatic_attack_status'),
  );

  Future<void> activate(WidgetTester tester, {bool ground = false}) async {
    final gesture = ground
        ? await tester.startGesture(
            const Offset(640, 520),
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          )
        : await holdFirstEnemy(tester);
    await advance(tester, 21);
    expect(automaticStatus, findsOneWidget);
    await gesture.up();
  }

  testWidgets(
    'two seconds of real pointer hold activates even with simulation stopped',
    (tester) async {
      final controller = await pumpScreen(tester, autoStep: false);
      final hud = find.byKey(const ValueKey('phase0a_player_hud'));
      final hudHeight = tester.getSize(hud).height;
      final gesture = await holdFirstEnemy(tester);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(automaticStatus, findsNothing);
      expect(controller.state.tick, 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(automaticStatus, findsOneWidget);
      expect(tester.getSize(hud).height, hudHeight);
      expect(controller.state.tick, 0);
      await gesture.up();
      await tester.pump();
      expect(automaticStatus, findsOneWidget);
    },
  );

  testWidgets(
    'automatic left attack survives release and target death; click cancels without moving',
    (tester) async {
      final controller = await pumpScreen(tester);
      final start = controller.state.player.position;
      await activate(tester);
      expect(
        controller.state.enemies.any((enemy) => enemy.id == 'wave1_blade'),
        isFalse,
      );
      final before = attackCount(controller);
      await advance(tester);
      expect(attackCount(controller), greaterThan(before));
      expect(
        controller.events.whereType<Phase0aHitLanded>().any(
          (event) => event.actor == 'player' && event.target == 'wave1_archer',
        ),
        isTrue,
      );
      expect(controller.state.player.position, start);
      await tester.tapAt(const Offset(780, 530));
      await tester.pump();
      expect(automaticStatus, findsNothing);
      final stopped = attackCount(controller);
      await advance(tester);
      expect(attackCount(controller), stopped);
      expect(controller.state.player.position, start);
    },
  );

  testWidgets(
    'ground hold enables automatic attacks without chasing a distant enemy',
    (tester) async {
      final controller = await pumpScreen(tester, nextEnemyInRange: false);
      await activate(tester, ground: true);
      final position = controller.state.player.position;
      await advance(tester, 30);
      expect(automaticStatus, findsOneWidget);
      expect(controller.state.player.position, position);
      expect(
        controller.events.whereType<Phase0aHitLanded>().where(
          (event) => event.actor == 'player' && event.target == 'wave1_archer',
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'Q targeting click and R preserve automatic attack; no automatic skills',
    (tester) async {
      final controller = await pumpScreen(tester);
      await activate(tester);
      expect(controller.events.whereType<Phase0aGatherStarted>(), isEmpty);
      expect(controller.events.whereType<Phase0aClearStarted>(), isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.tapAt(const Offset(700, 410));
      await advance(tester, 3);
      expect(controller.events.whereType<Phase0aGatherStarted>(), hasLength(1));
      expect(automaticStatus, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      final before = attackCount(controller);
      await advance(tester);
      expect(controller.events.whereType<Phase0aClearStarted>(), hasLength(1));
      expect(automaticStatus, findsOneWidget);
      expect(attackCount(controller), greaterThan(before));
    },
  );

  testWidgets(
    'short ground clicks stay movement only and never arm automatic attacks',
    (tester) async {
      final controller = await pumpScreen(tester);
      final start = controller.state.player.position;
      await tester.tapAt(const Offset(640, 520));
      await advance(tester, 30);
      expect(controller.state.player.position, isNot(start));
      expect(automaticStatus, findsNothing);
      expect(attackCount(controller), 0);
    },
  );

  for (final interruption in ['focus loss', 'pause', 'pointer cancel']) {
    testWidgets(
      '$interruption clears automatic attacks and pending activation',
      (tester) async {
        final controller = await pumpScreen(tester);
        await activate(tester);
        final before = attackCount(controller);
        switch (interruption) {
          case 'focus loss':
            FocusManager.instance.primaryFocus?.unfocus();
            await tester.pump();
          case 'pause':
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await advance(tester, 3);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          case 'pointer cancel':
            // A new press first cancels the toggle; cancellation must also leave
            // no pending activation timer behind.
            final gesture = await tester.startGesture(
              const Offset(780, 530),
              kind: PointerDeviceKind.mouse,
              buttons: kPrimaryMouseButton,
            );
            await gesture.cancel();
        }
        await advance(tester, 30);
        expect(automaticStatus, findsNothing);
        expect(attackCount(controller), before);
      },
    );
  }

  testWidgets(
    'pause before the two-second threshold prevents delayed activation after resume',
    (tester) async {
      await pumpScreen(tester);
      final gesture = await holdFirstEnemy(tester);
      await advance(tester, 10);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await advance(tester, 15);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await advance(tester, 25);
      expect(automaticStatus, findsNothing);
      await gesture.up();
    },
  );

  testWidgets(
    'terminal and retry clear automatic attack and its activation timer',
    (tester) async {
      final controller = await pumpScreen(tester, quickVictory: true);
      final gesture = await holdFirstEnemy(tester);
      await advance(tester, 40);
      expect(controller.outcome, Phase0aBattleOutcome.victory);
      expect(automaticStatus, findsNothing);
      await gesture.up();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await advance(tester, 30);
      expect(controller.outcome, Phase0aBattleOutcome.ongoing);
      expect(automaticStatus, findsNothing);
      expect(attackCount(controller), 0);
    },
  );

  testWidgets(
    'leaving the application cancels both active and pending automatic attacks',
    (tester) async {
      final controller = await pumpScreen(tester);
      await activate(tester);
      final before = attackCount(controller);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await advance(tester, 3);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await advance(tester, 25);
      expect(automaticStatus, findsNothing);
      expect(attackCount(controller), before);

      final gesture = await tester.startGesture(
        const Offset(780, 530),
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await advance(tester, 10);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await advance(tester, 15);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await advance(tester, 25);
      expect(automaticStatus, findsNothing);
      await gesture.up();
    },
  );
}
