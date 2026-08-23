import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_event_order_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_spawn_event_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';

Phase0aActor enemyActor(String id, ArenaVector position) => Phase0aActor(
  id: id,
  side: Phase0aSide.enemy,
  position: position,
  facing: const ArenaVector(-1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

/// warning=1/grace=1,两个入口第 1 拍预警、第 2 拍入场、第 3 拍宽限到期。
SpawnDirector twoEntryDirector() => SpawnDirector(
  config: SpawnDirectorConfig(
    activeLimit: 2,
    reinforcementThreshold: 0,
    entryWarningTicks: 1,
    attackGraceTicks: 1,
  ),
  entries: [
    SpawnEntry(entryId: 'e1', enemyId: 'enemy_e1'),
    SpawnEntry(entryId: 'e2', enemyId: 'enemy_e2'),
  ],
);

Phase0aEncounterRoster twoEntryRoster(SpawnDirector director) =>
    Phase0aEncounterRoster(
      director: director,
      playerId: 'player',
      bindings: [
        Phase0aEncounterRosterBinding(
          entryId: 'e1',
          actor: enemyActor('enemy_e1', const ArenaVector(10, 20)),
        ),
        Phase0aEncounterRosterBinding(
          entryId: 'e2',
          actor: enemyActor('enemy_e2', const ArenaVector(30, 40)),
        ),
      ],
    );

void main() {
  group('单拍事件投影', () {
    test('warningStarted 投影携带全局 seq、combat tick 与名单入场点', () {
      final director = twoEntryDirector();
      final roster = twoEntryRoster(director);
      final advance = director.advance();

      final events = Phase0aSpawnEventAdapter.project(
        directorEvents: advance.events,
        roster: roster,
        seqStart: 5,
        combatTick: advance.director.state.tick,
      );

      expect(events, hasLength(2));
      final first = events.first as Phase0aSpawnWarningStarted;
      expect(first.seq, 5);
      expect(first.tick, 1);
      expect(first.entryId, 'e1');
      expect(first.enemyId, 'enemy_e1');
      expect(first.entryPosition, const ArenaVector(10, 20));
      final second = events[1] as Phase0aSpawnWarningStarted;
      expect(second.seq, 6);
      expect(second.entryId, 'e2');
      expect(second.entryPosition, const ArenaVector(30, 40));
      expect(() => events.add(first), throwsUnsupportedError);
    });

    test('entered 与 graceExpired 投影类型与 payload 正确', () {
      final director = twoEntryDirector();
      final roster = twoEntryRoster(director);

      var current = director.advance();
      current = current.director.advance();
      expect(current.events, hasLength(2));
      final entered = Phase0aSpawnEventAdapter.project(
        directorEvents: current.events,
        roster: roster,
        seqStart: 0,
        combatTick: current.director.state.tick,
      );
      expect(entered.map((event) => event.runtimeType).toList(), [
        Phase0aEnemyEntered,
        Phase0aEnemyEntered,
      ]);
      expect(
        (entered.first as Phase0aEnemyEntered).entryPosition,
        const ArenaVector(10, 20),
      );
      expect(entered.map((event) => event.tick).toList(), [2, 2]);

      current = current.director.advance();
      final expired = Phase0aSpawnEventAdapter.project(
        directorEvents: current.events,
        roster: roster,
        seqStart: 9,
        combatTick: current.director.state.tick,
      );
      expect(expired.map((event) => event.runtimeType).toList(), [
        Phase0aSpawnGraceExpired,
        Phase0aSpawnGraceExpired,
      ]);
      expect(expired.map((event) => event.seq).toList(), [9, 10]);
      expect(expired.map((event) => event.tick).toList(), [3, 3]);
    });

    test('按输入原顺序分配连续 seq,不排序不去重', () {
      final director = twoEntryDirector();
      final roster = twoEntryRoster(director);
      const shuffled = [
        SpawnDirectorEvent(
          SpawnDirectorEventType.graceExpired,
          'e2',
          'enemy_e2',
          4,
        ),
        SpawnDirectorEvent(
          SpawnDirectorEventType.warningStarted,
          'e1',
          'enemy_e1',
          4,
        ),
      ];

      final events = Phase0aSpawnEventAdapter.project(
        directorEvents: shuffled,
        roster: roster,
        seqStart: 2,
        combatTick: 4,
      );

      expect(events, hasLength(2));
      expect(events.first, isA<Phase0aSpawnGraceExpired>());
      expect((events.first as Phase0aSpawnGraceExpired).entryId, 'e2');
      expect((events.first as Phase0aSpawnGraceExpired).seq, 2);
      expect(events.last, isA<Phase0aSpawnWarningStarted>());
      expect((events.last as Phase0aSpawnWarningStarted).entryId, 'e1');
      expect((events.last as Phase0aSpawnWarningStarted).seq, 3);
    });

    test('投影不修改 director/roster,空事件列表返回空结果', () {
      final director = twoEntryDirector();
      final roster = twoEntryRoster(director);
      final before = director.state;

      final events = Phase0aSpawnEventAdapter.project(
        directorEvents: const [],
        roster: roster,
        seqStart: 0,
        combatTick: 1,
      );

      expect(events, isEmpty);
      final after = director.state;
      expect(after.tick, before.tick);
      expect(after.totalCount, before.totalCount);
      expect(after.units, before.units);
      expect(roster.size, 2);
      expect(roster.bindingByEntryId('e1'), isNotNull);
    });
  });

  group('fail closed 边界', () {
    test('负 seqStart 或负 combatTick 拒绝', () {
      final director = twoEntryDirector();
      final roster = twoEntryRoster(director);

      expect(
        () => Phase0aSpawnEventAdapter.project(
          directorEvents: const [],
          roster: roster,
          seqStart: -1,
          combatTick: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => Phase0aSpawnEventAdapter.project(
          directorEvents: const [],
          roster: roster,
          seqStart: 0,
          combatTick: -1,
        ),
        throwsArgumentError,
      );
    });

    test('非本拍(与 combatTick 不符)的 director tick 拒绝', () {
      final director = twoEntryDirector();
      final roster = twoEntryRoster(director);
      final advance = director.advance();

      expect(
        () => Phase0aSpawnEventAdapter.project(
          directorEvents: advance.events,
          roster: roster,
          seqStart: 0,
          combatTick: advance.director.state.tick + 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => Phase0aSpawnEventAdapter.project(
          directorEvents: const [
            SpawnDirectorEvent(
              SpawnDirectorEventType.entered,
              'e1',
              'enemy_e1',
              2,
            ),
            SpawnDirectorEvent(
              SpawnDirectorEventType.entered,
              'e2',
              'enemy_e2',
              3,
            ),
          ],
          roster: roster,
          seqStart: 0,
          combatTick: 2,
        ),
        throwsArgumentError,
      );
    });

    test('未知 entry 映射拒绝', () {
      final director = twoEntryDirector();
      final roster = twoEntryRoster(director);

      expect(
        () => Phase0aSpawnEventAdapter.project(
          directorEvents: const [
            SpawnDirectorEvent(
              SpawnDirectorEventType.warningStarted,
              'ghost',
              'enemy_ghost',
              1,
            ),
          ],
          roster: roster,
          seqStart: 0,
          combatTick: 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('接入 Phase0aEventOrderAdapter', () {
    test('warning → entered → graceExpired 的 tick/seq 严格有序且记录稳定', () {
      final director = twoEntryDirector();
      final roster = twoEntryRoster(director);

      final all = <Phase0aEvent>[];
      var current = director;
      var seq = 1;
      for (var tick = 1; tick <= 3; tick++) {
        final advance = current.advance();
        all.addAll(
          Phase0aSpawnEventAdapter.project(
            directorEvents: advance.events,
            roster: roster,
            seqStart: seq,
            combatTick: advance.director.state.tick,
          ),
        );
        seq += advance.events.length;
        current = advance.director;
      }
      expect(all, hasLength(6));

      final firstRecords = Phase0aEventOrderAdapter.project(all);
      final secondRecords = Phase0aEventOrderAdapter.project(List.of(all));
      expect(firstRecords, secondRecords);

      expect(firstRecords.map((record) => record.tick).toList(), [
        1,
        1,
        2,
        2,
        3,
        3,
      ]);
      expect(firstRecords.map((record) => record.tieBreak).toList(), [
        1,
        2,
        3,
        4,
        5,
        6,
      ]);
      expect(firstRecords.first.eventId, contains('spawn_warning_started'));
      expect(firstRecords[2].eventId, contains('enemy_entered'));
      expect(firstRecords[4].eventId, contains('spawn_grace_expired'));
      expect(
        firstRecords.every((record) => record.feedKind == CombatFeedKind.none),
        isTrue,
      );
    });

    test('三类事件映射到稳定领域阶段', () {
      final records = Phase0aEventOrderAdapter.project([
        const Phase0aSpawnWarningStarted(
          seq: 1,
          tick: 4,
          entryId: 'e1',
          enemyId: 'enemy_e1',
          entryPosition: ArenaVector(1, 2),
        ),
        const Phase0aEnemyEntered(
          seq: 2,
          tick: 4,
          entryId: 'e1',
          enemyId: 'enemy_e1',
          entryPosition: ArenaVector(1, 2),
        ),
        const Phase0aSpawnGraceExpired(
          seq: 3,
          tick: 4,
          entryId: 'e1',
          enemyId: 'enemy_e1',
          entryPosition: ArenaVector(1, 2),
        ),
      ]);
      expect(records.map((record) => record.stage), [
        CombatEventStage.startup,
        CombatEventStage.displacementAndSelection,
        CombatEventStage.status,
      ]);
    });

    test('入场点坐标与 entry/enemy 完整进入 canonical payload', () {
      Phase0aEnemyEntered entered(ArenaVector position) => Phase0aEnemyEntered(
        seq: 2,
        tick: 3,
        entryId: 'e1',
        enemyId: 'enemy_e1',
        entryPosition: position,
      );

      final positioned = Phase0aEventOrderAdapter.project([
        entered(const ArenaVector(1, 2)),
      ]).single.eventId;
      final elsewhere = Phase0aEventOrderAdapter.project([
        entered(const ArenaVector(2, 1)),
      ]).single.eventId;
      expect(positioned, isNot(elsewhere));

      final sameAgain = Phase0aEventOrderAdapter.project([
        entered(const ArenaVector(1, 2)),
      ]).single.eventId;
      expect(positioned, sameAgain);
      expect(positioned, contains('enemy_entered'));
    });

    test('spawn 事件与战斗事件共用严格递增 seq 投影', () {
      final records = Phase0aEventOrderAdapter.project([
        const Phase0aSpawnWarningStarted(
          seq: 1,
          tick: 2,
          entryId: 'e1',
          enemyId: 'enemy_e1',
          entryPosition: ArenaVector(0, 0),
        ),
        const Phase0aAttackStarted(
          seq: 2,
          tick: 2,
          actor: 'player',
          moveKind: Phase0aMoveKind.light,
        ),
      ]);

      expect(records.map((record) => record.tieBreak), [1, 2]);
      expect(
        () => Phase0aEventOrderAdapter.project([
          const Phase0aSpawnWarningStarted(
            seq: 3,
            tick: 2,
            entryId: 'e1',
            enemyId: 'enemy_e1',
            entryPosition: ArenaVector(0, 0),
          ),
          const Phase0aSpawnWarningStarted(
            seq: 3,
            tick: 2,
            entryId: 'e2',
            enemyId: 'enemy_e2',
            entryPosition: ArenaVector(0, 0),
          ),
        ]),
        throwsArgumentError,
      );
    });
  });
}
