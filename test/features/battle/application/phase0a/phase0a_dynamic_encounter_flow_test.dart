import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';

Phase0aActor _actor(
  String id, {
  required Phase0aSide side,
  int health = 100,
  ArenaVector position = const ArenaVector(50, 0),
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: const ArenaVector(1, 0),
  maxHealth: health,
  currentHealth: health,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

final class _FixedResolver implements Phase0aDamageResolver {
  _FixedResolver({
    this.damage = 0,
    this.throwOnce = false,
    this.playerOnly = false,
  });

  final int damage;
  final bool playerOnly;
  bool throwOnce;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderCharging = false,
    required double defenderWardMult,
  }) {
    if (throwOnce) {
      throwOnce = false;
      throw StateError('resolver failure');
    }
    final resolvedDamage = playerOnly && attackerId != 'player' ? 0 : damage;
    return Phase0aResolvedHit(
      isHit: resolvedDamage > 0,
      isCritical: false,
      damage: resolvedDamage,
    );
  }
}

class _Fixture {
  _Fixture({
    int enemyCount = 2,
    int damage = 0,
    bool throwOnce = false,
    bool playerOnly = false,
  }) {
    director = SpawnDirector(
      config: SpawnDirectorConfig(
        activeLimit: 1,
        reinforcementThreshold: 0,
        entryWarningTicks: 0,
        attackGraceTicks: 1,
      ),
      entries: [
        for (var i = 1; i <= enemyCount; i++)
          SpawnEntry(entryId: 'entry_$i', enemyId: 'enemy_$i'),
      ],
    );
    roster = Phase0aEncounterRoster(
      director: director,
      playerId: 'player',
      bindings: [
        for (final unit in director.state.units)
          Phase0aEncounterRosterBinding(
            entryId: unit.entryId,
            actor: _actor(unit.enemyId, side: Phase0aSide.enemy),
          ),
      ],
    );
    final session = Phase0aCombatSession(
      initialState: Phase0aArenaState(
        tick: 0,
        nextSeq: 0,
        player: _actor(
          'player',
          side: Phase0aSide.player,
          position: ArenaVector.zero,
        ),
        enemies: const [],
        skillSlots: const [],
      ),
      playerAdapter: const Phase0aPlayerInputAdapter(
        playerId: 'player',
        attackRange: 100,
        attackHalfArcRadians: 3.14,
        attackCooldownSeconds: 0,
        attackQiDelta: 0,
        gatherSlot: 'gather',
        gatherRingRadius: 1,
        gatherEffectRadius: 1,
        gatherQiCost: 0,
        gatherCooldownSeconds: 0,
        clearSlot: 'clear',
        clearEffectRadius: 1,
        clearQiCost: 0,
        clearCooldownSeconds: 0,
      ),
      enemyAiAdapter: const Phase0aEnemyAiAdapter(
        attackRange: 100,
        attackHalfArcRadians: 3.14,
        attackCooldownSeconds: 0,
      ),
      damageResolver: _FixedResolver(
        damage: damage,
        throwOnce: throwOnce,
        playerOnly: playerOnly,
      ),
    );
    flow = Phase0aEncounterFlow.runtime(
      session: session,
      director: director,
      roster: roster,
    );
  }

  late final SpawnDirector director;
  late final Phase0aEncounterRoster roster;
  late final Phase0aEncounterFlow flow;
}

void main() {
  test('逐拍生成、宽限与严格 seq', () {
    final fixture = _Fixture(enemyCount: 1);

    final first = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(),
    );
    expect(first.whereType<Phase0aEnemyEntered>(), hasLength(1));
    expect(first.every((event) => event.tick == 1), isTrue);
    expect(fixture.flow.state.enemies.single.id, 'enemy_1');
    expect(fixture.flow.spawnState.units.single.canAttack, isFalse);
    expect(fixture.flow.lastOrderedEventRecords, hasLength(first.length));

    final second = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(),
    );
    expect(second.whereType<Phase0aSpawnGraceExpired>(), hasLength(1));
    expect(fixture.flow.spawnState.units.single.canAttack, isTrue);
    final seqs = [...first, ...second].map((event) => event.seq).toList();
    for (var i = 1; i < seqs.length; i++) {
      expect(seqs[i], greaterThan(seqs[i - 1]));
    }
    expect(seqs.toSet(), hasLength(seqs.length));
  });

  test('击败后离场，下一拍才补入后备；终局后幂等', () {
    final fixture = _Fixture(enemyCount: 2, damage: 100, playerOnly: true);
    final first = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(attack: true),
    );
    expect(first.whereType<Phase0aEnemyDefeated>(), hasLength(1));
    expect(fixture.flow.outcome, Phase0aBattleOutcome.ongoing);
    expect(fixture.flow.state.enemies, isEmpty);
    final reinforcement = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(),
    );
    expect(reinforcement.whereType<Phase0aEnemyEntered>(), hasLength(1));
    final terminal = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(attack: true),
    );
    final last = terminal.whereType<Phase0aEnemyDefeated>().isNotEmpty
        ? terminal
        : fixture.flow.advance(
            deltaSeconds: 1,
            command: const Phase0aPlayerCommand(attack: true),
          );
    expect(last.whereType<Phase0aEnemyDefeated>(), hasLength(1));
    expect(fixture.flow.outcome, Phase0aBattleOutcome.victory);
    final state = fixture.flow.state;
    final records = fixture.flow.lastOrderedEventRecords;
    expect(
      fixture.flow.advance(
        deltaSeconds: 1,
        command: const Phase0aPlayerCommand(),
      ),
      isEmpty,
    );
    expect(fixture.flow.state, state);
    expect(fixture.flow.lastOrderedEventRecords, isEmpty);
    expect(records, isNotEmpty);
  });

  test('reducer 失败时 session/director/records 原子回滚，可重试', () {
    final fixture = _Fixture(enemyCount: 1, throwOnce: true);
    fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(),
    );
    expect(
      () => fixture.flow.advance(
        deltaSeconds: 1,
        command: const Phase0aPlayerCommand(),
      ),
      throwsStateError,
    );
    expect(fixture.flow.state.tick, 1);
    expect(fixture.flow.spawnState.tick, 1);
    expect(fixture.flow.lastOrderedEventRecords, isNotEmpty);
    expect(
      fixture.flow.advance(
        deltaSeconds: 1,
        command: const Phase0aPlayerCommand(),
      ),
      isNotEmpty,
    );
    expect(fixture.flow.state.tick, 2);
  });
}
