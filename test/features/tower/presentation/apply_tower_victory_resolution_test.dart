import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_entry_flow.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_tower_0a_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<int> insertCharacter(
    String name, {
    LineageRole lineageRole = LineageRole.founder,
  }) {
    final character = Character.create(
      name: name,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: lineageRole,
      createdAt: DateTime(2026, 8, 22),
      internalForce: 3000,
    );
    return IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.characters.put(character),
    );
  }

  Future<void> writeSave(int founderId, int reserveId) {
    return IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..slotId = IsarSetup.currentSlotId
          ..saveVersion = '0.0.1'
          ..createdAt = DateTime(2026, 8, 22)
          ..lastSavedAt = DateTime(2026, 8, 22)
          ..lastOnlineAt = DateTime(2026, 8, 22)
          ..activeCharacterIds = [
            founderId,
            if (reserveId != founderId) reserveId,
          ]
          ..founderCharacterId = founderId,
      ),
    );
  }

  testWidgets('非 active 空闲门人实际参战时由本人承接塔结算', (tester) async {
    final ids = (await tester.runAsync(() async {
      final founderId = await insertCharacter('掌门');
      final discipleId = await insertCharacter(
        '门人',
        lineageRole: LineageRole.disciple,
      );
      await writeSave(founderId, founderId);
      return (founderId, discipleId);
    }))!;
    final floor = GameRepository.instance.getTowerFloor(1);
    final settlement = CombatSettlementSnapshot(
      result: BattleResult.leftWin,
      totalTicks: 37,
      hadActions: true,
      playerCharacterId: ids.$2,
      participants: [
        CombatParticipantSnapshot(
          characterId: ids.$2,
          currentHp: 7000,
          maxHp: 8000,
        ),
      ],
      skillCasts: const [],
      totalDamage: 456,
      criticalCount: 3,
      damageByCharacterId: {ids.$2: 456},
    );

    WidgetRef? capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (_, ref, _) {
              capturedRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    final result = await tester.runAsync(
      () => applyTowerCombatResolution(
        ref: capturedRef!,
        floor: floor,
        grantsFirstClearExperience: true,
        settlementSnapshot: settlement,
      ),
    );

    expect(result!.participantName, '门人');

    await tester.runAsync(() async {
      final founder = await IsarSetup.instance.characters.get(ids.$1);
      final disciple = await IsarSetup.instance.characters.get(ids.$2);
      expect(founder!.experience, 0, reason: '未参战掌门不得承接门人的塔结算');
      expect(disciple!.experience, floor.baseExpReward);
      expect(founder.lightInjuryStacks, 0);
      expect(disciple.lightInjuryStacks, 1);
    });
  });

  testWidgets('0A snapshot 只结算真实参战祖师，替补零污染', (tester) async {
    final ids = (await tester.runAsync(() async {
      final founderId = await insertCharacter('祖师');
      final reserveId = await insertCharacter('替补');
      await writeSave(founderId, reserveId);
      return (founderId, reserveId);
    }))!;
    final floor = GameRepository.instance.getTowerFloor(1);
    final settlement = CombatSettlementSnapshot(
      result: BattleResult.leftWin,
      totalTicks: 37,
      hadActions: true,
      playerCharacterId: ids.$1,
      participants: [
        CombatParticipantSnapshot(
          characterId: ids.$1,
          currentHp: 7000,
          maxHp: 8000,
        ),
      ],
      skillCasts: const [],
      totalDamage: 456,
      criticalCount: 3,
      damageByCharacterId: {ids.$1: 456},
    );

    WidgetRef? capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (_, ref, _) {
              capturedRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    final result = await tester.runAsync(
      () => applyTowerCombatResolution(
        ref: capturedRef!,
        floor: floor,
        grantsFirstClearExperience: true,
        settlementSnapshot: settlement,
      ),
    );

    expect(result!.stats.totalDamage, 456);
    expect(result.participantName, '祖师');
    expect(result.stats.critCount, 3);
    expect(result.stats.totalTicks, 37);
    await tester.runAsync(() async {
      final founder = await IsarSetup.instance.characters.get(ids.$1);
      final reserve = await IsarSetup.instance.characters.get(ids.$2);
      expect(founder!.experience, floor.baseExpReward);
      expect(reserve!.experience, 0, reason: '未参战替补不得获得塔首通经验');
      expect(founder.lightInjuryStacks, 1);
      expect(reserve.lightInjuryStacks, 0, reason: '未参战替补不得累积连战伤势');
    });
  });

  testWidgets('0A 败北由真实参战门人承接伤势且未参战掌门零污染', (tester) async {
    final ids = (await tester.runAsync(() async {
      final founderId = await insertCharacter('掌门');
      final discipleId = await insertCharacter(
        '门人',
        lineageRole: LineageRole.disciple,
      );
      await writeSave(founderId, founderId);
      return (founderId, discipleId);
    }))!;
    final floor = GameRepository.instance.getTowerFloor(1);
    final settlement = CombatSettlementSnapshot(
      result: BattleResult.rightWin,
      totalTicks: 37,
      hadActions: true,
      playerCharacterId: ids.$2,
      participants: [
        CombatParticipantSnapshot(
          characterId: ids.$2,
          currentHp: 0,
          maxHp: 8000,
        ),
      ],
      skillCasts: const [],
      totalDamage: 0,
      criticalCount: 0,
      damageByCharacterId: const {},
    );
    var defeatRecorded = false;
    int? reportedLightInjuryAdded;
    BuildContext? capturedContext;
    WidgetRef? capturedRef;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              capturedContext = context;
              capturedRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => runTowerFlow(
        context: capturedContext!,
        ref: capturedRef!,
        floor: floor,
        participantId: ids.$2,
        phase0aBattleOutcomeForTest: () async =>
            (won: false, surrendered: false, settlement: settlement),
        clearRecorderForTest: (_, _) async =>
            (isFirstClear: false, highestAfter: 0),
        defeatRecorderForTest: () async => defeatRecorded = true,
        defeatFactPresenterForTest: (facts) async {
          reportedLightInjuryAdded = facts.lightInjuryStacksAdded;
        },
      ),
    );

    expect(defeatRecorded, isTrue);
    expect(reportedLightInjuryAdded, 1);
    await tester.runAsync(() async {
      final founder = await IsarSetup.instance.characters.get(ids.$1);
      final disciple = await IsarSetup.instance.characters.get(ids.$2);
      expect(founder!.lightInjuryStacks, 0);
      expect(disciple!.lightInjuryStacks, 1);
      expect(founder.experience, 0);
      expect(disciple.experience, 0, reason: '塔败北不得发放首通经验');
    });
  });

  testWidgets('U09 塔进度、成长与 receipt 同事务回滚且重放防重', (tester) async {
    final founderId = (await tester.runAsync(() async {
      final id = await insertCharacter('原子结算门人');
      await writeSave(id, id);
      await TowerProgressService(
        isar: IsarSetup.instance,
      ).getOrCreate(saveDataId: IsarSetup.currentSlotId);
      return id;
    }))!;
    final floor = GameRepository.instance.getTowerFloor(1);
    final settlement = CombatSettlementSnapshot(
      result: BattleResult.leftWin,
      totalTicks: 10,
      hadActions: true,
      playerCharacterId: founderId,
      participants: [
        CombatParticipantSnapshot(
          characterId: founderId,
          currentHp: 7900,
          maxHp: 8000,
        ),
      ],
      skillCasts: const [],
      totalDamage: 100,
      criticalCount: 0,
      damageByCharacterId: {founderId: 100},
    );
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (_, value, _) {
              ref = value;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      await expectLater(
        applyTowerVictorySettlement(
          ref: ref,
          floor: floor,
          participantId: founderId,
          elapsedMs: 1234,
          settlementSnapshot: settlement,
          rewardOccurrenceId: 'tower-atomic-replay',
          afterProgressInTxnForTest: () async => throw StateError('crash'),
        ),
        throwsStateError,
      );
      var progress = await IsarSetup.instance.towerProgress.where().findFirst();
      var character = await IsarSetup.instance.characters.get(founderId);
      expect(progress!.highestClearedFloor, 0);
      expect(progress.totalAttempts, 0);
      expect(character!.experience, 0);
      expect(await IsarSetup.instance.rewardClaimReceipts.where().count(), 0);

      final applied = await applyTowerVictorySettlement(
        ref: ref,
        floor: floor,
        participantId: founderId,
        elapsedMs: 1234,
        settlementSnapshot: settlement,
        rewardOccurrenceId: 'tower-atomic-replay',
      );
      expect(applied.clearResult.isFirstClear, isTrue);
      progress = await IsarSetup.instance.towerProgress.where().findFirst();
      character = await IsarSetup.instance.characters.get(founderId);
      expect(progress!.highestClearedFloor, 1);
      expect(progress.totalAttempts, 1);
      expect(character!.experience, floor.baseExpReward);
      expect(await IsarSetup.instance.rewardClaimReceipts.where().count(), 3);

      await expectLater(
        applyTowerVictorySettlement(
          ref: ref,
          floor: floor,
          participantId: founderId,
          elapsedMs: 1234,
          settlementSnapshot: settlement,
          rewardOccurrenceId: 'tower-atomic-replay',
        ),
        throwsStateError,
      );
      progress = await IsarSetup.instance.towerProgress.where().findFirst();
      character = await IsarSetup.instance.characters.get(founderId);
      expect(progress!.totalAttempts, 1);
      expect(character!.experience, floor.baseExpReward);
      expect(await IsarSetup.instance.rewardClaimReceipts.where().count(), 3);
    });
  });
}
