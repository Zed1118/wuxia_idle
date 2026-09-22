import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_controller.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/phase0a_gauntlet_stage_runner.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';

import '../../support/isar_test_support.dart';
import '../../support/phase0a_ch1_founder_profile.dart';

void main() {
  test(
    'boundary fixtures replace cooldowns and preserve the session on every outcome',
    () {
      for (final (won, boss) in [(true, false), (true, true), (false, false)]) {
        final original = ActivityMemberSnapshot()
          ..characterId = 7
          ..reservedEquipmentIds = [11, 13]
          ..reservedTechniqueIds = [17]
          ..skillCooldownKeys = ['old-skill']
          ..skillCooldownTurns = [3];
        final run = BossGauntletRun()
          ..seed = 73
          ..currentStage = 2
          ..members = [original]
          ..escrowItemDefIds = ['item_liaoshangdan']
          ..escrowLoadedQty = [2]
          ..escrowUsedQty = [1];
        void advance(Map<String, double> cooldowns) =>
            GauntletController.advancePhase0a(
              run: run,
              checkpoint: GauntletMemberCheckpoint(
                characterId: 7,
                currentHp: won ? 421 : 0,
                currentQi: 23,
                maxHp: 700,
                maxQi: 89,
                skillCooldownSeconds: cooldowns,
              ),
              leftWin: won,
              isBossStage: boss,
            );
        advance({'phase0a_skill_2': 0.125, 'gather': 2.8, 'clear': 0});
        expect(run.members.single.phase0aCooldownSnapshot(), {
          'gather': 2.8,
          'phase0a_skill_2': 0.125,
        });
        expect(run.members.single.isDowned, !won);
        expect(run.currentStage, won && !boss ? 3 : 2);
        expect(
          run.sessionPhase,
          !won
              ? GauntletPhase.inBattle
              : boss
              ? GauntletPhase.awaitingRewardChoice
              : GauntletPhase.interlude,
        );
        expect(run.members.single.reservedEquipmentIds, [11, 13]);
        expect(run.members.single.reservedTechniqueIds, [17]);
        expect(run.members.single.skillCooldownTurns, [3]);
        expect(run.seed, 73);
        expect(run.escrowLoadedQty, [2]);
        expect(run.escrowUsedQty, [1]);
        // 后续检查点没有正冷却时必须清除之前的秒数，
        // 不得重新启用保留的历史回合值。
        advance({'gather': 0});
        expect(run.members.single.phase0aCooldownsRecorded, isTrue);
        expect(run.members.single.phase0aCooldownSnapshot(), isEmpty);
        expect(original.phase0aCooldownsRecorded, isFalse);
      }
    },
  );

  for (final invalid in [-0.1, double.nan, double.infinity]) {
    test('invalid terminal cooldown $invalid leaves the run unchanged', () {
      final original = ActivityMemberSnapshot()..characterId = 7;
      final run = BossGauntletRun()..members = [original];
      expect(
        () => GauntletController.advancePhase0a(
          run: run,
          checkpoint: GauntletMemberCheckpoint(
            characterId: 7,
            currentHp: 1,
            currentQi: 1,
            maxHp: 1,
            maxQi: 1,
            skillCooldownSeconds: {'gather': invalid},
          ),
          leftWin: true,
          isBossStage: false,
        ),
        throwsStateError,
      );
      expect(identical(run.members.single, original), isTrue);
      expect(run.currentStage, 1);
      expect(run.sessionPhase, GauntletPhase.inBattle);
    });
  }

  test(
    'explicit victory boundary survives interlude, cold open and next-stage mapping',
    () async {
      await initializeTestIsarCore();
      final repo = await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
      final dir = await Directory.systemTemp.createTemp(
        'gauntlet_cd_victory_boundary_',
      );
      try {
        await IsarSetup.init(directory: dir, inspector: false);
        final profile = await seedPhase0aCh1FounderProfile(
          isar: IsarSetup.instance,
          schoolId: 'yin_rou',
          originId: 'mountain_wanderer',
          fateId: 'balanced_seed',
          rngSeed: 20260820,
        );
        final player = profile.snapshot;
        final run = BossGauntletRun()
          ..saveDataId = 0
          ..seed = 73
          ..members = [
            ActivityMemberSnapshot()
              ..characterId = player.characterId
              ..skillCooldownKeys = ['old-skill']
              ..skillCooldownTurns = [3],
          ];
        await IsarSetup.instance.writeTxn(
          () => IsarSetup.instance.bossGauntletRuns.put(run),
        );
        final config = repo.bossGauntletConfig!;
        // 明确的事务边界夹具，不代表真实观测到的战斗胜利。
        await GauntletService(IsarSetup.instance).settlePhase0aStageResult(
          config: config,
          result: GauntletStageSettlement(
            leftWin: true,
            checkpoint: GauntletMemberCheckpoint(
              characterId: player.characterId,
              currentHp: player.maxHp - 1,
              currentQi: player.maxQi - 1,
              maxHp: player.maxHp,
              maxQi: player.maxQi,
              skillCooldownSeconds: const {
                'gather': 2.8,
                'phase0a_skill_1': 1.1,
              },
            ),
            combatSettlement: CombatSettlementSnapshot(
              result: BattleResult.leftWin,
              totalTicks: 1,
              hadActions: false,
              playerCharacterId: player.characterId,
              participants: [
                CombatParticipantSnapshot(
                  characterId: player.characterId,
                  currentHp: player.maxHp - 1,
                  maxHp: player.maxHp,
                ),
              ],
              skillCasts: const [],
              totalDamage: 0,
              criticalCount: 0,
              damageByCharacterId: const {},
            ),
          ),
        );
        final interlude = (await IsarSetup.instance.bossGauntletRuns.get(
          run.id,
        ))!;
        expect(
          (interlude.currentStage, interlude.sessionPhase),
          (2, GauntletPhase.interlude),
        );
        await IsarSetup.close();
        IsarSetup.resetForTest();
        await IsarSetup.init(directory: dir, inspector: false);
        final resumed = GauntletService(IsarSetup.instance);
        await resumed.continueToNextStage();
        final plan = await resumed.preparePhase0aStage(config: config);
        expect(plan.stage, 2);
        expect(plan.playerSnapshot.openingSkillCooldowns, isEmpty);
        final mapping = Phase0aStageContentMapper.mapExpedition(
          contentId: 'gauntlet_2',
          enemyTeam: plan.enemyDefs,
          playerSnapshot: plan.playerSnapshot,
          numbers: repo.numbers,
          cycleIndex: plan.cycleIndex,
        );
        expect(
          {
            for (final slot in mapping.initialState.skillSlots)
              if (slot.cooldownRemaining > 0) slot.slot: slot.cooldownRemaining,
          },
          {'gather': 2.8, 'phase0a_skill_1': 1.1},
        );
        expect(plan.playerSnapshot.currentHp, player.maxHp - 1);
        expect(plan.playerSnapshot.currentQi, player.maxQi - 1);
        expect((await resumed.activeRun())!.members.single.skillCooldownTurns, [
          3,
        ]);
      } finally {
        if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
        IsarSetup.resetForTest();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'actual terminal cooldowns survive checkpoint storage and cold mapping',
    () async {
      await initializeTestIsarCore();
      final repo = await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
      final dir = await Directory.systemTemp.createTemp(
        'gauntlet_cd_checkpoint_',
      );
      try {
        await IsarSetup.init(directory: dir, inspector: false);
        final profile = await seedPhase0aCh1FounderProfile(
          isar: IsarSetup.instance,
          schoolId: 'yin_rou',
          originId: 'mountain_wanderer',
          fateId: 'balanced_seed',
          rngSeed: 20260820,
        );
        // 独立的战中检查点夹具；不伪造门票、通关、胜利或奖励，
        // 也不增强玩家或削弱敌人。
        await IsarSetup.instance.writeTxn(() async {
          await IsarSetup.instance.bossGauntletRuns.put(
            BossGauntletRun()
              ..saveDataId = 0
              ..seed = 0
              ..members = [
                ActivityMemberSnapshot()
                  ..characterId = profile.snapshot.characterId,
              ],
          );
        });
        final config = repo.bossGauntletConfig!;
        final service = GauntletService(IsarSetup.instance);
        final plan = await service.preparePhase0aStage(config: config);
        final result = await Phase0aGauntletStageRunner.run(
          contentId: 'gauntlet_${plan.stage}',
          playerSnapshot: plan.playerSnapshot,
          enemyTeam: plan.enemyDefs,
          numbers: repo.numbers,
          seed: plan.seed,
          cycleIndex: plan.cycleIndex,
        );
        final expected = {
          for (final slot in result.finalState.skillSlots)
            if (slot.cooldownRemaining > 0) slot.slot: slot.cooldownRemaining,
        };
        expect(
          expected,
          isNotEmpty,
          reason: 'The production battle must actually cast a skill',
        );
        await service.settlePhase0aStageResult(
          result: result.settlement,
          config: config,
        );
        await IsarSetup.close();
        IsarSetup.resetForTest();
        await IsarSetup.init(directory: dir, inspector: false);
        final restored = await GauntletService(
          IsarSetup.instance,
        ).preparePhase0aStage(config: config);
        final mapping = Phase0aStageContentMapper.mapExpedition(
          contentId: 'gauntlet_${restored.stage}',
          enemyTeam: restored.enemyDefs,
          playerSnapshot: restored.playerSnapshot,
          numbers: repo.numbers,
          cycleIndex: restored.cycleIndex,
        );
        expect({
          for (final slot in mapping.initialState.skillSlots)
            if (slot.cooldownRemaining > 0) slot.slot: slot.cooldownRemaining,
        }, expected);
        expect(
          mapping.playerAdapter.numericSkillBindings.equipped.map(
            (binding) => (binding.slotId, binding.skill.id),
          ),
          result.mapping.playerAdapter.numericSkillBindings.equipped.map(
            (binding) => (binding.slotId, binding.skill.id),
          ),
          reason:
              'Repeated production autoFill preserves occupied slot identities',
        );
        expect(
          restored.playerSnapshot.currentHp,
          result.finalState.player.currentHealth,
        );
        expect(
          restored.playerSnapshot.currentQi,
          result.finalState.player.qiCurrent,
        );
        expect(restored.stage, result.leftWin ? plan.stage + 1 : plan.stage);
      } finally {
        if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
        IsarSetup.resetForTest();
        await dir.delete(recursive: true);
      }
    },
  );
}
