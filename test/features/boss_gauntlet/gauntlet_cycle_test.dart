import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// 批 B 断魂庄周目（spec 2026-08-01 拍板 #5）：enter 周目门槛硬守卫 +
/// run.cycleIndex 落库 + chooseReward 记 duanhunClearedCyclesMax / 奖励乘数 +
/// 旧档 cycle1 派生兜底。setup 沿 gauntlet_reward_test 体例（真 GameRepository +
/// P3 种子）。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_cycle_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  GauntletService svc() => GauntletService(IsarSetup.instance);

  Future<void> putTicket(int qty) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = GauntletService.ticketDefId
          ..itemType = ItemType.miscMaterial
          ..quantity = qty
          ..firstObtainedAt = DateTime(2026, 8, 4)
          ..lastObtainedAt = DateTime(2026, 8, 4),
      );
    });
  }

  /// P3 种子 id=1 弟子调成可入场态 + 指定境界。
  Future<void> makeEntrant(RealmTier tier) async {
    await IsarSetup.instance.writeTxn(() async {
      final c = (await IsarSetup.instance.characters.get(1))!;
      c
        ..isFounder = false
        ..lineageRole = LineageRole.disciple
        ..realmTier = tier
        ..currentRetreatSessionId = null;
      await IsarSetup.instance.characters.put(c);
    });
  }

  Future<void> setCleared({
    int cyclesMax = 0,
    DateTime? firstClearedAt,
  }) async {
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.duanhunClearedCyclesMax = cyclesMax;
      save.duanhunFirstClearedAt = firstClearedAt;
      await IsarSetup.instance.saveDatas.put(save);
    });
  }

  group('duanhunClearedCyclesMaxOf（旧档派生兜底）', () {
    test('字段为 0 但 duanhunFirstClearedAt 非空 → 派生 1', () {
      final save = SaveData()
        ..duanhunClearedCyclesMax = 0
        ..duanhunFirstClearedAt = DateTime(2026, 7, 1);
      expect(GauntletService.duanhunClearedCyclesMaxOf(save), 1);
    });

    test('字段更大时取字段；均空 → 0', () {
      final save = SaveData()..duanhunClearedCyclesMax = 2;
      expect(GauntletService.duanhunClearedCyclesMaxOf(save), 2);
      expect(GauntletService.duanhunClearedCyclesMaxOf(SaveData()), 0);
    });
  });

  group('enter 周目门槛（硬守卫）', () {
    test('cycle=2 未通 cycle1 → 抛（顺序解锁）', () async {
      await makeEntrant(RealmTier.wuSheng);
      await putTicket(1);
      await expectLater(
        svc().enter(characterIds: [1], supplyCap: 3, cycleIndex: 2),
        throwsA(isA<StateError>()),
      );
    });

    test('cycle=2 已通 cycle1 但境界不够 → 抛（境界门槛）', () async {
      // 断魂庄敌最高 erLiu（boss_gauntlets.yaml），cycle2 推进 +3 → zongShi，
      // margin 1 → 须 ≥ jueDing；sanLiu 不够。
      await makeEntrant(RealmTier.sanLiu);
      await putTicket(1);
      await setCleared(cyclesMax: 1);
      await expectLater(
        svc().enter(characterIds: [1], supplyCap: 3, cycleIndex: 2),
        throwsA(isA<StateError>()),
      );
    });

    test('cycle=2 已通 cycle1 且境界够 → 建会话且 run.cycleIndex=2', () async {
      await makeEntrant(RealmTier.wuSheng);
      await putTicket(1);
      await setCleared(cyclesMax: 1);
      await svc().enter(characterIds: [1], supplyCap: 3, cycleIndex: 2);
      final run = await svc().activeRun();
      expect(run, isNotNull);
      expect(run!.cycleIndex, 2);
    });

    test('cycle=1 默认路径不触境界门槛（低境界照常可入）', () async {
      await makeEntrant(RealmTier.xueTu);
      await putTicket(1);
      await svc().enter(characterIds: [1], supplyCap: 3);
      final run = await svc().activeRun();
      expect(run!.cycleIndex, 1);
    });

    test('cycle=0 → 抛（参数非法）', () async {
      await makeEntrant(RealmTier.wuSheng);
      await putTicket(1);
      await expectLater(
        svc().enter(characterIds: [1], supplyCap: 3, cycleIndex: 0),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('chooseReward 周目记账与奖励乘数', () {
    Future<void> putAwaitingRun({required int cycleIndex}) async {
      final config = GameRepository.instance.bossGauntletConfig!;
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.bossGauntletRuns.put(
          BossGauntletRun()
            ..saveDataId = 0
            ..seed = 0
            ..currentStage = 3
            ..cycleIndex = cycleIndex
            ..sessionPhase = GauntletPhase.awaitingRewardChoice
            ..members = [
              ActivityMemberSnapshot()
                ..characterId = 1
                ..maxHp = 5000
                ..currentHp = 3000,
            ]
            ..rewardCandidateDefIds = List.of(
              config.rewardCandidateEquipmentIds,
            )
            ..isFirstClearPending = false,
        );
      });
    }

    test('cycle2 结算 → duanhunClearedCyclesMax 记 2', () async {
      await setCleared(cyclesMax: 1, firstClearedAt: DateTime(2026, 7, 1));
      await putAwaitingRun(cycleIndex: 2);
      final config = GameRepository.instance.bossGauntletConfig!;
      await svc().chooseReward(
        chosenEquipmentDefId: config.rewardCandidateEquipmentIds.first,
        config: config,
        numbers: GameRepository.instance.numbers,
        rng: DefaultRng(seed: 7),
        now: DateTime(2026, 8, 4, 12),
      );
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      expect(save.duanhunClearedCyclesMax, 2);
    });

    test('cycle2 重复通关领悟点 = 半额 × rewardMultFor(2)（乘数生效）', () async {
      await setCleared(cyclesMax: 1, firstClearedAt: DateTime(2026, 7, 1));
      await putAwaitingRun(cycleIndex: 2);
      final config = GameRepository.instance.bossGauntletConfig!;
      final numbers = GameRepository.instance.numbers;
      final before = (await IsarSetup.instance.characters.get(
        1,
      ))!.insightPoints;
      await svc().chooseReward(
        chosenEquipmentDefId: config.rewardCandidateEquipmentIds.first,
        config: config,
        numbers: numbers,
        rng: DefaultRng(seed: 7),
        now: DateTime(2026, 8, 4, 12),
      );
      final after = (await IsarSetup.instance.characters.get(1))!.insightPoints;
      final mult = numbers.cycleEvolution.realmAdvance.rewardMultFor(2);
      expect(
        after - before,
        ((config.firstClearRewardInsight ~/ 2) * mult).round(),
      );
    });

    test('cycle1 结算不回退已记的更高周目（max 语义）', () async {
      await setCleared(cyclesMax: 2, firstClearedAt: DateTime(2026, 7, 1));
      await putAwaitingRun(cycleIndex: 1);
      final config = GameRepository.instance.bossGauntletConfig!;
      await svc().chooseReward(
        chosenEquipmentDefId: config.rewardCandidateEquipmentIds.first,
        config: config,
        numbers: GameRepository.instance.numbers,
        rng: DefaultRng(seed: 7),
        now: DateTime(2026, 8, 4, 12),
      );
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      expect(save.duanhunClearedCyclesMax, 2);
    });
  });
}
