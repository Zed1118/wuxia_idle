import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/posture.dart';

import '../support/combatant_snapshot_fixture.dart';
import '../support/test_data.dart';

enum _Scenario { clear, elite, boss }

typedef _Metrics = ({
  bool victory,
  int attacks,
  int hits,
  int maxHitsPerTick,
  int finalQi,
  ArenaVector finalPlayerPosition,
});

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  tearDownAll(GameRepository.resetForTest);

  test(
    'five production profiles x three schools clear all three risk scenarios',
    () {
      final results =
          <WeaponArchetype, Map<TechniqueSchool, Map<_Scenario, _Metrics>>>{};
      for (final archetype in WeaponArchetype.values) {
        results[archetype] = {};
        for (final school in TechniqueSchool.values) {
          results[archetype]![school] = {
            for (final scenario in _Scenario.values)
              scenario: _simulate(
                repository: repository,
                archetype: archetype,
                school: school,
                scenario: scenario,
              ),
          };
        }
      }

      expect(results, hasLength(WeaponArchetype.values.length));
      expect(
        results.values.expand((schools) => schools.values),
        hasLength(
          WeaponArchetype.values.length * TechniqueSchool.values.length,
        ),
      );
      expect(
        results.values
            .expand((schools) => schools.values)
            .expand((scenarios) => scenarios.values),
        hasLength(
          WeaponArchetype.values.length *
              TechniqueSchool.values.length *
              _Scenario.values.length,
        ),
      );
      for (final schools in results.values) {
        for (final scenarios in schools.values) {
          for (final metrics in scenarios.values) {
            expect(metrics.victory, isTrue);
            expect(metrics.attacks, greaterThan(0));
            expect(metrics.hits, greaterThan(0));
            expect(metrics.hits, lessThanOrEqualTo(metrics.attacks));
            expect(metrics.maxHitsPerTick, 1);
            expect(metrics.finalQi, inInclusiveRange(0, 100));
            expect(metrics.finalPlayerPosition, const ArenaVector(-320, 0));
          }
        }
      }
    },
  );
}

_Metrics _simulate({
  required GameRepository repository,
  required WeaponArchetype archetype,
  required TechniqueSchool school,
  required _Scenario scenario,
}) {
  final playerSnapshot = testCombatantSnapshot(
    characterId: 1,
    name: 'm3_player',
    school: school,
    maxHp: 20000,
    currentHp: 20000,
    internalForce: 600,
    maxQi: 100,
    currentQi: 0,
    criticalRate: 0,
    evasionRate: 0,
    totalEquipmentAttack: 130,
    weaponArchetype: archetype,
    includeProductionBasicAttack: true,
  );
  final mapping = Phase0aStageContentMapper.mapPlayerOnly(
    contentId: 'm3_${archetype.name}_${school.name}_${scenario.name}',
    playerSnapshot: playerSnapshot,
    numbers: repository.numbers,
  );
  final enemySchool = switch (school) {
    TechniqueSchool.gangMeng => TechniqueSchool.yinRou,
    TechniqueSchool.lingQiao => TechniqueSchool.gangMeng,
    TechniqueSchool.yinRou => TechniqueSchool.lingQiao,
  };
  final enemyActors = _enemyActors(scenario);
  final enemySnapshots = [
    for (final actor in enemyActors)
      Phase0aCombatantInput(
        actorId: actor.id,
        snapshot: testCombatantSnapshot(
          characterId: -actor.id.hashCode.abs(),
          name: actor.id,
          school: enemySchool,
          maxHp: actor.maxHealth,
          currentHp: actor.currentHealth,
          internalForce: 300,
          maxQi: 100,
          criticalRate: 0,
          evasionRate: 0,
          defenseRate: 0.05,
          totalEquipmentAttack: 60,
          isBoss: actor.isBoss,
        ),
      ),
  ];
  final bundle = Phase0aBattleSnapshotFactory(numbers: repository.numbers)
      .create(
        combatants: [
          Phase0aCombatantInput(actorId: 'player', snapshot: playerSnapshot),
          ...enemySnapshots,
        ],
        moveBindings: mapping.moveBindings,
      );
  final resolver = Phase0aDamageCalculatorAdapter(
    combatants: bundle.combatants,
    moveBindings: bundle.moveBindings,
    numbers: repository.numbers,
    rng: math.Random(1),
  );
  var state = Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: mapping.initialPlayer,
    enemies: enemyActors,
    skillSlots: mapping.skillSlots,
  );
  final initialPlayerPosition = state.player.position;
  var attacks = 0;
  var hits = 0;
  var maxHitsPerTick = 0;

  for (var step = 0; step < 1000 && state.enemies.isNotEmpty; step++) {
    final target = state.enemies.first;
    final aim = (target.position - state.player.position).normalized();
    final intents = mapping.playerAdapter.intentsFor(
      state: state,
      command: Phase0aPlayerCommand(
        attack: true,
        attackAimDirection: aim,
        attackTargetId: target.id,
      ),
    );
    final result = reducePhase0aTick(
      state: state,
      intents: intents,
      deltaSeconds: 0.1,
      damageResolver: resolver,
    );
    final started = result.events.whereType<Phase0aAttackStarted>().toList();
    final landed = result.events.whereType<Phase0aHitLanded>().toList();
    attacks += started.length;
    hits += landed.length;
    maxHitsPerTick = math.max(maxHitsPerTick, landed.length);
    expect(
      started.every(
        (event) =>
            event.basicAttackSegment == null &&
            event.weaponArchetype == archetype &&
            event.visualSchool == school,
      ),
      isTrue,
    );
    expect(
      landed.every(
        (event) =>
            event.basicAttackSegment == null &&
            event.weaponArchetype == archetype &&
            event.visualSchool == school,
      ),
      isTrue,
    );
    expect(result.state.player.position, initialPlayerPosition);
    state = result.state;
  }

  expect(
    state.player.qiCurrent,
    math.min(state.player.qiMax, attacks * 20),
    reason: 'one accepted single-stage attack may apply qiDelta only once',
  );
  return (
    victory: state.enemies.isEmpty,
    attacks: attacks,
    hits: hits,
    maxHitsPerTick: maxHitsPerTick,
    finalQi: state.player.qiCurrent,
    finalPlayerPosition: state.player.position,
  );
}

List<Phase0aActor> _enemyActors(_Scenario scenario) {
  Phase0aActor enemy({
    required String id,
    required ArenaVector position,
    required int hp,
    required Phase0aDefeatKind defeatKind,
    required bool isBoss,
    double? postureCapacity,
  }) => Phase0aActor(
    id: id,
    side: Phase0aSide.enemy,
    position: position,
    facing: const ArenaVector(-1, 0),
    maxHealth: hp,
    currentHealth: hp,
    moveSpeed: 0,
    qiCurrent: 0,
    qiMax: 100,
    attackCooldownRemaining: 0,
    defeatKind: defeatKind,
    isBoss: isBoss,
    posture: postureCapacity == null
        ? null
        : PostureState.initial(
            PostureConfig(
              capacity: postureCapacity,
              vulnerabilityTicks: 3,
              recoveryPolicy: PostureRecoveryPolicy.reset,
              postVulnerabilityAccumulated: 0,
              bossControlConversionFactor: 3,
            ),
          ),
  );

  return switch (scenario) {
    _Scenario.clear => [
      for (var index = 0; index < 6; index++)
        enemy(
          id: 'clear_$index',
          position: ArenaVector(-80 + index * 18, (index - 3) * 22),
          hp: 1100,
          defeatKind: Phase0aDefeatKind.normal,
          isBoss: false,
        ),
    ],
    _Scenario.elite => [
      enemy(
        id: 'elite',
        position: const ArenaVector(-40, 0),
        hp: 6000,
        defeatKind: Phase0aDefeatKind.elite,
        isBoss: false,
        postureCapacity: 4,
      ),
    ],
    _Scenario.boss => [
      enemy(
        id: 'boss',
        position: const ArenaVector(-20, 0),
        hp: 12000,
        defeatKind: Phase0aDefeatKind.elite,
        isBoss: true,
        postureCapacity: 8,
      ),
    ],
  };
}
