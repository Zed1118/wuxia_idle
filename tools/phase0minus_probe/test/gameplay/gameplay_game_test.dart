import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/config/probe_config.dart';
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
    game.update(0.50);
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
  });
}
