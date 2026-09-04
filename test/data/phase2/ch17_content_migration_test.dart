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
  'stage_17_01': (
    'ch17_encounter_01_sand_treader',
    'ch17_s01_sand_treader',
    TechniqueSchool.lingQiao,
    'ch2_attack_set_lightfoot',
    'sect_lightfoot',
  ),
  'stage_17_02': (
    'ch17_encounter_02_blackwind_blade',
    'ch17_s02_blackwind_blade',
    TechniqueSchool.gangMeng,
    'ch2_attack_set_outer',
    'sect_outer',
  ),
  'stage_17_03': (
    'ch17_encounter_03_old_city_guard',
    'ch17_s03_old_city_guard',
    TechniqueSchool.yinRou,
    'ch2_attack_set_lightfoot',
    'sect_lightfoot',
  ),
  'stage_17_04': (
    'ch17_encounter_04_sandstorm_hand',
    'ch17_s04_sandstorm_hand',
    TechniqueSchool.lingQiao,
    'ch2_attack_set_lightfoot',
    'sect_lightfoot',
  ),
  'stage_17_05': (
    'ch17_encounter_05_desert_guide',
    'ch17_s05_desert_guide',
    TechniqueSchool.lingQiao,
    'ch2_attack_set_lightfoot',
    'sect_lightfoot',
  ),
};

const _bossCases = {
  'stage_17_04': (
    'ch17_encounter_04_sandstorm_hand',
    'ch17_s04_sandstorm_hand',
  ),
  'stage_17_05': ('ch17_encounter_05_desert_guide', 'ch17_s05_desert_guide'),
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

  test('Chapter 17 exposes five of five migrated production routes', () {
    final chapterStageIds = repository.stageDefs.values
        .where((stage) => stage.chapterIndex == 17)
        .map((stage) => stage.id)
        .toSet();
    expect(chapterStageIds, _expected.keys.toSet());
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
    expect(migratedMainlineCount, 81);
  });

  test(
    'Chapter 17 routes retain authored singleton identities and reviewed roles',
    () {
      for (final MapEntry(key: stageId, value: contract) in _expected.entries) {
        final stage = repository.getStage(stageId);
        final assignment = repository.combatAssignmentForStage(stageId);
        final encounter = repository.combatEncounterForStage(stageId);
        final runtime = repository.combatRuntimeBindingForStage(stageId);
        expect(assignment?.encounterId, contract.$1, reason: stageId);
        expect(encounter?.spawnEntries, hasLength(1), reason: stageId);
        expect(encounter?.spawnConfig.activeLimit, 1, reason: stageId);
        expect(
          encounter?.spawnEntries.single.entryId,
          contract.$2,
          reason: '$stageId must match the authored singleton opponent',
        );
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
    },
  );

  test('Chapter 17 routes construct through the real factory', () async {
    final source = _runtimeSource(repository);
    for (final stageId in _expected.keys) {
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
      expect(host!.mapping!.combatants, hasLength(2), reason: stageId);
      expect(host.mapping!.director.config.activeLimit, 1, reason: stageId);
      expect(host.tokenBindingsByActorId, hasLength(1), reason: stageId);
    }
  });

  test('Chapter 17 objectives require the authored singleton opponent', () {
    for (final stageId in ['stage_17_01', 'stage_17_02', 'stage_17_03']) {
      final encounter = repository.combatEncounterForStage(stageId)!;
      final controller = mapCombatObjectiveComposition(
        encounter.objectives,
        tickDuration: const Duration(milliseconds: 100),
      );
      final progress = controller.advance(
        controller.initialProgress,
        TargetDefeated(_expected[stageId]!.$2),
      );
      expect(progress.completed, isTrue, reason: stageId);
    }

    for (final MapEntry(key: stageId, value: identity) in _bossCases.entries) {
      final encounter = repository.combatEncounterForStage(stageId)!;
      final controller = mapCombatObjectiveComposition(
        encounter.objectives,
        tickDuration: const Duration(milliseconds: 100),
      );
      final progress = controller.advance(
        controller.initialProgress,
        CommanderDefeated(identity.$2),
      );
      expect(progress.completed, isTrue, reason: stageId);
    }
  });

  test('both authored Chapter 17 targets retain exact Boss mechanics', () {
    for (final MapEntry(key: stageId, value: identity) in _bossCases.entries) {
      final base = EnemyCombatantSnapshotAssembler.assembleOne(
        enemy: repository.getStage(stageId).enemyTeam.single,
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
      expect(target.combatant.vulnerabilityMult, base.vulnerabilityMult);
      expect(
        target.combatant.availableSkills.map((skill) => skill.id),
        base.availableSkills.map((skill) => skill.id),
        reason: stageId,
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
    expect(
      repository.getStage('stage_17_04').enemyTeam.single.vulnerability,
      isNull,
    );
    expect(
      repository
          .getStage('stage_17_05')
          .enemyTeam
          .single
          .vulnerability!
          .outOfWindowDamageMult,
      0.20,
    );
  });

  test(
    'all five Chapter 17 routes reach dynamic victory without stalls',
    () async {
      final source = _runtimeSource(repository);
      final maxTicks = repository.numbers.phase0aArena.maxSimulationTicks;
      final deltaSeconds = repository.numbers.phase0aArena.fixedDeltaSeconds;
      for (var index = 0; index < _expected.length; index++) {
        final stageId = _expected.keys.elementAt(index);
        final host = (await createFreshPhase0aMainlineEncounter(
          Phase0aMainlineEncounterHostBuildRequest(
            stage: repository.getStage(stageId),
            playerMapping: _playerMapping(repository, stageId),
            numbers: repository.numbers,
            cycleIndex: 1,
            rng: Random(2026091700 + index),
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
          hasLength(1),
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
      realmLayer: enemy.realmLayer,
      maxHp: 20000,
      currentHp: 20000,
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
