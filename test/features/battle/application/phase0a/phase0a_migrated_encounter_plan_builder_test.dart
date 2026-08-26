import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/combat_stage_encounter_route_selector.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_migrated_encounter_plan_builder.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  CombatEncounterSpawnEntry contentEntry(String entryId) =>
      CombatEncounterSpawnEntry(
        entryId: entryId,
        archetypeId: 'archetype_$entryId',
        roleId: 'role_$entryId',
        entranceId: 'entrance_$entryId',
        positionId: 'position_$entryId',
        behaviorId: 'behavior_$entryId',
      );

  CombatEncounterDef encounter() => CombatEncounterDef(
    id: 'encounter_r11',
    spawnConfig: CombatEncounterSpawnConfig(
      activeLimit: 2,
      reinforcementThreshold: 0,
      entryWarningTicks: 1,
      attackGraceTicks: 1,
    ),
    tokenBudgets: CombatEncounterTokenBudgets(
      melee: 1,
      ranged: 1,
      charge: 1,
      support: 1,
    ),
    spawnEntries: [contentEntry('entry_b'), contentEntry('entry_a')],
    objectives: CombatObjectiveCompositionRef(
      completionRule: CombatObjectiveCompletionRule.all,
      clauses: [
        CombatObjectiveClauseRef(
          id: 'clear',
          primitive: CombatDefeatTargetsRef(const ['target']),
        ),
      ],
    ),
  );

  Phase0aActor actor({
    required String id,
    required Phase0aSide side,
    ArenaVector position = ArenaVector.zero,
  }) => Phase0aActor(
    id: id,
    side: side,
    position: position,
    facing: side == Phase0aSide.player
        ? const ArenaVector(1, 0)
        : const ArenaVector(-1, 0),
    maxHealth: 100,
    currentHealth: 100,
    moveSpeed: 1,
    qiCurrent: 0,
    qiMax: 100,
    attackCooldownRemaining: 0,
    defeatKind: Phase0aDefeatKind.normal,
  );

  Phase0aArenaState initialState({
    int tick = 0,
    List<Phase0aActor> enemies = const [],
  }) => Phase0aArenaState(
    tick: tick,
    nextSeq: 1,
    player: actor(id: 'player', side: Phase0aSide.player),
    enemies: enemies,
    skillSlots: const [],
  );

  List<Phase0aCombatantInput> combatants() => [
    Phase0aCombatantInput(
      actorId: 'player',
      snapshot: testCombatantSnapshot(characterId: 1),
    ),
    Phase0aCombatantInput(
      actorId: 'enemy_entry_b',
      snapshot: testCombatantSnapshot(characterId: 2),
    ),
    Phase0aCombatantInput(
      actorId: 'enemy_entry_a',
      snapshot: testCombatantSnapshot(characterId: 3),
    ),
  ];

  Map<Phase0aDamageKind, SkillDef?> moveBindings() => {
    Phase0aDamageKind.basic: null,
    Phase0aDamageKind.gather: null,
    Phase0aDamageKind.clear: null,
  };

  Phase0aPlayerInputAdapter playerAdapter({String playerId = 'player'}) =>
      Phase0aPlayerInputAdapter(
        playerId: playerId,
        attackRange: 1,
        attackHalfArcRadians: 1,
        attackCooldownSeconds: 1,
        attackQiDelta: 0,
        postureBasicPowerMultiplier: 1,
        attackPowerMultiplier: 1,
        gatherPowerMultiplier: 1,
        clearPowerMultiplier: 1,
        gatherSlot: 'gather',
        gatherRingRadius: 1,
        gatherEffectRadius: 1,
        gatherQiCost: 0,
        gatherCooldownSeconds: 1,
        clearSlot: 'clear',
        clearEffectRadius: 1,
        clearQiCost: 0,
        clearCooldownSeconds: 1,
      );

  Phase0aEnemyAiAdapter enemyAiAdapter() => const Phase0aEnemyAiAdapter(
    attackRange: 1,
    attackHalfArcRadians: 1,
    attackCooldownSeconds: 1,
    postureBasicPowerMultiplier: 1,
    uniformBasicPowerMultiplier: 1,
  );

  Phase0aMigratedEncounterPlan buildPlan({
    MigratedCombatStageEncounterRoute? route,
    Duration tickDuration = const Duration(milliseconds: 25),
    String Function(CombatEncounterSpawnEntry entry)? resolveEnemyId,
    Phase0aActor Function(CombatEncounterSpawnEntry entry, String enemyId)?
    createActor,
    String playerId = 'player',
    Phase0aArenaState? arena,
    List<Phase0aCombatantInput>? combatantInputs,
    Map<Phase0aDamageKind, SkillDef?>? bindings,
    Phase0aPlayerInputAdapter? playerInput,
  }) {
    final resolvedRoute =
        route ?? MigratedCombatStageEncounterRoute('stage_r11', encounter());
    return buildPhase0aMigratedEncounterPlan(
      resolvedRoute,
      tickDuration: tickDuration,
      resolveEnemyId: resolveEnemyId ?? (entry) => 'enemy_${entry.entryId}',
      playerId: playerId,
      createActor:
          createActor ??
          (entry, enemyId) => actor(
            id: enemyId,
            side: Phase0aSide.enemy,
            position: const ArenaVector(10, 0),
          ),
      initialState: arena ?? initialState(),
      combatants: combatantInputs ?? combatants(),
      moveBindings: bindings ?? moveBindings(),
      playerAdapter: playerInput ?? playerAdapter(),
      enemyAiAdapter: enemyAiAdapter(),
    );
  }

  test('preserves exact route identity and composes in content order once', () {
    final sourceEncounter = encounter();
    final route = MigratedCombatStageEncounterRoute(
      'stage_exact',
      sourceEncounter,
    );
    final resolverCalls = <String>[];
    final factoryCalls = <String>[];

    final plan = buildPlan(
      route: route,
      resolveEnemyId: (entry) {
        resolverCalls.add(entry.entryId);
        return 'runtime_${entry.entryId}';
      },
      createActor: (entry, enemyId) {
        factoryCalls.add('${entry.entryId}:$enemyId');
        return actor(id: enemyId, side: Phase0aSide.enemy);
      },
      combatantInputs: [
        Phase0aCombatantInput(
          actorId: 'player',
          snapshot: testCombatantSnapshot(characterId: 1),
        ),
        Phase0aCombatantInput(
          actorId: 'runtime_entry_b',
          snapshot: testCombatantSnapshot(characterId: 2),
        ),
        Phase0aCombatantInput(
          actorId: 'runtime_entry_a',
          snapshot: testCombatantSnapshot(characterId: 3),
        ),
      ],
    );

    expect(plan.route, same(route));
    expect(plan.stageId, 'stage_exact');
    expect(plan.encounter, same(sourceEncounter));
    expect(resolverCalls, ['entry_b', 'entry_a']);
    expect(factoryCalls, [
      'entry_b:runtime_entry_b',
      'entry_a:runtime_entry_a',
    ]);
    expect(plan.runtimeContracts.spawnDirector, same(plan.mapping.director));
    expect(plan.roster, same(plan.mapping.roster));
    expect(plan.roster.director, same(plan.runtimeContracts.spawnDirector));
  });

  test('resolver failure short-circuits actor factory and propagates', () {
    final failure = StateError('resolver failed');
    var factoryCalls = 0;

    expect(
      () => buildPlan(
        resolveEnemyId: (entry) => throw failure,
        createActor: (entry, enemyId) {
          factoryCalls++;
          return actor(id: enemyId, side: Phase0aSide.enemy);
        },
      ),
      throwsA(same(failure)),
    );
    expect(factoryCalls, 0);
  });

  test('actor factory failure propagates unchanged in content order', () {
    final failure = StateError('factory failed');
    final calls = <String>[];

    expect(
      () => buildPlan(
        createActor: (entry, enemyId) {
          calls.add(entry.entryId);
          if (entry.entryId == 'entry_a') throw failure;
          return actor(id: enemyId, side: Phase0aSide.enemy);
        },
      ),
      throwsA(same(failure)),
    );
    expect(calls, ['entry_b', 'entry_a']);
  });

  test('repeated builds create fresh builder-owned runtime objects', () {
    final route = MigratedCombatStageEncounterRoute('stage_r11', encounter());
    final first = buildPlan(route: route);
    final second = buildPlan(route: route);

    expect(first, isNot(same(second)));
    expect(first.runtimeContracts, isNot(same(second.runtimeContracts)));
    expect(
      first.runtimeContracts.spawnDirector,
      isNot(same(second.runtimeContracts.spawnDirector)),
    );
    expect(
      first.runtimeContracts.objectiveController,
      isNot(same(second.runtimeContracts.objectiveController)),
    );
    expect(first.roster, isNot(same(second.roster)));
    expect(first.mapping, isNot(same(second.mapping)));
    expect(first.route, same(route));
  });

  test('caller collection mutation does not leak into plan mapping', () {
    final callerCombatants = combatants();
    final callerBindings = moveBindings();
    final plan = buildPlan(
      combatantInputs: callerCombatants,
      bindings: callerBindings,
    );

    callerCombatants.clear();
    callerBindings.clear();

    expect(plan.mapping.combatants, hasLength(3));
    expect(plan.mapping.moveBindings, hasLength(3));
    expect(() => plan.mapping.combatants.clear(), throwsUnsupportedError);
    expect(() => plan.mapping.moveBindings.clear(), throwsUnsupportedError);
  });

  test(
    'plan mapping delegates coverage adapter move tick and active checks',
    () {
      final missingCombatants = combatants()
        ..removeWhere((input) => input.actorId == 'enemy_entry_a');
      final missingMove = moveBindings()..remove(Phase0aDamageKind.clear);
      final activeEnemy = actor(id: 'enemy_entry_a', side: Phase0aSide.enemy);
      final plans = <Phase0aMigratedEncounterPlan>[
        buildPlan(combatantInputs: missingCombatants),
        buildPlan(playerInput: playerAdapter(playerId: 'other')),
        buildPlan(bindings: missingMove),
        buildPlan(arena: initialState(tick: 1)),
        buildPlan(arena: initialState(enemies: [activeEnemy])),
      ];

      for (final plan in plans) {
        final rng = math.Random(71);
        expect(
          () => Phase0aProductionFlowAssembler.assembleEncounterFromMapping(
            mapping: plan.mapping,
            numbers: GameRepository.instance.numbers,
            rng: rng,
          ),
          throwsArgumentError,
        );
        expect(
          rng.nextDouble(),
          math.Random(71).nextDouble(),
          reason: 'delegated structural checks must not consume caller RNG',
        );
      }
    },
  );

  test('builder source exposes only the typed migrated composition seam', () {
    final source = File(
      'lib/features/battle/application/phase0a/'
      'phase0a_migrated_encounter_plan_builder.dart',
    ).readAsStringSync();
    final imports = RegExp(
      r"^import '([^']+)';$",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)).toList();

    expect(
      source,
      contains(
        'buildPhase0aMigratedEncounterPlan(\n'
        '  MigratedCombatStageEncounterRoute route,',
      ),
    );
    for (final forbidden in [
      'LegacyCombatStageEncounterRoute',
      'hasLegacyContent',
      'Random',
      'NumbersConfig',
      'dart:io',
      'GameRepository',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
    for (final forbidden in [
      RegExp(r'\bswitch\b'),
      RegExp(r'\bcatch\b'),
      RegExp(r'\bfallback\b', caseSensitive: false),
      RegExp(r'\brepository\b', caseSensitive: false),
      RegExp(r'\bhost\b', caseSensitive: false),
      RegExp(r'\bcandidate\b', caseSensitive: false),
      RegExp(r'\bdefault\b', caseSensitive: false),
      RegExp(r'\btuning\b', caseSensitive: false),
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden.pattern);
    }
    expect(imports, [
      '../../../../data/defs/combat_encounter_def.dart',
      '../../../../data/defs/skill_def.dart',
      '../../../../data/validation/combat_encounter_roster_mapper.dart',
      '../../../../data/validation/combat_encounter_runtime_contract_mapper.dart',
      '../../../../data/validation/combat_stage_encounter_route_selector.dart',
      '../../domain/phase0a/encounter_enemy_roster.dart',
      '../../domain/phase0a/phase0a_combat_model.dart',
      '../../domain/phase0a/phase0a_damage_kind.dart',
      'phase0a_battle_snapshot_factory.dart',
      'phase0a_encounter_mapping.dart',
      'phase0a_enemy_ai_adapter.dart',
      'phase0a_player_input_adapter.dart',
    ]);
  });
}
