import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/boss_gauntlet_config.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/gauntlet_automation_policy.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

const _losingReplayConfig = BossGauntletConfig(
  stages: [
    GauntletStageConfig(role: 'elite', enemyTeamId: 'unused'),
    GauntletStageConfig(role: 'boss', enemyTeamId: 'strong'),
  ],
  supplyCap: 3,
  firstClearRewardSkillId: 'skill_x',
  rewardCandidateEquipmentIds: [
    'weapon_haojiahuo_qing_feng_jian',
    'armor_haojiahuo_jin_pao',
    'accessory_haojiahuo_yu_pei_lao',
  ],
  eliteRewardExp: 100,
  enemyTeams: {
    'strong': [
      EnemyDef(
        id: 'strong_durable_e',
        name: 'strong durable enemy',
        realmTier: RealmTier.wuSheng,
        realmLayer: RealmLayer.dengFeng,
        school: TechniqueSchool.gangMeng,
        baseHp: 60000,
        baseAttack: 60000,
        baseSpeed: 1000,
        skillIds: ['skill_gangmeng_jichu_basic'],
        iconPath: '',
      ),
    ],
  },
);

void main() {
  late Directory tempDir;
  late Character participant;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_durable_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    participant = (await IsarSetup.instance.characters.where().findFirst())!;
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save
        ..founderCharacterId = participant.id
        ..activeCharacterIds = [participant.id]
        ..clearedGauntletIds = [GauntletService.gauntletId]
        ..duanhunClearedCyclesMax = 1;
      await IsarSetup.instance.saveDatas.put(save);
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = GauntletService.ticketDefId
          ..itemType = ItemType.ticket
          ..quantity = 1
          ..firstObtainedAt = DateTime.utc(2026, 9, 1)
          ..lastObtainedAt = DateTime.utc(2026, 9, 1),
      );
    });
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('扣帖、Boss 会话与 exact participant durable owner 同事务创建', () async {
    final request = gauntletDurableDispatchRequest(characterId: participant.id);
    final started = await GauntletService(IsarSetup.instance)
        .enterDurableDispatch(
          characterIds: [participant.id],
          supplyCap: 3,
          cycleIndex: 1,
          request: request,
          now: DateTime.utc(2026, 9, 1, 8),
        );

    final boss = (await IsarSetup.instance.bossGauntletRuns.get(
      started.gauntletRunId,
    ))!;
    final durable = (await IsarSetup.instance.durableActivityCombatRuns.get(
      started.durableRunId,
    ))!;
    expect(durable.kind, DurableActivityKind.gauntlet);
    expect(durable.request, request);
    expect(durable.stageId, gauntletDurableStageId(boss.id));
    expect(durable.members.single.characterId, participant.id);
    expect(
      durable.members.single.reservedEquipmentIds,
      boss.members.single.reservedEquipmentIds,
    );
    expect(
      durable.members.single.reservedTechniqueIds,
      boss.members.single.reservedTechniqueIds,
    );
    expect(durable.participantCreatedAt, participant.createdAt);
    expect(durable.participantName, participant.name);
    expect(durable.phase, DurableActivityPhase.active);
    expect(
      (await IsarSetup.instance.inventoryItems.getByDefId(
        GauntletService.ticketDefId,
      ))!.quantity,
      0,
    );
  });

  test('无帖时原子失败，不遗留 Boss 会话或 durable owner', () async {
    await IsarSetup.instance.writeTxn(() async {
      final ticket = (await IsarSetup.instance.inventoryItems.getByDefId(
        GauntletService.ticketDefId,
      ))!;
      ticket.quantity = 0;
      await IsarSetup.instance.inventoryItems.put(ticket);
    });

    await expectLater(
      GauntletService(IsarSetup.instance).enterDurableDispatch(
        characterIds: [participant.id],
        supplyCap: 3,
        cycleIndex: 1,
        request: gauntletDurableDispatchRequest(characterId: participant.id),
      ),
      throwsStateError,
    );
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
    expect(await IsarSetup.instance.durableActivityCombatRuns.count(), 0);
  });

  test('恢复已到三选一边界只落 victory receipt，不替玩家选奖', () async {
    final service = GauntletService(IsarSetup.instance);
    final started = await service.enterDurableDispatch(
      characterIds: [participant.id],
      supplyCap: 3,
      cycleIndex: 1,
      request: gauntletDurableDispatchRequest(characterId: participant.id),
    );
    await IsarSetup.instance.writeTxn(() async {
      final boss = (await IsarSetup.instance.bossGauntletRuns.get(
        started.gauntletRunId,
      ))!;
      boss
        ..sessionPhase = GauntletPhase.awaitingRewardChoice
        ..rewardCandidateDefIds = List.of(
          GameRepository
              .instance
              .bossGauntletConfig!
              .rewardCandidateEquipmentIds,
        );
      await IsarSetup.instance.bossGauntletRuns.put(boss);
    });

    final equipmentCountBefore = await IsarSetup.instance.equipments
        .where()
        .count();

    final result = await service.resumeDurableDispatch(
      durableRunId: started.durableRunId,
      config: GameRepository.instance.bossGauntletConfig!,
      numbers: GameRepository.instance.numbers,
    );

    expect(
      result.terminal,
      GauntletAutomationDriveTerminal.awaitingRewardChoice,
    );
    final durable = (await IsarSetup.instance.durableActivityCombatRuns.get(
      started.durableRunId,
    ))!;
    expect(durable.phase, DurableActivityPhase.settlementApplied);
    expect(durable.outcome, DurableActivityOutcome.victory);
    final boss = (await IsarSetup.instance.bossGauntletRuns.get(
      started.gauntletRunId,
    ))!;
    expect(boss.sessionPhase, GauntletPhase.awaitingRewardChoice);
    expect(boss.rewardCandidateDefIds, isNotEmpty);
    expect(
      await IsarSetup.instance.equipments.where().count(),
      equipmentCountBefore,
      reason: '恢复不能替玩家挑选三选一',
    );

    await expectLater(
      service.resumeDurableDispatch(
        durableRunId: started.durableRunId,
        config: GameRepository.instance.bossGauntletConfig!,
        numbers: GameRepository.instance.numbers,
      ),
      throwsStateError,
    );
  });

  test('恢复前 exact participant 装配漂移时 fail closed', () async {
    final service = GauntletService(IsarSetup.instance);
    final started = await service.enterDurableDispatch(
      characterIds: [participant.id],
      supplyCap: 3,
      cycleIndex: 1,
      request: gauntletDurableDispatchRequest(characterId: participant.id),
    );
    final lastAdvancedAtBefore =
        (await IsarSetup.instance.durableActivityCombatRuns.get(
          started.durableRunId,
        ))!.lastAdvancedAt;
    await IsarSetup.instance.writeTxn(() async {
      final current = (await IsarSetup.instance.characters.get(
        participant.id,
      ))!;
      current.mainTechniqueId = current.mainTechniqueId! + 999;
      await IsarSetup.instance.characters.put(current);
    });

    await expectLater(
      service.resumeDurableDispatch(
        durableRunId: started.durableRunId,
        config: GameRepository.instance.bossGauntletConfig!,
        numbers: GameRepository.instance.numbers,
      ),
      throwsStateError,
    );
    final durable = (await IsarSetup.instance.durableActivityCombatRuns.get(
      started.durableRunId,
    ))!;
    expect(durable.phase, DurableActivityPhase.active);
    expect(durable.outcome, DurableActivityOutcome.none);
    expect(
      durable.lastAdvancedAt,
      lastAdvancedAtBefore,
      reason: '装配漂移必须在更新推进游标或进入战斗前失败',
    );
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 1);
  });

  test('自动战败时 Boss 结算与 defeat receipt 同一终局且不可重放', () async {
    final service = GauntletService(IsarSetup.instance);
    final started = await service.enterDurableDispatch(
      characterIds: [participant.id],
      supplyCap: 3,
      cycleIndex: 1,
      request: gauntletDurableDispatchRequest(characterId: participant.id),
    );
    await IsarSetup.instance.writeTxn(() async {
      final boss = (await IsarSetup.instance.bossGauntletRuns.get(
        started.gauntletRunId,
      ))!;
      boss
        ..currentStage = 2
        ..sessionPhase = GauntletPhase.inBattle;
      boss.members.single
        ..currentHp = 1
        ..maxHp = 1;
      await IsarSetup.instance.bossGauntletRuns.put(boss);
    });
    final equipmentBefore = await IsarSetup.instance.equipments.where().count();

    final result = await service.resumeDurableDispatch(
      durableRunId: started.durableRunId,
      config: _losingReplayConfig,
      numbers: GameRepository.instance.numbers,
    );

    expect(result.terminal, GauntletAutomationDriveTerminal.defeated);
    expect(result.defeatedAtStage, 2);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
    final durable = (await IsarSetup.instance.durableActivityCombatRuns.get(
      started.durableRunId,
    ))!;
    expect(durable.phase, DurableActivityPhase.settlementApplied);
    expect(durable.outcome, DurableActivityOutcome.defeat);
    expect(
      await IsarSetup.instance.equipments.where().count(),
      equipmentBefore,
      reason: '战败不得发放三选一装备',
    );
    await expectLater(
      service.resumeDurableDispatch(
        durableRunId: started.durableRunId,
        config: _losingReplayConfig,
        numbers: GameRepository.instance.numbers,
      ),
      throwsStateError,
    );
  });
}
