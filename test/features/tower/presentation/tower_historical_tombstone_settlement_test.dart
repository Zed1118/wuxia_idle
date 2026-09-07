import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_usage_entry.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/application/durable_activity_automation_service.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_unlock_service.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/features/tower/domain/tower_automation_policy.dart';
import 'package:wuxia_idle/features/tower/domain/tower_personal_record.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_entry_flow.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_contract.dart';
import 'package:wuxia_idle/shared/utils/math_random.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

class _AlwaysDropRandom implements math.Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}

void main() {
  late Directory tempDir;
  final at = DateTime(2026, 8, 22);

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tower_bad_tombstone_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  RewardClaimReceipt tombstoneFor(int floorIndex) {
    return RewardClaimReceipt.fromKey(
      key: RewardClaimKey.contentLayer(
        contentKind: RewardContentKind.tower,
        contentId: 'tower_floor_${floorIndex}_cycle_1',
        layer: RewardLayer.firstClear,
        scope: RewardScope.sectShared,
        saveDataId: IsarSetup.currentSlotId,
        participantId: null,
        occurrenceId: 'historical',
      ),
      sourceSettlementId:
          'migration:0.42.0:cleared-tower:tower_floor_${floorIndex}_cycle_1',
      createdAt: at,
      isHistoricalTombstone: true,
    );
  }

  Future<int> seedHistoricalSave({int highestClearedFloor = 30}) async {
    final isar = IsarSetup.instance;
    return isar.writeTxn(() async {
      final character = Character.create(
        name: '老档门人',
        realmTier: RealmTier.jueDing,
        realmLayer: RealmLayer.shuLian,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        isFounder: true,
        school: TechniqueSchool.gangMeng,
        createdAt: at,
        internalForce: 3000,
      );
      final participantId = await isar.characters.put(character);
      character.mainTechniqueId = await isar.techniques.put(
        Technique.create(
          defId: 'tech_gangmeng_jichu',
          ownerCharacterId: participantId,
          tier: TechniqueTier.ruMenGong,
          school: TechniqueSchool.gangMeng,
          role: TechniqueRole.main,
          learnedAt: at,
        ),
      );
      await isar.characters.put(character);
      final save = (await isar.saveDatas.get(0))!;
      save
        ..saveVersion = '0.45.0'
        ..grantedTicketMilestoneIds = ['tower_floor_16']
        ..activeCharacterIds = [participantId]
        ..founderCharacterId = participantId;
      await isar.saveDatas.put(save);
      await isar.towerProgress.put(
        TowerProgress()
          ..saveDataId = IsarSetup.currentSlotId
          ..highestClearedFloor = highestClearedFloor
          ..maxClearedCycle = 1
          ..currentCycleIndex = 1
          ..createdAt = at,
      );
      await isar.rewardClaimReceipts.putAll([
        tombstoneFor(31),
        tombstoneFor(32),
      ]);
      return participantId;
    });
  }

  CombatSettlementSnapshot victoryFor(int participantId) {
    return CombatSettlementSnapshot(
      result: BattleResult.leftWin,
      totalTicks: 10,
      hadActions: true,
      playerCharacterId: participantId,
      participants: [
        CombatParticipantSnapshot(
          characterId: participantId,
          currentHp: 7900,
          maxHp: 8000,
        ),
      ],
      skillCasts: [
        CombatSkillCastSnapshot(
          tick: 1,
          characterId: participantId,
          skillId: 'skill_gangmeng_jichu_basic',
        ),
      ],
      totalDamage: 100,
      criticalCount: 0,
      damageByCharacterId: {participantId: 100},
    );
  }

  Future<WidgetRef> mountRef(WidgetTester tester) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mathRandomProvider.overrideWithValue(_AlwaysDropRandom())],
        child: MaterialApp(
          home: Consumer(
            builder: (_, ref, _) {
              captured = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  Future<int> skillUses() async {
    final technique = (await IsarSetup.instance.techniques
        .where()
        .findFirst())!;
    return technique.skillUsageCount.countOf('skill_gangmeng_jichu_basic');
  }

  testWidgets('老档坏墓碑未经修复迁移也能经生产结算突破31层并继续32层', (tester) async {
    final participantId = (await tester.runAsync(seedHistoricalSave))!;
    final ref = await mountRef(tester);
    await tester.runAsync(() async {
      final isar = IsarSetup.instance;
      final snapshot = victoryFor(participantId);
      final itemCount = await isar.inventoryItems.count();
      final equipmentCount = await isar.equipments.count();
      final first = await applyTowerVictorySettlement(
        ref: ref,
        floor: GameRepository.instance.getTowerFloor(31),
        participantId: participantId,
        elapsedMs: 1234,
        settlementSnapshot: snapshot,
        rewardOccurrenceId: 'legacy-floor31',
      );
      expect(first.clearResult.isFirstClear, isTrue);
      expect(first.clearResult.highestAfter, 31);
      expect(first.drops.items, isEmpty);
      expect(first.drops.equipments, isEmpty);
      expect(
        (await isar.towerProgress.where().findFirst())!.highestClearedFloor,
        31,
      );
      expect((await isar.characters.get(participantId))!.experience, 0);
      expect((await isar.characters.get(participantId))!.lightInjuryStacks, 1);
      expect(await skillUses(), 1);
      expect(await isar.inventoryItems.count(), itemCount);
      expect(await isar.equipments.count(), equipmentCount);
      expect(await isar.rewardClaimReceipts.count(), 4);
      expect(
        (await isar.saveDatas.get(0))!.saveVersion,
        '0.45.0',
        reason: '结算加固必须在数据修复迁移尚未运行时独立解锁进度',
      );
      expect(
        await isar.rewardClaimReceipts.getByClaimKey(tombstoneFor(31).claimKey),
        isNotNull,
      );

      await expectLater(
        applyTowerVictorySettlement(
          ref: ref,
          floor: GameRepository.instance.getTowerFloor(31),
          participantId: participantId,
          elapsedMs: 1234,
          settlementSnapshot: snapshot,
          rewardOccurrenceId: 'legacy-floor31',
        ),
        throwsStateError,
      );
      expect((await isar.towerProgress.where().findFirst())!.totalAttempts, 1);
      expect((await isar.characters.get(participantId))!.lightInjuryStacks, 1);
      expect(await skillUses(), 1);

      final next = await applyTowerVictorySettlement(
        ref: ref,
        floor: GameRepository.instance.getTowerFloor(32),
        participantId: participantId,
        elapsedMs: 1234,
        settlementSnapshot: snapshot,
        rewardOccurrenceId: 'legacy-floor32',
      );
      expect(next.clearResult.highestAfter, 32);
      expect(next.skillDrop.fragmentSkillId, 'skill_ma_ta_fei_yan');
      expect(next.skillDrop.fragmentCount, 1);
      expect(await skillUses(), 2);
      expect(next.drops.items, isEmpty);
      expect(next.drops.equipments, isEmpty);
      expect((await isar.characters.get(participantId))!.experience, 0);
      expect(await isar.inventoryItems.count(), itemCount);
      expect(await isar.equipments.count(), equipmentCount);
      expect(await isar.rewardClaimReceipts.count(), 6);
    });
  });

  for (final version in ['0.41.0', '0.45.0']) {
    testWidgets('$version老档重开迁移后经生产结算通关31层并领取真实首通奖励', (tester) async {
      final participantId = (await tester.runAsync(() async {
        final id = await seedHistoricalSave();
        if (version == '0.41.0') {
          final isar = IsarSetup.instance;
          await isar.writeTxn(() async {
            final save = (await isar.saveDatas.get(0))!;
            save.saveVersion = version;
            await isar.saveDatas.put(save);
            await isar.rewardClaimReceipts.clear();
          });
        }
        await IsarSetup.close();
        await IsarSetup.init(directory: tempDir, inspector: false);
        return id;
      }))!;
      final ref = await mountRef(tester);
      await tester.runAsync(() async {
        final isar = IsarSetup.instance;
        expect((await isar.saveDatas.get(0))!.saveVersion, '0.46.0');
        expect(
          await isar.rewardClaimReceipts.getByClaimKey(
            tombstoneFor(31).claimKey,
          ),
          isNull,
        );
        final floor = GameRepository.instance.getTowerFloor(31);
        final result = await applyTowerVictorySettlement(
          ref: ref,
          floor: floor,
          participantId: participantId,
          elapsedMs: 1234,
          settlementSnapshot: victoryFor(participantId),
          rewardOccurrenceId: 'migrated-floor31',
        );
        expect(result.clearResult.isFirstClear, isTrue);
        expect(
          (await isar.towerProgress.where().findFirst())!.highestClearedFloor,
          31,
        );
        expect(
          (await isar.characters.get(participantId))!.experience,
          floor.baseExpReward,
        );
        expect(result.drops.items, isNotEmpty);
        expect(
          (await isar.rewardClaimReceipts.getByClaimKey(
            tombstoneFor(31).claimKey,
          ))!.isHistoricalTombstone,
          isFalse,
        );
      });
    });
  }

  for (final durable in [false, true]) {
    testWidgets('${durable ? '离线durable' : '普通'}塔重打仍发残页和成长，失败回滚且同场不双发', (
      tester,
    ) async {
      final participantId = (await tester.runAsync(
        () => seedHistoricalSave(highestClearedFloor: 32),
      ))!;
      final ref = await mountRef(tester);
      await tester.runAsync(() async {
        final isar = IsarSetup.instance;
        final floor = GameRepository.instance.getTowerFloor(32);
        final service = DurableActivityAutomationService(isar);
        final runId = durable
            ? await service.startTower(
                floor: floor,
                cycleIndex: 1,
                request: towerDurableDispatchRequest(
                  floorIndex: 32,
                  characterId: participantId,
                ),
              )
            : null;
        final context = runId == null
            ? null
            : DurableActivitySettlementContext(service: service, runId: runId);
        final itemCount = await isar.inventoryItems.count();
        final equipmentCount = await isar.equipments.count();
        final skillService = SkillUnlockService(isar);
        Future<TowerVictorySettlement> settle({bool fail = false}) {
          return applyTowerVictorySettlement(
            ref: ref,
            floor: floor,
            participantId: participantId,
            elapsedMs: 1234,
            settlementSnapshot: victoryFor(participantId),
            rewardOccurrenceId: 'floor32-repeat',
            durableActivitySettlement: context,
            afterProgressInTxnForTest: fail
                ? () async => throw StateError('rollback after progress')
                : null,
          );
        }

        await expectLater(settle(fail: true), throwsStateError);
        expect(
          (await isar.towerProgress.where().findFirst())!.totalAttempts,
          0,
        );
        expect(await isar.towerPersonalRecords.count(), 0);
        expect(await isar.rewardClaimReceipts.count(), 2);
        expect(await skillUses(), 0);
        expect(
          (await isar.characters.get(participantId))!.lightInjuryStacks,
          0,
        );
        expect(
          (await skillService.fragmentProgress(floor.dropSkillFragmentId!)).$1,
          0,
        );
        if (runId != null) {
          expect(
            (await service.runById(runId))!.phase,
            DurableActivityPhase.active,
          );
        }

        final result = await settle();
        expect(result.clearResult.isFirstClear, isFalse);
        expect(result.skillDrop.fragmentCount, 1);
        expect(await skillUses(), 1);
        expect(result.drops.items, isEmpty);
        expect(result.drops.equipments, isEmpty);
        expect(
          (await isar.towerProgress.where().findFirst())!.totalAttempts,
          1,
        );
        expect((await isar.characters.get(participantId))!.experience, 0);
        expect(
          (await isar.characters.get(participantId))!.lightInjuryStacks,
          1,
        );
        expect(
          (await skillService.fragmentProgress(floor.dropSkillFragmentId!)).$1,
          1,
        );
        expect(await isar.rewardClaimReceipts.count(), 4);
        expect(await isar.towerPersonalRecords.count(), 1);
        expect(await isar.inventoryItems.count(), itemCount);
        expect(await isar.equipments.count(), equipmentCount);
        if (runId != null) {
          expect(
            (await service.runById(runId))!.phase,
            DurableActivityPhase.settlementApplied,
          );
        }

        await expectLater(settle(), throwsStateError);
        expect(await skillUses(), 1);
        expect(
          (await isar.towerProgress.where().findFirst())!.totalAttempts,
          1,
        );
        expect(
          (await isar.characters.get(participantId))!.lightInjuryStacks,
          1,
        );
        expect(
          (await skillService.fragmentProgress(floor.dropSkillFragmentId!)).$1,
          1,
        );
        expect(await isar.rewardClaimReceipts.count(), 4);
      });
    });
  }
}
