import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';

Phase0aActor enemyActor(
  String id, {
  ArenaVector position = const ArenaVector(1, 2),
  int currentHealth = 100,
  Phase0aSide side = Phase0aSide.enemy,
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: const ArenaVector(1, 0),
  maxHealth: 100,
  currentHealth: currentHealth,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

SpawnDirector directorWith(List<String> entryIds) => SpawnDirector(
  config: SpawnDirectorConfig(
    activeLimit: entryIds.isEmpty ? 1 : entryIds.length,
    reinforcementThreshold: 0,
    entryWarningTicks: 1,
    attackGraceTicks: 1,
  ),
  entries: [
    for (final id in entryIds) SpawnEntry(entryId: id, enemyId: 'enemy_$id'),
  ],
);

List<Phase0aEncounterRosterBinding> bindingsFor(SpawnDirector director) => [
  for (final unit in director.state.units)
    Phase0aEncounterRosterBinding(
      entryId: unit.entryId,
      actor: enemyActor(unit.enemyId),
    ),
];

void main() {
  group('Phase0aEncounterRoster happy path', () {
    test('每个 director entry 精确绑定一个敌方存活 actor', () {
      final director = directorWith(['e1', 'e2', 'e3']);
      final roster = Phase0aEncounterRoster(
        director: director,
        playerId: 'player',
        bindings: bindingsFor(director),
      );

      expect(roster.size, 3);
      expect(roster.director, same(director));
      for (final unit in director.state.units) {
        final binding = roster.bindingByEntryId(unit.entryId);
        expect(binding, isNotNull);
        expect(binding!.actorId, unit.enemyId);
        expect(binding.actor.side, Phase0aSide.enemy);
        expect(binding.actor.isAlive, isTrue);
      }
    });

    test('按 entryId/enemyId 查询命中并暴露入场点坐标', () {
      final director = directorWith(['e1']);
      final actor = enemyActor('enemy_e1', position: const ArenaVector(7, -3));
      final roster = Phase0aEncounterRoster(
        director: director,
        playerId: 'player',
        bindings: [Phase0aEncounterRosterBinding(entryId: 'e1', actor: actor)],
      );

      expect(roster.bindingByEntryId('e1')?.actor, actor);
      expect(roster.bindingByEnemyId('enemy_e1')?.entryId, 'e1');
      expect(roster.entryPositionOf('e1'), const ArenaVector(7, -3));
      expect(roster.bindingByEntryId('ghost'), isNull);
      expect(roster.bindingByEnemyId('ghost'), isNull);
      expect(roster.entryPositionOf('ghost'), isNull);
    });
  });

  group('输入顺序无关与不可变', () {
    test('binding 输入顺序无关,输出按 entryId 稳定排序且相等', () {
      final director = directorWith(['b', 'a', 'c']);
      final shuffled = bindingsFor(director).reversed.toList();
      final ascending = bindingsFor(director);

      final fromShuffled = Phase0aEncounterRoster(
        director: director,
        playerId: 'player',
        bindings: shuffled,
      );
      final fromAscending = Phase0aEncounterRoster(
        director: director,
        playerId: 'player',
        bindings: ascending,
      );

      expect(fromShuffled, fromAscending);
      expect(fromShuffled.bindings.map((binding) => binding.entryId).toList(), [
        'a',
        'b',
        'c',
      ]);
    });

    test('构造后不暴露可变结构且输入列表被防御性复制', () {
      final director = directorWith(['e1', 'e2']);
      final source = bindingsFor(director);
      final roster = Phase0aEncounterRoster(
        director: director,
        playerId: 'player',
        bindings: source,
      );

      expect(() => roster.bindings.removeAt(0), throwsUnsupportedError);
      expect(() => roster.bindings.add(source.first), throwsUnsupportedError);

      source.removeAt(0);
      expect(roster.size, 2);
      expect(roster.bindingByEntryId('e1'), isNotNull);
    });
  });

  group('fail closed 边界', () {
    test('缺失或多余 binding 拒绝', () {
      final director = directorWith(['e1', 'e2']);
      final all = bindingsFor(director);

      expect(
        () => Phase0aEncounterRoster(
          director: director,
          playerId: 'player',
          bindings: [all.first],
        ),
        throwsArgumentError,
      );
      expect(
        () => Phase0aEncounterRoster(
          director: director,
          playerId: 'player',
          bindings: [
            ...all,
            Phase0aEncounterRosterBinding(
              entryId: 'e3',
              actor: enemyActor('enemy_e3'),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('重复 entryId 或未知 entryId 拒绝', () {
      final director = directorWith(['e1', 'e2']);
      final all = bindingsFor(director);

      expect(
        () => Phase0aEncounterRoster(
          director: director,
          playerId: 'player',
          bindings: [all.first, all.first],
        ),
        throwsArgumentError,
      );
      expect(
        () => Phase0aEncounterRoster(
          director: director,
          playerId: 'player',
          bindings: [
            all.first,
            Phase0aEncounterRosterBinding(
              entryId: 'ghost',
              actor: enemyActor('enemy_e2'),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('actor id 与 entry enemyId 不一致拒绝', () {
      final director = directorWith(['e1']);

      expect(
        () => Phase0aEncounterRoster(
          director: director,
          playerId: 'player',
          bindings: [
            Phase0aEncounterRosterBinding(
              entryId: 'e1',
              actor: enemyActor('someone_else'),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('非敌方、初始死亡或与玩家同 ID 的 actor 拒绝', () {
      final director = directorWith(['e1', 'e2', 'e3']);
      final units = director.state.units;

      expect(
        () => Phase0aEncounterRoster(
          director: director,
          playerId: 'player',
          bindings: [
            Phase0aEncounterRosterBinding(
              entryId: units[0].entryId,
              actor: enemyActor(units[0].enemyId, side: Phase0aSide.player),
            ),
            for (final unit in units.skip(1))
              Phase0aEncounterRosterBinding(
                entryId: unit.entryId,
                actor: enemyActor(unit.enemyId),
              ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => Phase0aEncounterRoster(
          director: director,
          playerId: 'player',
          bindings: [
            Phase0aEncounterRosterBinding(
              entryId: units[0].entryId,
              actor: enemyActor(units[0].enemyId, currentHealth: 0),
            ),
            for (final unit in units.skip(1))
              Phase0aEncounterRosterBinding(
                entryId: unit.entryId,
                actor: enemyActor(unit.enemyId),
              ),
          ],
        ),
        throwsArgumentError,
      );

      final playerClash = directorWith(['e1']);
      expect(
        () => Phase0aEncounterRoster(
          director: playerClash,
          playerId: 'enemy_e1',
          bindings: [
            Phase0aEncounterRosterBinding(
              entryId: 'e1',
              actor: enemyActor('enemy_e1'),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('空白 playerId 拒绝', () {
      final director = directorWith(['e1']);
      expect(
        () => Phase0aEncounterRoster(
          director: director,
          playerId: '  ',
          bindings: bindingsFor(director),
        ),
        throwsArgumentError,
      );

      for (final invalid in [' player', 'player ', 'player id']) {
        expect(
          () => Phase0aEncounterRoster(
            director: director,
            playerId: invalid,
            bindings: bindingsFor(director),
          ),
          throwsArgumentError,
        );
      }
    });
  });
}
