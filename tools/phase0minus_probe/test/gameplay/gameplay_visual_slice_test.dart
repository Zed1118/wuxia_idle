import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/gameplay/gameplay_game.dart';
import 'package:phase0minus_probe/main.dart' show GameplayHud;

void main() {
  late ProbeConfig config;

  setUpAll(() {
    config = ProbeConfig.parse(
      File('assets/probe_scenarios.yaml').readAsStringSync(),
    );
  });

  Future<void> pumpUntilLoaded(WidgetTester tester, GameplayGame game) async {
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 60 && !game.isLoaded; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pump();
    expect(game.isLoaded, isTrue, reason: 'Gameplay art must finish loading');
  }

  testWidgets('playtest path mounts the art-backed battlefield component', (
    tester,
  ) async {
    final game = GameplayGame(config: config, loadArt: false);
    await tester.pumpWidget(
      MaterialApp(home: GameWidget<GameplayGame>(game: game)),
    );
    await tester.pump();
    await pumpUntilLoaded(tester, game);
    await tester.pump();

    expect(game.world.children.whereType<GameplayBackdrop>(), hasLength(1));
  });

  test('playtest art loader owns all four runtime assets', () {
    final source = File('lib/gameplay/gameplay_art.dart').readAsStringSync();
    expect(source, contains('scroll_panorama_mountain_to_gate_v1.png'));
    expect(source, contains('founder_pose_atlas_v1.png'));
    expect(source, contains('bandit_pose_atlas_v1.png'));
    expect(source, contains('elite_pose_atlas_v1.png'));
  });

  testWidgets('actor priorities follow foot position for shallow depth', (
    tester,
  ) async {
    final game = GameplayGame(config: config, loadArt: false);
    await tester.pumpWidget(
      MaterialApp(home: GameWidget<GameplayGame>(game: game)),
    );
    await tester.pump();
    await pumpUntilLoaded(tester, game);
    await tester.pump();

    final enemy = game.enemies.first;
    game.player.position.y = game.combatBottom - 40;
    enemy.position.y = game.combatTop + 40;
    game.update(1 / 60);

    expect(game.player.priority, greaterThan(enemy.priority));
  });

  testWidgets('combat HUD exposes three equal-action controls', (tester) async {
    final game = GameplayGame(config: config, loadArt: false);
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            GameWidget<GameplayGame>(game: game),
            GameplayHud(game: game),
          ],
        ),
      ),
    );
    await tester.pump();
    await pumpUntilLoaded(tester, game);
    await tester.pump();

    expect(find.text('SPACE'), findsOneWidget);
    expect(find.text('Q'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
    expect(find.text('STEP'), findsOneWidget);
    expect(find.text('GATHER'), findsOneWidget);
    expect(find.text('CLEAR'), findsOneWidget);
  });
}
