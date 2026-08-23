import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';

final class SeededDamageResolver implements Phase0aDamageResolver {
  SeededDamageResolver(int seed) : _random = math.Random(seed);

  final math.Random _random;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderCharging = false,
    double defenderWardMult = 1.0,
  }) => Phase0aResolvedHit(
    isHit: true,
    isCritical: _random.nextBool(),
    damage: 20 + _random.nextInt(11),
  );
}

final _playerAdapter = const Phase0aPlayerInputAdapter(
  playerId: 'player',
  attackRange: 120,
  attackHalfArcRadians: math.pi / 4,
  attackCooldownSeconds: 1,
  attackQiDelta: 0,
  gatherSlot: 'gather',
  gatherRingRadius: 90,
  gatherEffectRadius: 500,
  gatherQiCost: 20,
  gatherCooldownSeconds: 3,
  clearSlot: 'clear',
  clearEffectRadius: 500,
  clearQiCost: 30,
  clearCooldownSeconds: 4,
);

final _enemyAdapter = const Phase0aEnemyAiAdapter(
  attackRange: 70,
  attackHalfArcRadians: math.pi / 3,
  attackCooldownSeconds: 1.2,
);

Phase0aActor _actor({
  required String id,
  required Phase0aSide side,
  required int health,
  required ArenaVector position,
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: side == Phase0aSide.player
      ? const ArenaVector(1, 0)
      : const ArenaVector(-1, 0),
  maxHealth: health,
  currentHealth: health,
  moveSpeed: 60,
  qiCurrent: 0,
  qiMax: 0,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aWaveBattleFlow _legacy({
  required int seed,
  required int playerHealth,
  required int enemyHealth,
  required ArenaVector enemyPosition,
}) {
  final player = _actor(
    id: 'player',
    side: Phase0aSide.player,
    health: playerHealth,
    position: const ArenaVector(0, 0),
  );
  final enemy = _actor(
    id: 'enemy',
    side: Phase0aSide.enemy,
    health: enemyHealth,
    position: enemyPosition,
  );
  final initialState = Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: player,
    enemies: [enemy],
    skillSlots: const [
      Phase0aSkillSlot(
        slot: 'gather',
        cooldownRemaining: 0,
        qiCost: 20,
        availability: Phase0aSkillAvailability.ready,
      ),
      Phase0aSkillSlot(
        slot: 'clear',
        cooldownRemaining: 0,
        qiCost: 30,
        availability: Phase0aSkillAvailability.ready,
      ),
    ],
  );
  return Phase0aWaveBattleFlow(
    session: Phase0aCombatSession(
      initialState: initialState,
      playerAdapter: _playerAdapter,
      enemyAiAdapter: _enemyAdapter,
      damageResolver: SeededDamageResolver(seed),
    ),
    waves: [
      Phase0aWave(enemies: [enemy]),
    ],
  );
}

void expectParity(
  Phase0aBattleFlow legacy,
  Phase0aBattleFlow compatibility,
  List<Phase0aPlayerCommand> commands,
) {
  for (final command in commands) {
    final legacyEvents = legacy.advance(deltaSeconds: 1, command: command);
    final compatibilityEvents = compatibility.advance(
      deltaSeconds: 1,
      command: command,
    );
    expect(compatibility.state, legacy.state);
    expect(compatibilityEvents, legacyEvents);
    expect(
      compatibility.lastOrderedEventRecords,
      legacy.lastOrderedEventRecords,
    );
    expect(compatibility.outcome, legacy.outcome);
  }
}

void main() {
  test(
    'compatibility delegates exact per-tick state/events/records/outcome',
    () {
      final legacy = _legacy(
        seed: 42,
        playerHealth: 100,
        enemyHealth: 90,
        enemyPosition: const ArenaVector(50, 0),
      );
      final compatibility = Phase0aEncounterFlow.compatibility(
        legacy: _legacy(
          seed: 42,
          playerHealth: 100,
          enemyHealth: 90,
          enemyPosition: const ArenaVector(50, 0),
        ),
      );
      expectParity(legacy, compatibility, const [
        Phase0aPlayerCommand(attack: true),
        Phase0aPlayerCommand(attack: true),
        Phase0aPlayerCommand(attack: true),
      ]);
    },
  );

  test('terminal advance remains exactly idempotent', () {
    final legacy = _legacy(
      seed: 42,
      playerHealth: 100,
      enemyHealth: 10,
      enemyPosition: const ArenaVector(50, 0),
    );
    final compatibility = Phase0aEncounterFlow.compatibility(
      legacy: _legacy(
        seed: 42,
        playerHealth: 100,
        enemyHealth: 10,
        enemyPosition: const ArenaVector(50, 0),
      ),
    );
    expectParity(legacy, compatibility, const [
      Phase0aPlayerCommand(attack: true),
    ]);
    expect(legacy.outcome, Phase0aBattleOutcome.victory);
    expectParity(legacy, compatibility, const [
      Phase0aPlayerCommand(attack: true),
      Phase0aPlayerCommand(attack: true),
    ]);
  });

  test('headless victory, defeat, and ongoing results preserve parity', () {
    final scenarios = [
      (
        playerHealth: 100,
        enemyHealth: 10,
        enemyPosition: const ArenaVector(50, 0),
        expected: Phase0aBattleOutcome.victory,
      ),
      (
        playerHealth: 10,
        enemyHealth: 100,
        enemyPosition: const ArenaVector(50, 0),
        expected: Phase0aBattleOutcome.defeat,
      ),
      (
        playerHealth: 100,
        enemyHealth: 1000,
        enemyPosition: const ArenaVector(500, 0),
        expected: Phase0aBattleOutcome.ongoing,
      ),
    ];
    for (final scenario in scenarios) {
      final legacy = _legacy(
        seed: 42,
        playerHealth: scenario.playerHealth,
        enemyHealth: scenario.enemyHealth,
        enemyPosition: scenario.enemyPosition,
      );
      final compatibility = Phase0aEncounterFlow.compatibility(
        legacy: _legacy(
          seed: 42,
          playerHealth: scenario.playerHealth,
          enemyHealth: scenario.enemyHealth,
          enemyPosition: scenario.enemyPosition,
        ),
      );
      final legacyResult = Phase0aHeadlessRunner.runToEnd(
        flow: legacy,
        bot: Phase0aPlayerBotAdapter(playerAdapter: _playerAdapter),
        deltaSeconds: 1,
        maxTicks: 3,
      );
      final compatibilityResult = Phase0aHeadlessRunner.runToEnd(
        flow: compatibility,
        bot: Phase0aPlayerBotAdapter(playerAdapter: _playerAdapter),
        deltaSeconds: 1,
        maxTicks: 3,
      );
      expect(legacyResult.outcome, scenario.expected);
      expect(compatibilityResult.outcome, legacyResult.outcome);
      expect(compatibilityResult.ticks, legacyResult.ticks);
      expect(compatibilityResult.finalState, legacyResult.finalState);
      expect(compatibilityResult.events, legacyResult.events);
      expect(compatibilityResult.eventRecords, legacyResult.eventRecords);
    }
  });

  test('async headless victory, defeat, and ongoing preserve parity', () async {
    final scenarios = [
      (
        playerHealth: 100,
        enemyHealth: 10,
        enemyPosition: const ArenaVector(50, 0),
        expected: Phase0aBattleOutcome.victory,
      ),
      (
        playerHealth: 10,
        enemyHealth: 100,
        enemyPosition: const ArenaVector(50, 0),
        expected: Phase0aBattleOutcome.defeat,
      ),
      (
        playerHealth: 100,
        enemyHealth: 1000,
        enemyPosition: const ArenaVector(500, 0),
        expected: Phase0aBattleOutcome.ongoing,
      ),
    ];
    for (final scenario in scenarios) {
      final legacy = _legacy(
        seed: 42,
        playerHealth: scenario.playerHealth,
        enemyHealth: scenario.enemyHealth,
        enemyPosition: scenario.enemyPosition,
      );
      final compatibility = Phase0aEncounterFlow.compatibility(
        legacy: _legacy(
          seed: 42,
          playerHealth: scenario.playerHealth,
          enemyHealth: scenario.enemyHealth,
          enemyPosition: scenario.enemyPosition,
        ),
      );
      final legacyResult = await Phase0aHeadlessRunner.runToEndAsync(
        flow: legacy,
        bot: Phase0aPlayerBotAdapter(playerAdapter: _playerAdapter),
        deltaSeconds: 1,
        maxTicks: 3,
        yieldEveryTicks: 1,
      );
      final compatibilityResult = await Phase0aHeadlessRunner.runToEndAsync(
        flow: compatibility,
        bot: Phase0aPlayerBotAdapter(playerAdapter: _playerAdapter),
        deltaSeconds: 1,
        maxTicks: 3,
        yieldEveryTicks: 1,
      );
      expect(legacyResult.outcome, scenario.expected);
      expect(compatibilityResult.outcome, legacyResult.outcome);
      expect(compatibilityResult.ticks, legacyResult.ticks);
      expect(compatibilityResult.finalState, legacyResult.finalState);
      expect(compatibilityResult.events, legacyResult.events);
      expect(compatibilityResult.eventRecords, legacyResult.eventRecords);
    }
  });
}
