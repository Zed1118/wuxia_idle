import 'dart:io';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/gameplay/combat_rules.dart';
import 'package:phase0minus_probe/gameplay/gameplay_game.dart';

void main() {
  late ProbeConfig config;

  setUpAll(() {
    config = ProbeConfig.parse(
      File('assets/probe_scenarios.yaml').readAsStringSync(),
    );
  });

  Future<GameplayGame> mountGame(
    WidgetTester tester, {
    void Function(Map<String, Object?> report)? onSessionEnded,
  }) async {
    final game = GameplayGame(config: config, onSessionEnded: onSessionEnded);
    await tester.pumpWidget(
      MaterialApp(home: GameWidget<GameplayGame>(game: game)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    return game;
  }

  testWidgets('keyboard movement is normalized and focus clear stops it', (
    tester,
  ) async {
    final game = await mountGame(tester);
    final start = game.player.position.clone();
    game.onKeyEvent(
      KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyD,
        logicalKey: LogicalKeyboardKey.keyD,
        timeStamp: Duration.zero,
      ),
      {LogicalKeyboardKey.keyD},
    );

    game.update(0.1);
    expect(game.player.position.x, greaterThan(start.x));
    final moved = game.player.position.clone();
    game.clearInput();
    game.update(0.1);
    expect(game.player.position.x, closeTo(moved.x, 0.001));
  });

  testWidgets('GameWidget focus dispatches real keyboard events', (
    tester,
  ) async {
    final game = GameplayGame(config: config);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: GameWidget<GameplayGame>(
          game: game,
          focusNode: focusNode,
          autofocus: true,
        ),
      ),
    );
    await tester.pump();
    final start = game.player.position.clone();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
    game.update(0.1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);

    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(game.player.position.x, greaterThan(start.x));
  });

  testWidgets('one click attacks once and grants qi once', (tester) async {
    final game = await mountGame(tester);
    final enemy = game.enemies.first;
    enemy
      ..spawnGrace = 99
      ..position = game.player.position + Vector2(100, 0);
    game.updatePointer(Vector2(900, 360));
    game.setPrimaryHeld(true);
    game.setPrimaryHeld(false);

    game.update(0.01);
    game.update(0.06);
    expect(enemy.health, 66);
    expect(game.player.qi, 45);
    game.update(0.25);
    expect(game.counters.basicUses, 1);
  });

  testWidgets('Q then R clears an imbalanced normal but naked R does not', (
    tester,
  ) async {
    final game = await mountGame(tester);
    final enemy = game.enemies.first;
    enemy
      ..spawnGrace = 99
      ..position = game.player.position + Vector2(180, 0);
    game.pointerWorld = game.player.position + Vector2(160, 0);

    game.player.requestGather();
    game.update(0.31);
    expect(enemy.imbalanceRemaining, greaterThan(0));
    game.update(0.30);
    game.player.qi = 100;
    game.player.requestClear();
    game.update(0.30);
    expect(enemy.alive, isFalse);

    final naked = game.enemies.firstWhere((candidate) => candidate.alive);
    naked
      ..spawnGrace = 99
      ..position = game.player.position + Vector2(120, 0);
    // Finish the previous clear recovery after its 65 ms hit-stop.
    game.update(0.60);
    game.player.qi = 100;
    game.player.requestClear();
    game.update(0.30);
    expect(naked.health, 35);
    expect(naked.alive, isTrue);
  });

  testWidgets('defeat emits one structured playtest report', (tester) async {
    final reports = <Map<String, Object?>>[];
    final game = await mountGame(tester, onSessionEnded: reports.add);
    game.player.health = 7;

    game.damagePlayer(7, game.player.position + Vector2(10, 0));
    game.damagePlayer(7, game.player.position + Vector2(10, 0));

    expect(reports, hasLength(1));
    expect(reports.single['outcome'], 'defeat');
    expect(reports.single['damage_events'], 1);
    expect(reports.single['actions'], isA<Map<String, int>>());
    expect(reports.single['session_serial'], 1);
    expect(reports.single['replay_requested'], isFalse);

    game.requestReplay();
    expect(reports, hasLength(2));
    expect(reports.last['session_serial'], 1);
    expect(reports.last['outcome'], 'defeat');
    expect(reports.last['replay_requested'], isTrue);
  });

  testWidgets('pause restores between-wave phase', (tester) async {
    final game = await mountGame(tester);
    game.phase = GameplayPhase.betweenWaves;

    game.togglePause();
    expect(game.phase, GameplayPhase.paused);
    game.togglePause();

    expect(game.phase, GameplayPhase.betweenWaves);
  });

  testWidgets('session reset reproduces seeded spawn positions', (
    tester,
  ) async {
    final game = await mountGame(tester);
    final firstRun = game.enemies
        .map((enemy) => enemy.position.clone())
        .toList();

    game.resetSession();
    await tester.pump();
    final secondRun = game.enemies
        .map((enemy) => enemy.position.clone())
        .toList();

    expect(secondRun, hasLength(firstRun.length));
    for (var index = 0; index < firstRun.length; index++) {
      expect(secondRun[index].x, firstRun[index].x);
      expect(secondRun[index].y, firstRun[index].y);
    }
  });

  testWidgets('one buffered command executes after basic recovery', (
    tester,
  ) async {
    final game = await mountGame(tester);
    game.setPrimaryHeld(true);
    game.setPrimaryHeld(false);
    game.update(0.01);
    game.update(0.20);
    expect(game.player.action, PlayerAction.basic);

    expect(game.player.requestGather(), isFalse);
    game.update(0.10);
    game.update(0.01);

    expect(game.player.action, PlayerAction.gather);
  });

  testWidgets('compressed replay reuses 21 resident enemies', (tester) async {
    final game = GameplayGame(config: config, deterministicReplay: true);
    await tester.pumpWidget(
      MaterialApp(home: GameWidget<GameplayGame>(game: game)),
    );
    await tester.pump();

    expect(game.enemies, hasLength(21));
    expect(game.enemies.where((enemy) => enemy.alive), hasLength(10));
    game.update(8.1);

    expect(game.enemies.where((enemy) => enemy.alive), hasLength(21));
    expect(game.replayPeakCount, greaterThanOrEqualTo(1));
    game.enemies[0].position = game.player.position.clone();
    game.enemies[1].position = game.player.position.clone();
    game.update(1 / 60);
    game.enemiesInRadius(game.player.position, 340).toList();
    final collision =
        game.replayWorkloadSnapshot()['collision_workload']!
            as Map<String, Object?>;
    expect(collision['resident_hitboxes'], 22);
    expect(collision['contact_starts'], greaterThan(0));
    expect(collision['range_query_count'], greaterThan(0));
    expect(collision['range_query_hits'], greaterThan(0));
    expect(
      game.replayPoolSnapshot()['enemy_residents'],
      containsPair('invariant_holds', true),
    );
  });

  testWidgets('normal attack leases stay at three and starts are staggered', (
    tester,
  ) async {
    final game = await mountGame(tester);
    final normals = game.enemies.where((enemy) => !enemy.elite).toList();
    for (var index = 0; index < normals.length; index++) {
      normals[index]
        ..spawnGrace = 0
        ..attackCooldown = 0
        ..position = game.player.position + Vector2(45 + index * 2, 0);
    }

    final firstStartAt = <int, double>{};
    var maximumAttackers = 0;
    for (var frame = 0; frame < 90; frame++) {
      game.update(1 / 60);
      final attackers = normals
          .where((enemy) => enemy.mode == EnemyMode.attack)
          .toList();
      maximumAttackers = math.max(maximumAttackers, attackers.length);
      for (final enemy in attackers) {
        firstStartAt.putIfAbsent(enemy.id, () => frame / 60);
      }
    }

    expect(maximumAttackers, lessThanOrEqualTo(3));
    final starts = firstStartAt.values.toList()..sort();
    expect(starts.length, greaterThanOrEqualTo(3));
    for (var index = 1; index < starts.length; index++) {
      expect(starts[index] - starts[index - 1], greaterThanOrEqualTo(0.16));
    }
    expect(game.telemetry.peakConcurrentNormalAttackers, lessThanOrEqualTo(3));
  });

  testWidgets('resident feedback pool survives the compressed clear burst', (
    tester,
  ) async {
    final game = GameplayGame(config: config, deterministicReplay: true);
    await tester.pumpWidget(
      MaterialApp(home: GameWidget<GameplayGame>(game: game)),
    );
    await tester.pump();

    for (var frame = 0; frame < 750; frame++) {
      game.update(1 / 60);
    }

    final feedback =
        game.replayPoolSnapshot()['feedback_residents']!
            as Map<String, Object?>;
    expect(feedback['created_total'], 160);
    expect(feedback['active_peak'], greaterThanOrEqualTo(128));
    expect(feedback['emitted_total'], greaterThanOrEqualTo(160));
    expect(feedback['overflow_total'], 0);
    expect(feedback['allocation_after_warmup'], 0);
    expect(feedback['invariant_holds'], isTrue);
  });
}
