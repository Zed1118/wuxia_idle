import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_vfx_controller.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';

import '../../../support/test_data.dart';

void main() {
  late Phase0aDebugBattleFixture fixture;

  setUp(() async {
    await loadTestGameRepository();
    fixture = await Phase0aDebugBattleFixture.load(
      assetLoader: loadTestAsset,
      numbers: GameRepository.instance.numbers,
    );
  });

  tearDown(GameRepository.resetForTest);

  test('typed YAML builds the frozen two-wave real flow and root roster', () {
    expect(fixture.seed, 20260816);
    expect(fixture.fixedDeltaSeconds, 0.1);
    expect(fixture.arenaMin, const ArenaVector(-640, -260));
    expect(fixture.arenaMax, const ArenaVector(640, 260));

    final state = fixture.flow.state;
    expect(state.player.id, 'player');
    expect(state.player.position, const ArenaVector(-320, 0));
    expect(state.player.maxHealth, 15000);
    expect(state.player.moveSpeed, 210);
    expect(state.player.qiCurrent, 100);
    expect(state.skillSlots.map((slot) => slot.slot), ['gather', 'clear']);
    expect(fixture.flow.waves, hasLength(2));
    expect(
      fixture.flow.waves
          .expand((wave) => wave.enemies)
          .map((enemy) => enemy.maxHealth),
      [1800, 2400, 1800, 2400, 6000],
    );
    expect(
      fixture.flow.waves.last.enemies.last.defeatKind,
      Phase0aDefeatKind.elite,
    );

    for (final actor in [
      state.player,
      ...fixture.flow.waves.expand((wave) => wave.enemies),
    ]) {
      final visual = fixture.roster.visualFor(actor.id);
      expect(File(visual.assetPath).existsSync(), isTrue, reason: actor.id);
    }
  });

  test(
    'controller merges queued input and consumes exact real-flow events',
    () {
      final controller = Phase0aBattleController(
        flow: fixture.flow,
        roster: fixture.roster,
        fixedDeltaSeconds: fixture.fixedDeltaSeconds,
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      final before = controller.state.player.position;

      controller.enqueue(const Phase0aPlayerCommand(right: true));
      controller.enqueue(const Phase0aPlayerCommand(attack: true));
      final events = controller.step();

      expect(controller.state.player.position.x, greaterThan(before.x));
      expect(controller.lastEvents, events);
      expect(
        events.map((event) => event.seq).toList(),
        orderedEquals([...events.map((event) => event.seq)]..sort()),
      );
      final hit = events.whereType<Phase0aHitLanded>().singleWhere(
        (event) => event.actor == 'player',
      );
      expect(hit.resolvedDamage, greaterThan(0));
      expect(
        controller.feedback.any(
          (entry) =>
              entry.kind == Phase0aVfxKind.damagePopup &&
              entry.damage == hit.resolvedDamage,
        ),
        isTrue,
      );
      expect(
        controller.feedback.any(
          (entry) => entry.kind == Phase0aVfxKind.palmTrail,
        ),
        isTrue,
      );
      expect(notifications, 1);
    },
  );

  test('terminal state is lazy and preserves the unique outcome feedback', () {
    final controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
    var guard = 0;
    while (controller.outcome == Phase0aBattleOutcome.ongoing && guard < 600) {
      final player = controller.state.player.position;
      final enemies = controller.state.enemies;
      final target = enemies.isEmpty ? null : enemies.first;
      final dx = target == null ? 0.0 : target.position.x - player.x;
      final dy = target == null ? 0.0 : target.position.y - player.y;
      controller.step(
        Phase0aPlayerCommand(
          attack: true,
          clear: true,
          right: dx > 1,
          left: dx < -1,
          down: dy > 1,
          up: dy < -1,
        ),
      );
      guard++;
    }
    expect(controller.outcome, Phase0aBattleOutcome.victory);
    expect(
      controller.feedback.where(
        (entry) => entry.kind == Phase0aVfxKind.outcomeSeal,
      ),
      hasLength(1),
    );
    final feedback = controller.feedback;
    final state = controller.state;
    final events = controller.step(const Phase0aPlayerCommand(attack: true));
    expect(events, isEmpty);
    expect(controller.state, same(state));
    expect(controller.feedback, same(feedback));
  });
}
