import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/combat_objective_primitive_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_enemy_behavior_profile.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

import '../../support/combatant_snapshot_fixture.dart';

class _EcologySpec {
  const _EcologySpec({
    required this.stageId,
    required this.encounterId,
    required this.archetypeId,
    required this.idPrefix,
    required this.roleCounts,
    required this.roleNames,
    required this.tokensByRole,
    required this.movementByRole,
    required this.attackByRole,
    required this.supportRoleId,
  });

  final String stageId;
  final String encounterId;
  final String archetypeId;
  final String idPrefix;
  final Map<String, int> roleCounts;
  final Map<String, String> roleNames;
  final Map<String, AttackTokenKind> tokensByRole;
  final Map<String, Phase0aEnemyMovementPolicy> movementByRole;
  final Map<String, Phase0aEnemyAttackPolicy> attackByRole;
  final String supportRoleId;
}

const _specs = <_EcologySpec>[
  _EcologySpec(
    stageId: 'stage_02_01',
    encounterId: 'ch2_encounter_01_poison_escort',
    archetypeId: 'ch2_poison',
    idPrefix: 'ch2p',
    roleCounts: {
      'poison_blood_blade': 12,
      'poison_dart': 6,
      'poison_shadow_assassin': 5,
      'poison_master': 2,
    },
    roleNames: {
      'poison_blood_blade': '血刀众',
      'poison_dart': '毒镖手',
      'poison_shadow_assassin': '影袭刺客',
      'poison_master': '毒师',
    },
    tokensByRole: {
      'poison_blood_blade': AttackTokenKind.melee,
      'poison_dart': AttackTokenKind.ranged,
      'poison_shadow_assassin': AttackTokenKind.charge,
      'poison_master': AttackTokenKind.support,
    },
    movementByRole: {
      'poison_blood_blade': Phase0aEnemyMovementPolicy.directAdvance,
      'poison_dart': Phase0aEnemyMovementPolicy.holdDistance,
      'poison_shadow_assassin': Phase0aEnemyMovementPolicy.lateralFlank,
      'poison_master': Phase0aEnemyMovementPolicy.guardedPosition,
    },
    attackByRole: {
      'poison_blood_blade': Phase0aEnemyAttackPolicy.closeRange,
      'poison_dart': Phase0aEnemyAttackPolicy.rangedPressure,
      'poison_shadow_assassin': Phase0aEnemyAttackPolicy.chargeAndReposition,
      'poison_master': Phase0aEnemyAttackPolicy.supportPulse,
    },
    supportRoleId: 'poison_master',
  ),
  _EcologySpec(
    stageId: 'stage_04_01',
    encounterId: 'ch4_encounter_01_xiliang_crossing',
    archetypeId: 'ch4_xiliang',
    idPrefix: 'ch4',
    roleCounts: {
      'xiliang_sand_blade': 12,
      'xiliang_horse_archer': 6,
      'xiliang_heavy_cavalry': 5,
      'xiliang_banner': 2,
    },
    roleNames: {
      'xiliang_sand_blade': '沙刀骑卒',
      'xiliang_horse_archer': '骑射手',
      'xiliang_heavy_cavalry': '重骑',
      'xiliang_banner': '旗主',
    },
    tokensByRole: {
      'xiliang_sand_blade': AttackTokenKind.melee,
      'xiliang_horse_archer': AttackTokenKind.ranged,
      'xiliang_heavy_cavalry': AttackTokenKind.charge,
      'xiliang_banner': AttackTokenKind.support,
    },
    movementByRole: {
      'xiliang_sand_blade': Phase0aEnemyMovementPolicy.directAdvance,
      'xiliang_horse_archer': Phase0aEnemyMovementPolicy.holdDistance,
      'xiliang_heavy_cavalry': Phase0aEnemyMovementPolicy.lateralFlank,
      'xiliang_banner': Phase0aEnemyMovementPolicy.guardedPosition,
    },
    attackByRole: {
      'xiliang_sand_blade': Phase0aEnemyAttackPolicy.closeRange,
      'xiliang_horse_archer': Phase0aEnemyAttackPolicy.rangedPressure,
      'xiliang_heavy_cavalry': Phase0aEnemyAttackPolicy.chargeAndReposition,
      'xiliang_banner': Phase0aEnemyAttackPolicy.supportPulse,
    },
    supportRoleId: 'xiliang_banner',
  ),
  _EcologySpec(
    stageId: 'stage_13_02',
    encounterId: 'ch13_encounter_02_halfway_temple',
    archetypeId: 'ch13_temple',
    idPrefix: 'ch13',
    roleCounts: {
      'temple_staff': 12,
      'temple_thrower': 6,
      'temple_arhat_charger': 5,
      'temple_guard': 2,
    },
    roleNames: {
      'temple_staff': '棍僧',
      'temple_thrower': '投掷僧',
      'temple_arhat_charger': '罗汉冲阵',
      'temple_guard': '护院客僧',
    },
    tokensByRole: {
      'temple_staff': AttackTokenKind.melee,
      'temple_thrower': AttackTokenKind.ranged,
      'temple_arhat_charger': AttackTokenKind.charge,
      'temple_guard': AttackTokenKind.support,
    },
    movementByRole: {
      'temple_staff': Phase0aEnemyMovementPolicy.guardedPosition,
      'temple_thrower': Phase0aEnemyMovementPolicy.holdDistance,
      'temple_arhat_charger': Phase0aEnemyMovementPolicy.lateralFlank,
      'temple_guard': Phase0aEnemyMovementPolicy.guardedPosition,
    },
    attackByRole: {
      'temple_staff': Phase0aEnemyAttackPolicy.closeRange,
      'temple_thrower': Phase0aEnemyAttackPolicy.rangedPressure,
      'temple_arhat_charger': Phase0aEnemyAttackPolicy.chargeAndReposition,
      'temple_guard': Phase0aEnemyAttackPolicy.supportPulse,
    },
    supportRoleId: 'temple_guard',
  ),
];

Future<String> _fileLoader(String path) async =>
    (await File(path).readAsString()).replaceAll('\r\n', '\n');

Phase0aMainlineEncounterRuntimeBindingSourceAdapter _runtimeSource(
  GameRepository repository,
) => Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
  loader:
      ({required stageId, required encounterId, required cycleIndex}) async =>
          buildPhase0aMainlineRuntimeBindingBundleFromRepository(
            stageId: stageId,
            encounterId: encounterId,
            cycleIndex: cycleIndex,
            repository: repository,
          ),
);

Future<void> _verifyEcology(
  GameRepository repository,
  _EcologySpec spec,
) async {
  final manifest = repository.combatCatalog!;
  final assignment = manifest.assignmentForStage(spec.stageId);
  final encounter = manifest.encounterForStage(spec.stageId);
  final archetype = manifest.archetypeById(spec.archetypeId);

  expect(assignment?.migrationState, CombatEncounterMigrationState.migrated);
  expect(assignment?.encounterId, spec.encounterId);
  expect(encounter, isNotNull);
  expect(archetype, isNotNull);
  final encounterDef = encounter!;
  final archetypeDef = archetype!;
  expect(encounterDef.id, spec.encounterId);
  expect(encounterDef.spawnEntries, hasLength(25));
  expect(encounterDef.spawnConfig.activeLimit, 10);
  expect(encounterDef.tokenBudgets.melee, 2);
  expect(encounterDef.tokenBudgets.ranged, 1);
  expect(encounterDef.tokenBudgets.charge, 1);
  expect(encounterDef.tokenBudgets.support, 1);

  final actualRoleCounts = <String, int>{};
  for (final entry in encounterDef.spawnEntries) {
    actualRoleCounts.update(
      entry.roleId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    expect(entry.archetypeId, spec.archetypeId);
  }
  expect(actualRoleCounts, spec.roleCounts);
  expect({
    for (final variant in archetypeDef.variants)
      variant.roleId: variant.displayName,
  }, spec.roleNames);
  for (final variant in archetypeDef.variants) {
    expect(variant.visualVariantIds, hasLength(2), reason: variant.roleId);
    expect(variant.attackTagIds, isNotEmpty, reason: variant.roleId);
    expect(variant.attackSetId, startsWith('${spec.idPrefix}_attack_set_'));
    expect(variant.postureProfileId, startsWith('${spec.idPrefix}_posture_'));
    expect(
      variant.dropGroupId,
      '${spec.idPrefix}_drop_group_ecology_encounter',
    );
    expect(variant.sfxGroupId, startsWith('${spec.idPrefix}_sfx_'));
  }

  final bundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
    stageId: spec.stageId,
    encounterId: spec.encounterId,
    cycleIndex: 1,
    repository: repository,
  );
  expect(bundle.actorBindingsByEntryId, hasLength(25));
  expect(bundle.actorBindingsByEntryId.keys.toSet(), {
    for (final entry in encounterDef.spawnEntries) entry.entryId,
  });

  final namesByRole = <String, Set<String>>{};
  final visualsByRole = <String, Set<String>>{};
  final tokensByRole = <String, Set<AttackTokenKind>>{};
  for (final entry in encounterDef.spawnEntries) {
    final binding = bundle.actorBindingsByEntryId[entry.entryId]!;
    namesByRole
        .putIfAbsent(entry.roleId, () => <String>{})
        .add(binding.combatant.name);
    visualsByRole
        .putIfAbsent(entry.roleId, () => <String>{})
        .add(binding.visualAssetPath);
    tokensByRole
        .putIfAbsent(entry.roleId, () => <AttackTokenKind>{})
        .add(binding.token.kind);
    expect(File(binding.visualAssetPath).existsSync(), isTrue);
    expect(binding.behaviorProfile, isNotNull);
    expect(
      binding.behaviorProfile!.movementPolicy,
      spec.movementByRole[entry.roleId],
      reason: entry.roleId,
    );
    expect(
      binding.behaviorProfile!.attackPolicy,
      spec.attackByRole[entry.roleId],
      reason: entry.roleId,
    );
    expect(binding.token.kind, spec.tokensByRole[entry.roleId]);
    expect(binding.combatant.skillLoadout.basicAttack, isNotNull);
    expect(
      binding.enemySkillBindings,
      entry.roleId == spec.supportRoleId ? isNotEmpty : isEmpty,
      reason: entry.roleId,
    );
  }
  expect(
    namesByRole,
    spec.roleNames.map((role, name) => MapEntry(role, {name})),
  );
  for (final role in spec.roleCounts.keys) {
    expect(visualsByRole[role], hasLength(2), reason: role);
    expect(tokensByRole[role], {spec.tokensByRole[role]!}, reason: role);
  }

  final playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
    contentId: spec.stageId,
    playerSnapshot: testCombatantSnapshot(
      maxHp: 15000,
      currentHp: 15000,
      maxQi: 100,
      currentQi: 100,
      includeProductionBasicAttack: true,
    ),
    numbers: repository.numbers,
  );
  final host = await createFreshPhase0aMainlineEncounter(
    Phase0aMainlineEncounterHostBuildRequest(
      stage: repository.getStage(spec.stageId),
      playerMapping: playerMapping,
      numbers: repository.numbers,
      cycleIndex: 1,
      rng: Random(20260831),
      runtimeBindingSource: _runtimeSource(repository),
      catalogOverride: repository.combatCatalog,
    ),
  );
  expect(host, isNotNull);
  expect(host!.mapping!.combatants, hasLength(26));
  expect(host.mapping!.director.config.activeLimit, 10);
  expect(host.mapping!.enemyAiAdapter.behaviorProfilesByActor, hasLength(25));
  expect(host.tokenBindingsByActorId, hasLength(25));

  final positions = [
    for (final entry in encounterDef.spawnEntries)
      bundle.actorBindingsByEntryId[entry.entryId]!
          .createActor(entry.entryId)
          .position,
  ];
  for (var start = 0; start <= positions.length - 10; start++) {
    expect(
      positions.sublist(start, start + 10).toSet(),
      hasLength(10),
      reason: '${spec.stageId} active position window start=$start',
    );
  }

  if (encounterDef.objectives.clauses.single.primitive
      case CombatDefendEntityRef(:final requiredTicks)) {
    final defended = host.mapping!.initialState.defendedEntity;
    expect(defended, isNotNull);
    expect(defended!.isAlive, isTrue);
    final defendSource = buildPhase0aMainlineObjectiveEventSource(
      encounter: encounterDef,
      roster: host.mapping!.roster,
    );
    final defendController = mapCombatObjectiveComposition(
      encounterDef.objectives,
      tickDuration: const Duration(milliseconds: 100),
    );
    var defendProgress = defendController.initialProgress;
    final initialArena = host.mapping!.initialState;
    for (var index = 0; index < requiredTicks; index++) {
      final events = defendSource.eventsFor(
        Phase0aEncounterObjectiveFrame(
          beforeArena: initialArena,
          afterArena: Phase0aArenaState(
            tick: index + 1,
            nextSeq: initialArena.nextSeq,
            player: initialArena.player,
            enemies: initialArena.enemies,
            skillSlots: initialArena.skillSlots,
            defendedEntity: initialArena.defendedEntity,
            winCondition: initialArena.winCondition,
          ),
          beforeSpawn: host.mapping!.director.state,
          afterSpawn: host.mapping!.director.state,
          directorEvents: const [],
          spawnEvents: const [],
          combatEvents: const [],
          deltaSeconds: 0.1,
          playerMovementDelta: playerMapping.initialPlayer.position * 0,
        ),
      );
      expect(events, hasLength(1));
      expect(events.single, isA<EntityDefended>());
      defendProgress = defendController.advance(defendProgress, events.single);
      expect(
        defendProgress.completed,
        index == requiredTicks - 1,
        reason: '${spec.stageId} defend tick ${index + 1}',
      );
    }
    expect(defendProgress.clauses.single.completed, isTrue);
    return;
  }

  final objectiveEvents =
      buildPhase0aMainlineObjectiveEventSource(
        encounter: encounterDef,
        roster: host.mapping!.roster,
      ).eventsFor(
        Phase0aEncounterObjectiveFrame(
          beforeArena: host.mapping!.initialState,
          afterArena: host.mapping!.initialState,
          beforeSpawn: host.mapping!.director.state,
          afterSpawn: host.mapping!.director.state,
          directorEvents: const [],
          spawnEvents: const [],
          combatEvents: [
            for (
              var index = 0;
              index < encounterDef.spawnEntries.length;
              index++
            )
              Phase0aEnemyDefeated(
                seq: index + 1,
                tick: 1,
                target: host.mapping!.roster
                    .bindingByEntryId(encounterDef.spawnEntries[index].entryId)!
                    .actorId,
                defeatKind: bundle
                    .actorBindingsByEntryId[encounterDef
                        .spawnEntries[index]
                        .entryId]!
                    .createActor('probe')
                    .defeatKind,
              ),
          ],
          deltaSeconds: 0.1,
          playerMovementDelta: playerMapping.initialPlayer.position * 0,
        ),
      );
  expect(objectiveEvents, hasLength(25));

  final controller = mapCombatObjectiveComposition(
    encounterDef.objectives,
    tickDuration: const Duration(milliseconds: 100),
  );
  var progress = controller.initialProgress;
  for (final event in objectiveEvents) {
    progress = controller.advance(progress, event);
  }
  expect(progress.completed, isTrue);
  expect(progress.clauses.single.completed, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameRepository repository;

  setUpAll(() async {
    repository = await GameRepository.loadAllDefs(
      loader: _fileLoader,
      assetExists: (path) async => File(path).existsSync(),
    );
  });
  tearDownAll(GameRepository.resetForTest);

  for (final spec in _specs) {
    test('${spec.stageId} closes its four-role production ecology', () async {
      await _verifyEcology(repository, spec);
    });
  }
}
