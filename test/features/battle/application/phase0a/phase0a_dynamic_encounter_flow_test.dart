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
  maxHealth: 100,
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

Phase0aCombatSession _session({
  int tick = 0,
  Phase0aActor? player,
  List<Phase0aActor> enemies = const [],
}) => Phase0aCombatSession(
  initialState: Phase0aArenaState(
    tick: tick,
    nextSeq: 0,
    player:
        player ??
        _actor('player', side: Phase0aSide.player, position: ArenaVector.zero),
    enemies: enemies,
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
  damageResolver: _FixedResolver(),
);

SpawnDirector _director({String enemyId = 'enemy_1'}) => SpawnDirector(
  config: SpawnDirectorConfig(
    activeLimit: 1,
    reinforcementThreshold: 0,
    entryWarningTicks: 0,
    attackGraceTicks: 1,
  ),
  entries: [SpawnEntry(entryId: 'entry_1', enemyId: enemyId)],
);

Phase0aEncounterRoster _roster(
  SpawnDirector director, {
  String playerId = 'player',
}) => Phase0aEncounterRoster(
  director: director,
  playerId: playerId,
  bindings: [
    Phase0aEncounterRosterBinding(
      entryId: 'entry_1',
      actor: _actor('enemy_1', side: Phase0aSide.enemy),
    ),
  ],
);

class _Fixture {
  _Fixture({
    int enemyCount = 2,
    int damage = 0,
    bool throwOnce = false,
    bool playerOnly = false,
    int entryWarningTicks = 0,
    int attackGraceTicks = 1,
    int playerHealth = 100,
    Phase0aWinCondition? winCondition,
  }) {
    director = SpawnDirector(
      config: SpawnDirectorConfig(
        activeLimit: 1,
        reinforcementThreshold: 0,
        entryWarningTicks: entryWarningTicks,
        attackGraceTicks: attackGraceTicks,
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
          health: playerHealth,
          position: ArenaVector.zero,
        ),
        enemies: const [],
        skillSlots: const [],
        winCondition: winCondition,
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
  group('runtime 构造严格拒绝漂移合同', () {
    test('director identity 不同即拒绝', () {
      final director = _director();
      final otherDirector = _director();

      expect(
        () => Phase0aEncounterFlow.runtime(
          session: _session(),
          director: otherDirector,
          roster: _roster(director),
        ),
        throwsArgumentError,
      );
    });

    test('playerId 或玩家阵营不匹配即拒绝', () {
      final director = _director();
      expect(
        () => Phase0aEncounterFlow.runtime(
          session: _session(),
          director: director,
          roster: _roster(director, playerId: 'other_player'),
        ),
        throwsArgumentError,
      );
      expect(
        () => Phase0aEncounterFlow.runtime(
          session: _session(player: _actor('player', side: Phase0aSide.enemy)),
          director: director,
          roster: _roster(director),
        ),
        throwsArgumentError,
      );
    });

    test('tick 不同即拒绝', () {
      final director = _director();
      expect(
        () => Phase0aEncounterFlow.runtime(
          session: _session(tick: 1),
          director: director,
          roster: _roster(director),
        ),
        throwsArgumentError,
      );
    });

    test('active 敌人集合不同或重复即拒绝', () {
      final director = _director().advance().director;
      final enemy = _actor('enemy_1', side: Phase0aSide.enemy);

      expect(
        () => Phase0aEncounterFlow.runtime(
          session: _session(),
          director: director,
          roster: _roster(director),
        ),
        throwsArgumentError,
      );
      expect(
        () => Phase0aEncounterFlow.runtime(
          session: _session(tick: 1, enemies: [enemy, enemy]),
          director: director,
          roster: _roster(director),
        ),
        throwsArgumentError,
      );
    });

    test('active 敌人非敌方或已死亡即拒绝', () {
      final director = _director().advance().director;

      expect(
        () => Phase0aEncounterFlow.runtime(
          session: _session(
            tick: 1,
            enemies: [_actor('enemy_1', side: Phase0aSide.player)],
          ),
          director: director,
          roster: _roster(director),
        ),
        throwsArgumentError,
      );
      expect(
        () => Phase0aEncounterFlow.runtime(
          session: _session(
            tick: 1,
            enemies: [_actor('enemy_1', side: Phase0aSide.enemy, health: 0)],
          ),
          director: director,
          roster: _roster(director),
        ),
        throwsArgumentError,
      );
    });
  });

  test('入口预警单位不进 arena，结束后才上场', () {
    final fixture = _Fixture(enemyCount: 2, entryWarningTicks: 1);

    final warning = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(),
    );
    expect(warning.whereType<Phase0aSpawnWarningStarted>(), hasLength(1));
    expect(fixture.flow.spawnState.warningCount, 1);
    expect(fixture.flow.spawnState.pendingCount, 1);
    expect(fixture.flow.state.enemies, isEmpty);

    final entered = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(),
    );
    expect(entered.whereType<Phase0aEnemyEntered>(), hasLength(1));
    expect(fixture.flow.spawnState.activeCount, 1);
    expect(fixture.flow.state.enemies.single.id, 'enemy_1');
  });

  test('敌人攻击宽限期间不造成伤害，到期当拍才可攻击', () {
    final fixture = _Fixture(enemyCount: 1, damage: 10);

    final entered = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(),
    );
    expect(entered.whereType<Phase0aEnemyEntered>(), hasLength(1));
    expect(fixture.flow.state.player.currentHealth, 100);

    final expired = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(),
    );
    expect(expired.whereType<Phase0aSpawnGraceExpired>(), hasLength(1));
    expect(fixture.flow.state.player.currentHealth, 90);
  });

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
    final allEvents = <Phase0aEvent>[];
    final first = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(attack: true),
    );
    allEvents.addAll(first);
    expect(first.whereType<Phase0aEnemyDefeated>(), hasLength(1));
    expect(fixture.flow.outcome, Phase0aBattleOutcome.ongoing);
    expect(fixture.flow.state.enemies, isEmpty);
    final reinforcement = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(),
    );
    allEvents.addAll(reinforcement);
    expect(reinforcement.whereType<Phase0aEnemyEntered>(), hasLength(1));
    final terminal = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(attack: true),
    );
    allEvents.addAll(terminal);
    final last = terminal.whereType<Phase0aEnemyDefeated>().isNotEmpty
        ? terminal
        : fixture.flow.advance(
            deltaSeconds: 1,
            command: const Phase0aPlayerCommand(attack: true),
          );
    if (!identical(last, terminal)) {
      allEvents.addAll(last);
    }
    expect(last.whereType<Phase0aEnemyDefeated>(), hasLength(1));
    expect(fixture.flow.outcome, Phase0aBattleOutcome.victory);
    for (var i = 0; i < allEvents.length; i++) {
      expect(allEvents[i].seq, i, reason: '第 $i 个事件 seq 断档');
    }
    expect(allEvents.last, isA<Phase0aBattleVictory>());
    expect(allEvents.last.seq, fixture.flow.state.nextSeq - 1);
    final state = fixture.flow.state;
    final terminalNextSeq = state.nextSeq;
    final records = fixture.flow.lastOrderedEventRecords;
    expect(
      fixture.flow.advance(
        deltaSeconds: 1,
        command: const Phase0aPlayerCommand(),
      ),
      isEmpty,
    );
    expect(fixture.flow.state, state);
    expect(fixture.flow.state.nextSeq, terminalNextSeq);
    expect(fixture.flow.lastOrderedEventRecords, isEmpty);
    expect(records, isNotEmpty);
  });

  test('surviveTicks 到达时敌人存活仍胜利', () {
    final fixture = _Fixture(
      enemyCount: 1,
      winCondition: const Phase0aWinCondition.surviveTicks(1),
    );

    final events = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(),
    );

    expect(fixture.flow.outcome, Phase0aBattleOutcome.victory);
    expect(fixture.flow.state.enemies, isNotEmpty);
    expect(events.last, isA<Phase0aBattleVictory>());
  });

  test('同拍 surviveTicks 到达且玩家死亡时失败优先', () {
    final fixture = _Fixture(
      enemyCount: 1,
      damage: 100,
      attackGraceTicks: 0,
      winCondition: const Phase0aWinCondition.surviveTicks(1),
    );

    final events = fixture.flow.advance(
      deltaSeconds: 1,
      command: const Phase0aPlayerCommand(),
    );

    expect(fixture.flow.state.player.isAlive, isFalse);
    expect(fixture.flow.outcome, Phase0aBattleOutcome.defeat);
    expect(events.last, isA<Phase0aBattleDefeat>());
    expect(events.whereType<Phase0aBattleVictory>(), isEmpty);
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
