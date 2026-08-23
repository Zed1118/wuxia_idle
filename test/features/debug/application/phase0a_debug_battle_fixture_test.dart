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

  test('fresh rebuilds independent mutable flow from cached config', () {
    final rebuilt = fixture.fresh();

    expect(rebuilt.seed, fixture.seed);
    expect(rebuilt.fixedDeltaSeconds, fixture.fixedDeltaSeconds);
    expect(rebuilt.flow, isNot(same(fixture.flow)));
    expect(rebuilt.flow.state, isNot(same(fixture.flow.state)));
    expect(rebuilt.flow.state.tick, fixture.flow.state.tick);
    expect(rebuilt.flow.state.player, fixture.flow.state.player);
    expect(rebuilt.flow.waves.length, fixture.flow.waves.length);
  });

  test('profile restart pool is bounded and contains independent flows', () {
    final pool = fixture.prewarmRestartPool(count: 4);

    expect(pool, hasLength(4));
    expect(pool.map((entry) => entry.flow).toSet(), hasLength(4));
    expect(
      pool.every((entry) => entry.flow.state.tick == fixture.flow.state.tick),
      isTrue,
    );
    expect(() => fixture.prewarmRestartPool(count: -1), throwsArgumentError);
  });

  test(
    'Boss fixture exposes chargeCast/vulnerability and breaks into stagger',
    () async {
      final bossFixture = await Phase0aDebugBattleFixture.load(
        assetLoader: loadTestAsset,
        numbers: GameRepository.instance.numbers,
        assetPath: 'data/phase0a_debug_boss_battle.yaml',
      );
      expect(bossFixture.playerAdapter.gatherSkillBinding!.cooldownSeconds, 5);
      expect(bossFixture.playerAdapter.clearSkillBinding!.cooldownSeconds, 8);
      final boss = bossFixture.flow.state.enemies.single;
      expect(boss.chargeCast, isNotNull);
      expect(boss.vulnerabilityMult, 0.15);
      expect(boss.staggerTicksTotal, 3);
      expect(bossFixture.flow.state.player.qiCurrent, 100);

      final controller = Phase0aBattleController(
        flow: bossFixture.flow,
        roster: bossFixture.roster,
        fixedDeltaSeconds: bossFixture.fixedDeltaSeconds,
      );
      final chargeEvents = controller.step();
      expect(chargeEvents.whereType<Phase0aBossChargeStarted>(), hasLength(1));
      expect(
        controller.feedback.map((entry) => entry.kind),
        contains(Phase0aVfxKind.bossChargeWarning),
      );
      expect(controller.state.enemies.single.chargingCast, isNotNull);

      controller.step(const Phase0aPlayerCommand(clear: true));
      expect(
        controller.lastEvents.whereType<Phase0aBossChargeInterrupted>(),
        hasLength(1),
      );
      expect(
        controller.feedback.map((entry) => entry.kind),
        contains(Phase0aVfxKind.bossChargeInterrupted),
      );
      expect(controller.state.enemies.single.chargingCast, isNull);
      expect(controller.state.enemies.single.staggerTicksRemaining, 3);
    },
  );

  test(
    'guardian visual fixture reaches ward, intercept, and coop through real flow',
    () async {
      final guardianFixture = await Phase0aDebugBattleFixture.load(
        assetLoader: loadTestAsset,
        numbers: GameRepository.instance.numbers,
        assetPath: 'data/phase0a_debug_guardian_mechanics.yaml',
      );
      final boss = guardianFixture.flow.state.enemies.first;
      expect(boss.guardianWardMult, 0.15);
      expect(boss.guardianDefIds, ['wave1_blade', 'wave1_archer']);
      expect(boss.guardInterceptsInterrupt, isTrue);
      expect(
        guardianFixture.flow.state.winCondition,
        const Phase0aWinCondition.surviveTicks(80),
      );

      final controller = Phase0aBattleController(
        flow: guardianFixture.flow,
        roster: guardianFixture.roster,
        fixedDeltaSeconds: guardianFixture.fixedDeltaSeconds,
      );
      var breakSent = false;
      final kinds = <Phase0aVfxKind>{};
      for (var i = 0; i < 80; i++) {
        final charging = controller.state.enemies.first.chargingCast != null;
        controller.step(
          !breakSent && charging
              ? const Phase0aPlayerCommand(clear: true)
              : null,
        );
        if (charging) breakSent = true;
        kinds.addAll(controller.feedback.map((entry) => entry.kind));
        if (kinds.contains(Phase0aVfxKind.guardIntercepted) &&
            kinds.contains(Phase0aVfxKind.guardianCoop)) {
          break;
        }
      }
      expect(kinds, contains(Phase0aVfxKind.guardIntercepted));
      expect(kinds, contains(Phase0aVfxKind.guardianCoop));
    },
  );

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

  test('events exposes one stable read-only view that grows incrementally', () {
    final controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
    final view = controller.events;
    expect(view, isEmpty);
    expect(() => view.clear(), throwsUnsupportedError);
    final firstLength = view.length;
    controller.step(const Phase0aPlayerCommand(attack: true));
    expect(controller.events, same(view));
    expect(view.length, greaterThan(firstLength));
    controller.restart(fixture.flow);
    expect(controller.events, same(view));
    expect(view, isEmpty);
  });

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
