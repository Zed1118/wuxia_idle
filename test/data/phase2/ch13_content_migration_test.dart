import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/combat_objective_primitive_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/battle_shared/enemy_combatant_snapshot_assembler.dart';

import '../../support/combatant_snapshot_fixture.dart';

Future<String> _fileLoader(String path) async =>
    (await File(path).readAsString()).replaceAll('\r\n', '\n');

const _expected = {
  'stage_13_01': (
    'ch13_encounter_01_tea_stall_veteran',
    'ch13_s01_tea_stall_veteran',
    TechniqueSchool.gangMeng,
    'ch2_attack_set_outer',
    'sect_outer',
  ),
  'stage_13_03': (
    'ch13_encounter_03_bamboo_recluse',
    'ch13_s03_bamboo_recluse',
    TechniqueSchool.yinRou,
    'ch2_attack_set_lightfoot',
    'sect_lightfoot',
  ),
  'stage_13_04': (
    'ch13_encounter_04_cliff_gatekeeper',
    'ch13_s04_cliff_gatekeeper',
    TechniqueSchool.gangMeng,
    'ch2_attack_set_outer',
    'sect_outer',
  ),
  'stage_13_05': (
    'ch13_encounter_05_peak_waiting_sage',
    'ch13_s05_peak_waiting_sage',
    TechniqueSchool.lingQiao,
    'ch2_attack_set_lightfoot',
    'sect_lightfoot',
  ),
};

const _templeStageId = 'stage_13_02';
const _templeEncounterId = 'ch13_encounter_02_halfway_temple';
const _templeCommanderEntryId = 'ch13_s02_guard_02';

const _bossCases = {
  'stage_13_04': (
    'ch13_encounter_04_cliff_gatekeeper',
    'ch13_s04_cliff_gatekeeper',
  ),
  'stage_13_05': (
    'ch13_encounter_05_peak_waiting_sage',
    'ch13_s05_peak_waiting_sage',
  ),
};

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

  test('Chapter 13 exposes five of five migrated production routes', () {
    final chapterStageIds = repository.stageDefs.values
        .where((stage) => stage.chapterIndex == 13)
        .map((stage) => stage.id)
        .toSet();
    expect(chapterStageIds, {..._expected.keys, _templeStageId});
    for (final stageId in chapterStageIds) {
      expect(
        repository.combatAssignmentForStage(stageId)?.migrationState,
        CombatEncounterMigrationState.migrated,
        reason: stageId,
      );
      expect(repository.combatEncounterForStage(stageId), isNotNull);
      expect(repository.combatRuntimeBindingForStage(stageId), isNotNull);
    }
    final migratedMainlineCount = repository.combatCatalog!.stageAssignments
        .where(
          (assignment) =>
              assignment.migrationState ==
                  CombatEncounterMigrationState.migrated &&
              repository.stageDefs[assignment.stageId]?.stageType ==
                  StageType.mainline,
        )
        .length;
    expect(migratedMainlineCount, 105);
  });

  test('Chapter 13 singleton routes retain exact StageDef contracts', () {
    for (final MapEntry(key: stageId, value: contract) in _expected.entries) {
      final stage = repository.getStage(stageId);
      final assignment = repository.combatAssignmentForStage(stageId);
      final encounter = repository.combatEncounterForStage(stageId);
      final runtime = repository.combatRuntimeBindingForStage(stageId);
      expect(assignment?.encounterId, contract.$1, reason: stageId);
      expect(encounter?.spawnEntries, hasLength(1), reason: stageId);
      expect(encounter?.spawnConfig.activeLimit, 1, reason: stageId);
      expect(encounter?.spawnEntries.single.entryId, contract.$2);
      expect(encounter?.spawnEntries.single.roleId, contract.$5);
      expect(runtime?.baseEnemyId, stage.enemyTeam.single.id);
      expect(runtime?.enemyBindings, hasLength(1));

      final bundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
        stageId: stageId,
        encounterId: contract.$1,
        cycleIndex: 1,
        repository: repository,
      );
      final target = bundle.actorBindingsByEntryId[contract.$2]!;
      expect(target.combatant.school, contract.$3, reason: stageId);
      expect(target.attackSet, contract.$4, reason: stageId);
    }
  });

  test('halfway temple remains a 25 actor, 10 active layered ecology', () {
    final encounter = repository.combatEncounterForStage(_templeStageId)!;
    expect(encounter.id, _templeEncounterId);
    expect(encounter.spawnEntries, hasLength(25));
    expect(encounter.spawnConfig.activeLimit, 10);
    expect(encounter.tokenBudgets.melee, 2);
    expect(encounter.tokenBudgets.ranged, 1);
    expect(encounter.tokenBudgets.charge, 1);
    expect(encounter.tokenBudgets.support, 1);
    expect(encounter.spawnEntries.last.entryId, _templeCommanderEntryId);
    expect(encounter.spawnEntries.last.roleId, 'temple_guard');

    final targets = encounter.objectives.clauses
        .map((clause) => clause.primitive)
        .whereType<CombatDefeatTargetsRef>()
        .single
        .targetIds;
    final commander = encounter.objectives.clauses
        .map((clause) => clause.primitive)
        .whereType<CombatDefeatCommanderRef>()
        .single;
    expect(
      encounter.objectives.completionRule,
      CombatObjectiveCompletionRule.all,
    );
    expect(targets, hasLength(24));
    expect(targets, isNot(contains(_templeCommanderEntryId)));
    expect(commander.commanderId, _templeCommanderEntryId);
  });

  test('halfway temple commander keeps non-Boss StageDef identity', () {
    final stage = repository.getStage(_templeStageId);
    final base = EnemyCombatantSnapshotAssembler.assembleOne(
      enemy: stage.enemyTeam.single,
      slotIndex: 24,
      cycleIndex: 1,
      isTower: false,
    );
    final bundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
      stageId: _templeStageId,
      encounterId: _templeEncounterId,
      cycleIndex: 1,
      repository: repository,
    );
    final commander = bundle.actorBindingsByEntryId[_templeCommanderEntryId]!;
    expect(base.name, '半山知客僧');
    expect(base.isBoss, isFalse);
    expect(commander.combatant.name, base.name);
    expect(commander.combatant.iconPath, base.iconPath);
    expect(commander.visualAssetPath, base.iconPath);
    expect(commander.combatant.school, base.school);
    expect(commander.combatant.isBoss, isFalse);
    expect(commander.createActor('runtime-commander').isBoss, isFalse);
    expect(
      commander.combatant.availableSkills.map((skill) => skill.id),
      base.availableSkills.map((skill) => skill.id),
    );

    final encounter = repository.combatEncounterForStage(_templeStageId)!;
    for (final entry in encounter.spawnEntries.take(24)) {
      final actor = bundle.actorBindingsByEntryId[entry.entryId]!;
      final role = repository
          .combatArchetypeById(entry.archetypeId)!
          .variantByRole(entry.roleId)!;
      expect(actor.combatant.name, role.displayName, reason: entry.entryId);
      expect(actor.combatant.isBoss, isFalse, reason: entry.entryId);
    }
  });

  test('layered objective requires both 24 examiners and the commander', () {
    final encounter = repository.combatEncounterForStage(_templeStageId)!;
    final targetIds = encounter.objectives.clauses
        .map((clause) => clause.primitive)
        .whereType<CombatDefeatTargetsRef>()
        .single
        .targetIds;
    final controller = mapCombatObjectiveComposition(
      encounter.objectives,
      tickDuration: const Duration(milliseconds: 100),
    );
    var progress = controller.initialProgress;
    for (final targetId in targetIds) {
      progress = controller.advance(progress, TargetDefeated(targetId));
    }
    expect(progress.completed, isFalse);
    progress = controller.advance(
      progress,
      CommanderDefeated(_templeCommanderEntryId),
    );
    expect(progress.completed, isTrue);

    var reverse = controller.advance(
      controller.initialProgress,
      CommanderDefeated(_templeCommanderEntryId),
    );
    expect(reverse.completed, isFalse);
    for (final targetId in targetIds) {
      reverse = controller.advance(reverse, TargetDefeated(targetId));
    }
    expect(reverse.completed, isTrue);
  });

  test('both authored Chapter 13 Bosses retain identity and mechanics', () {
    for (final MapEntry(key: stageId, value: identity) in _bossCases.entries) {
      final stage = repository.getStage(stageId);
      final base = EnemyCombatantSnapshotAssembler.assembleOne(
        enemy: stage.enemyTeam.single,
        slotIndex: 0,
        cycleIndex: 1,
        isTower: false,
      );
      final bundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
        stageId: stageId,
        encounterId: identity.$1,
        cycleIndex: 1,
        repository: repository,
      );
      final target = bundle.actorBindingsByEntryId[identity.$2]!;
      expect(target.combatant.name, base.name, reason: stageId);
      expect(target.combatant.iconPath, base.iconPath, reason: stageId);
      expect(target.combatant.isBoss, isTrue, reason: stageId);
      expect(target.combatant.chargeSkillId, base.chargeSkillId);
      expect(
        target.combatant.availableSkills.map((skill) => skill.id),
        base.availableSkills.map((skill) => skill.id),
      );
      expect(
        target.combatant.bossPhases
            ?.map(
              (phase) => (
                phase.hpThresholdPct,
                phase.unlockSkillIds.join(','),
                phase.aiMode,
                phase.onEnterMechanic,
                phase.titleKey,
              ),
            )
            .toList(),
        base.bossPhases
            ?.map(
              (phase) => (
                phase.hpThresholdPct,
                phase.unlockSkillIds.join(','),
                phase.aiMode,
                phase.onEnterMechanic,
                phase.titleKey,
              ),
            )
            .toList(),
        reason: stageId,
      );
      expect(target.createActor('runtime-target').isBoss, isTrue);
    }

    final finalStage = repository.getStage('stage_13_05');
    expect(finalStage.dropSkillManualId, 'skill_yi_lan_zhong_shan');
    expect(
      finalStage.enemyTeam.single.chargeSkillId,
      finalStage.dropSkillManualId,
    );
  });

  test(
    'all five Chapter 13 routes construct through the real factory',
    () async {
      final source = _runtimeSource(repository);
      for (final stageId in [..._expected.keys, _templeStageId]) {
        final host = await createFreshPhase0aMainlineEncounter(
          Phase0aMainlineEncounterHostBuildRequest(
            stage: repository.getStage(stageId),
            playerMapping: _playerMapping(repository, stageId),
            numbers: repository.numbers,
            cycleIndex: 1,
            rng: Random(stageId.hashCode),
            runtimeBindingSource: source,
            catalogOverride: repository.combatCatalog,
          ),
        );
        expect(host, isNotNull, reason: stageId);
        final enemyCount = stageId == _templeStageId ? 25 : 1;
        expect(host!.mapping!.combatants, hasLength(enemyCount + 1));
        expect(
          host.mapping!.director.config.activeLimit,
          stageId == _templeStageId ? 10 : 1,
        );
        expect(host.tokenBindingsByActorId, hasLength(enemyCount));
      }
    },
  );

  test(
    'all five Chapter 13 routes reach dynamic victory without stalls',
    () async {
      final source = _runtimeSource(repository);
      final maxTicks = repository.numbers.phase0aArena.maxSimulationTicks;
      final deltaSeconds = repository.numbers.phase0aArena.fixedDeltaSeconds;
      final stageIds = [..._expected.keys, _templeStageId];
      for (var index = 0; index < stageIds.length; index++) {
        final stageId = stageIds[index];
        final host = (await createFreshPhase0aMainlineEncounter(
          Phase0aMainlineEncounterHostBuildRequest(
            stage: repository.getStage(stageId),
            playerMapping: _playerMapping(repository, stageId),
            numbers: repository.numbers,
            cycleIndex: 1,
            rng: Random(2026091300 + index),
            runtimeBindingSource: source,
            catalogOverride: repository.combatCatalog,
          ),
        ))!;
        final bot = Phase0aPlayerBotAdapter(
          playerAdapter: host.mapping!.playerAdapter,
          policy: const Phase0aBotTacticPolicy.assault(),
          objectiveContinuationCommandBuilder:
              host.objectiveContinuationCommandBuilder,
        );
        final result = host.runHeadless(
          bot: bot,
          deltaSeconds: deltaSeconds,
          maxTicks: maxTicks,
        );
        expect(result.outcome, Phase0aBattleOutcome.victory, reason: stageId);
        expect(result.timedOut, isFalse, reason: stageId);
        expect(result.ticks, inInclusiveRange(1, maxTicks - 1));
        expect(
          result.events.whereType<Phase0aEnemyDefeated>(),
          hasLength(stageId == _templeStageId ? 25 : 1),
          reason: stageId,
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Phase0aMainlineEncounterRuntimeBindingSource _runtimeSource(
  GameRepository repository,
) => Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
  loader: ({required stageId, required encounterId, required cycleIndex}) =>
      buildPhase0aMainlineRuntimeBindingBundleFromRepository(
        stageId: stageId,
        encounterId: encounterId,
        cycleIndex: cycleIndex,
        repository: repository,
      ),
);

Phase0aPlayerRuntimeMapping _playerMapping(
  GameRepository repository,
  String stageId,
) {
  final enemy = repository.getStage(stageId).enemyTeam.single;
  final numericSkills = [
    repository.getSkill('skill_gangmeng_shichuan_ult'),
    repository.getSkill('skill_lingqiao_shichuan_ult'),
    repository.getSkill('skill_yinrou_shichuan_ult'),
    repository.getSkill('skill_feng_juan_liu_sha'),
    repository.getSkill('skill_ping_sha_luo_yan'),
    repository.getSkill('skill_ye_yu_shi_nian_deng'),
  ];
  return Phase0aStageContentMapper.mapPlayerOnly(
    contentId: stageId,
    playerSnapshot: testCombatantSnapshot(
      realmTier: enemy.realmTier,
      realmLayer: stageId == _templeStageId
          ? RealmLayer.dengFeng
          : enemy.realmLayer,
      // Test-only terminal-path durability for the 25-enemy encounter. This
      // proves the live director/objective/reducer closure, not game balance.
      maxHp: stageId == _templeStageId ? 200000 : 20000,
      currentHp: stageId == _templeStageId ? 200000 : 20000,
      internalForce: 15000,
      maxQi: 15000,
      currentQi: 15000,
      totalEquipmentAttack: 2000,
      defenseRate: repository.numbers.cycleEvolution.defenseRateCap,
      includeProductionBasicAttack: true,
      skillLoadout: CombatantSkillLoadout(
        main1: numericSkills[0],
        main2: numericSkills[1],
        assist: numericSkills[2],
        resonance: numericSkills[3],
        ultimate: numericSkills[4],
        encounter: numericSkills[5],
      ),
      availableSkills: numericSkills,
    ),
    numbers: repository.numbers,
  );
}
