import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import 'package:wuxia_idle/features/debug/application/production_profile_keyboard_driver.dart';

import '../../../support/test_data.dart';

void main() {
  late Phase0aDebugBattleFixture fixture;
  late Phase0aBattleController controller;
  late ProductionProfileKeyboardDriver driver;
  var foreground = true;

  setUp(() async {
    await loadTestGameRepository();
    fixture = await Phase0aDebugBattleFixture.load(
      assetLoader: loadTestAsset,
      numbers: GameRepository.instance.numbers,
    );
    controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
    foreground = true;
    driver = ProductionProfileKeyboardDriver(
      controller: controller,
      basicAttackRange: fixture.playerAdapter.attackRange,
      isForeground: () => foreground,
    );
  });

  tearDown(() {
    driver.dispose();
    controller.dispose();
    GameRepository.resetForTest();
  });

  Future<void> focusSink(WidgetTester tester, List<KeyEvent> events) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          autofocus: true,
          onKeyEvent: (_, event) {
            events.add(event);
            return KeyEventResult.handled;
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> battleScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(
          controller: controller,
          basicAttackRange: fixture.playerAdapter.attackRange,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('KeyData reaches real Focus and HardwareKeyboard, then releases', (
    tester,
  ) async {
    final events = <KeyEvent>[];
    await focusSink(tester, events);
    final initialState = controller.state;
    driver.start();
    // Existing onboarding baseline: hold attack and approach the nearest enemy
    // at (0, -90) from (-320, 0), outside 90% of the configured attack range.
    final expectedKeys = {
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyW,
    };
    expect(
      events.whereType<KeyDownEvent>().map((event) => event.logicalKey).toSet(),
      expectedKeys,
    );
    expect(events.every((event) => event.synthesized), isTrue);
    expect(HardwareKeyboard.instance.logicalKeysPressed, expectedKeys);
    expect(controller.state, initialState);
    expect(driver.configurationMetadata['physical_os_input'], isFalse);
    driver.stop();
    expect(
      events.whereType<KeyUpEvent>().map((event) => event.logicalKey).toSet(),
      expectedKeys,
    );
    expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
    expect(driver.metadata['held_key_ids'], isEmpty);
  });

  testWidgets(
    'one decision per tick and foreground loss releases without ticks',
    (tester) async {
      final events = <KeyEvent>[];
      await focusSink(tester, events);
      driver.start();
      final configuration = driver.configurationMetadata;
      await tester.pump(const Duration(milliseconds: 500));
      driver.refreshForeground();
      expect(driver.metadata['decisions'], 1);
      controller.step();
      expect(driver.metadata['decisions'], 2);
      foreground = false;
      await tester.pump(const Duration(milliseconds: 100));
      expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
      expect(driver.metadata['decisions'], 2);
      controller.step();
      expect(driver.metadata['decisions'], 2);
      foreground = true;
      driver.refreshForeground();
      expect(driver.metadata['decisions'], 3);
      expect(driver.configurationMetadata, configuration);
      driver.dispose();
      final decisions = driver.metadata['decisions'];
      controller.step();
      await tester.pump(const Duration(milliseconds: 500));
      expect(driver.metadata['decisions'], decisions);
      expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
    },
  );

  testWidgets('baseline drives real screen movement and player damage', (
    tester,
  ) async {
    await battleScreen(tester);
    final entry = controller.state.player.position;
    driver.start();
    for (var tick = 0; tick < 60; tick++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(controller.state.tick, greaterThan(0));
    expect(controller.state.player.position, isNot(entry));
    expect(
      controller.events.whereType<Phase0aHitLanded>().any(
        (event) => event.actor == controller.state.player.id,
      ),
      isTrue,
    );
    driver.stop();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('survive permits real enemy damage without sending attack keys', (
    tester,
  ) async {
    driver.dispose();
    driver = ProductionProfileKeyboardDriver(
      controller: controller,
      basicAttackRange: fixture.playerAdapter.attackRange,
      isForeground: () => foreground,
      strategy: ProductionProfileKeyboardStrategy.survive,
    );
    final keyDowns = <LogicalKeyboardKey>[];
    bool observeKey(KeyEvent event) {
      if (event is KeyDownEvent) keyDowns.add(event.logicalKey);
      return false;
    }

    HardwareKeyboard.instance.addHandler(observeKey);
    addTearDown(() => HardwareKeyboard.instance.removeHandler(observeKey));
    await battleScreen(tester);
    final entry = controller.state.player.position;
    driver.start();
    for (var tick = 0; tick < 80; tick++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(controller.state.tick, greaterThan(0));
    expect(controller.state.player.position, isNot(entry));
    expect(keyDowns, isNotEmpty);
    expect(
      keyDowns.every(
        (key) => const [
          LogicalKeyboardKey.keyA,
          LogicalKeyboardKey.keyD,
          LogicalKeyboardKey.keyW,
          LogicalKeyboardKey.keyS,
          LogicalKeyboardKey.space,
        ].contains(key),
      ),
      isTrue,
    );
    expect(
      controller.events.whereType<Phase0aHitLanded>().where(
        (event) => event.actor == controller.state.player.id,
      ),
      isEmpty,
    );
    expect(controller.state.enemies.every((enemy) => enemy.isAlive), isTrue);
    driver.stop();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('terminal production screen stops driver and releases keys', (
    tester,
  ) async {
    await battleScreen(tester);
    driver.start();
    for (
      var tick = 0;
      tick < 600 && controller.outcome == Phase0aBattleOutcome.ongoing;
      tick++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(controller.outcome, isNot(Phase0aBattleOutcome.ongoing));
    expect(driver.metadata['running'], isFalse);
    expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
    expect(driver.metadata['held_key_ids'], isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
