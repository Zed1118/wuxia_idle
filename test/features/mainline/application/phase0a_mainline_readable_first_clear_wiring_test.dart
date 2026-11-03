import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_host.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  late Phase0aPlayerRuntimeMapping playerMapping;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
      contentId: 'stage_01_05',
      playerSnapshot: testCombatantSnapshot(
        maxHp: 20000,
        currentHp: 20000,
        internalForce: 15000,
        maxQi: 15000,
        currentQi: 15000,
        defenseRate: repository.numbers.cycleEvolution.defenseRateCap,
        totalEquipmentAttack: 2000,
        includeProductionBasicAttack: true,
      ),
      numbers: repository.numbers,
    );
  });

  Future<Phase0aEncounterHost> fresh({required bool readableFirstClear}) async {
    final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
      loader:
          ({
            required String stageId,
            required String encounterId,
            required int cycleIndex,
          }) async => buildPhase0aMainlineRuntimeBindingBundleFromRepository(
            stageId: stageId,
            encounterId: encounterId,
            cycleIndex: cycleIndex,
            repository: repository,
          ),
      readableFirstClearLoader:
          ({
            required String stageId,
            required String encounterId,
            required int cycleIndex,
          }) async => buildPhase0aMainlineRuntimeBindingBundleFromRepository(
            stageId: stageId,
            encounterId: encounterId,
            cycleIndex: cycleIndex,
            repository: repository,
            readableFirstClearTuning: true,
          ),
    );
    return (await createFreshPhase0aMainlineEncounter(
      Phase0aMainlineEncounterHostBuildRequest(
        stage: repository.getStage('stage_01_05'),
        playerMapping: playerMapping,
        numbers: repository.numbers,
        cycleIndex: 1,
        rng: Random(20260824),
        runtimeBindingSource: source,
        catalogOverride: repository.combatCatalog,
        readableFirstClearTuning: readableFirstClear,
      ),
    ))!;
  }

  test(
    'production first-clear path applies HP and auto-skill tuning',
    () async {
      final tuned = (await fresh(readableFirstClear: true)).mapping!;
      final neutral = (await fresh(readableFirstClear: false)).mapping!;
      final config = repository.numbers.combat.readableFirstClear;
      final playerId = neutral.initialState.player.id;
      final tunedById = {
        for (final combatant in tuned.combatants)
          if (combatant.actorId != playerId) combatant.actorId: combatant,
      };

      var checkedAutoSkills = 0;
      for (final enemy in neutral.combatants.where(
        (combatant) => combatant.actorId != playerId,
      )) {
        final tunedEnemy = tunedById[enemy.actorId]!;
        expect(
          tunedEnemy.snapshot.maxHp,
          (enemy.snapshot.maxHp *
                  config.hpMultiplierFor(isBoss: enemy.snapshot.isBoss))
              .round(),
          reason: enemy.actorId,
        );
        expect(
          tunedEnemy.snapshot.attackPowerMultiplier,
          closeTo(config.enemyAttackMultiplier, 1e-9),
          reason: enemy.actorId,
        );

        final neutralSkills = {
          for (final skill in enemy.snapshot.availableSkills) skill.id: skill,
        };
        for (final skill in tunedEnemy.snapshot.availableSkills) {
          final base = neutralSkills[skill.id]!;
          if (skill.requiresManualTrigger ||
              skill.type == SkillType.normalAttack) {
            expect(
              skill.powerMultiplier,
              base.powerMultiplier,
              reason: skill.id,
            );
            continue;
          }
          checkedAutoSkills++;
          expect(
            skill.powerMultiplier,
            (base.powerMultiplier * config.autoSkillPowerMultiplier)
                .round()
                .clamp(1, base.powerMultiplier),
            reason: skill.id,
          );
          expect(
            tunedEnemy.snapshot.openingSkillCooldowns[skill.id],
            config.openingAutoSkillCooldownTurns,
            reason: skill.id,
          );
          expect(
            enemy.snapshot.openingSkillCooldowns[skill.id],
            isNull,
            reason: skill.id,
          );
        }
      }
      expect(checkedAutoSkills, greaterThan(0));
    },
  );

  test('tuned binding load fails closed without a tuned loader', () async {
    final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
      loader:
          ({
            required String stageId,
            required String encounterId,
            required int cycleIndex,
          }) async => throw StateError('plain loader must not be selected'),
    );

    expect(
      () => source.load(
        stageId: 'stage_01_05',
        encounterId: 'ch1_encounter_05_commander',
        cycleIndex: 1,
        readableFirstClearTuning: true,
      ),
      throwsStateError,
    );
  });
}
