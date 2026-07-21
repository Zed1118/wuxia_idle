import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';
import 'package:wuxia_idle/data/defs/item_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// C2.4c 断魂庄奖励三选一原子结算 + 幂等（最关键幂等·§6.2/§9.2）。
/// chooseReward 单事务：发选中命名装备 + 参战全员经验/领悟点 + 首通秘籍 + 记
/// clearedGauntletIds/duanhunFirstClearedAt + 返还托管 + 关会话；重复点击/重入只成功一次。
void main() {
  late Directory tempDir;

  final itemDefs = <String, ItemDef>{
    'item_liaoshangdan': const ItemDef(
      defId: 'item_liaoshangdan',
      type: ItemType.miscMaterial,
      name: '疗伤丹',
      gauntletHpHealPct: 0.30,
    ),
  };

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_reward_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> putAwaitingRun({
    required List<String> candidates,
    bool firstClearPending = true,
    List<String> escrowDefIds = const [],
    List<int> escrowLoaded = const [],
    List<int> escrowUsed = const [],
  }) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 0
          ..currentStage = 3
          ..sessionPhase = GauntletPhase.awaitingRewardChoice
          ..members = [
            ActivityMemberSnapshot()
              ..characterId = 1
              ..maxHp = 5000
              ..currentHp = 3000,
          ]
          ..rewardCandidateDefIds = List.of(candidates)
          ..isFirstClearPending = firstClearPending
          ..escrowItemDefIds = List.of(escrowDefIds)
          ..escrowLoadedQty = List.of(escrowLoaded)
          ..escrowUsedQty = List.of(escrowUsed),
      );
    });
  }

  Future<void> putInventory(String defId, int qty) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = defId
          ..itemType = ItemType.miscMaterial
          ..quantity = qty
          ..firstObtainedAt = DateTime(2026, 7, 17)
          ..lastObtainedAt = DateTime(2026, 7, 17),
      );
    });
  }

  Future<int?> qtyOf(String defId) async =>
      (await IsarSetup.instance.inventoryItems.getByDefId(defId))?.quantity;

  Future<int> ownedCount(String defId) async => IsarSetup.instance.equipments
      .filter()
      .defIdEqualTo(defId)
      .ownerCharacterIdIsNull()
      .count();

  GauntletService svc() =>
      GauntletService(IsarSetup.instance, itemDefs: itemDefs);

  test('首通 chooseReward：发装备+领悟点+秘籍+记通关+返还托管+关会话（原子）', () async {
    final config = GameRepository.instance.bossGauntletConfig!;
    final chosen = config.rewardCandidateEquipmentIds.first;
    await putAwaitingRun(
      candidates: config.rewardCandidateEquipmentIds,
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [2],
      escrowUsed: [1],
    );
    await putInventory('item_liaoshangdan', 0); // 已移入托管
    final insightBefore = (await IsarSetup.instance.characters.get(
      1,
    ))!.insightPoints;

    await svc().chooseReward(
      chosenEquipmentDefId: chosen,
      config: config,
      numbers: GameRepository.instance.numbers,
      rng: DefaultRng(seed: 7),
      now: DateTime(2026, 7, 17, 12),
    );

    // ① 选中命名装备入背包（owner=null）。
    expect(await ownedCount(chosen), 1, reason: '发一件选中装备到背包');
    // ② 参战角色得领悟点（首通额）。
    final insightAfter = (await IsarSetup.instance.characters.get(
      1,
    ))!.insightPoints;
    expect(insightAfter, greaterThan(insightBefore), reason: '发领悟点');
    // ③ 首通秘籍解锁 + 记首通时间 + 记通关。
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    expect(
      save.skillUnlockProgress.isUnlocked(config.firstClearRewardSkillId),
      isTrue,
      reason: '首通解锁锁脉针法',
    );
    expect(save.clearedGauntletIds, contains(GauntletService.gauntletId));
    expect(save.duanhunFirstClearedAt, isNotNull);
    // ④ 返还托管（Loaded-Used=2-1）。
    expect(await qtyOf('item_liaoshangdan'), 1);
    // ⑤ 关会话。
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('幂等：结算后重入（无 run）→ no-op 不重复发装备', () async {
    final config = GameRepository.instance.bossGauntletConfig!;
    final chosen = config.rewardCandidateEquipmentIds.first;
    await putAwaitingRun(candidates: config.rewardCandidateEquipmentIds);

    final s = svc();
    await s.chooseReward(
      chosenEquipmentDefId: chosen,
      config: config,
      numbers: GameRepository.instance.numbers,
      rng: DefaultRng(seed: 7),
    );
    expect(await ownedCount(chosen), 1);
    // 第二次点击：会话已删 → no-op（不抛·不重复发）。
    await s.chooseReward(
      chosenEquipmentDefId: chosen,
      config: config,
      numbers: GameRepository.instance.numbers,
      rng: DefaultRng(seed: 7),
    );
    expect(await ownedCount(chosen), 1, reason: '重入不重复发装备');
  });

  test('非候选 defId → 抛错（不发放）', () async {
    final config = GameRepository.instance.bossGauntletConfig!;
    await putAwaitingRun(candidates: config.rewardCandidateEquipmentIds);
    await expectLater(
      svc().chooseReward(
        chosenEquipmentDefId: 'weapon_not_a_candidate',
        config: config,
        numbers: GameRepository.instance.numbers,
        rng: DefaultRng(seed: 7),
      ),
      throwsStateError,
    );
  });

  test('非 awaitingRewardChoice（interlude）→ 抛错', () async {
    final config = GameRepository.instance.bossGauntletConfig!;
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 0
          ..currentStage = 2
          ..sessionPhase = GauntletPhase.interlude
          ..members = [ActivityMemberSnapshot()..characterId = 1],
      );
    });
    await expectLater(
      svc().chooseReward(
        chosenEquipmentDefId: config.rewardCandidateEquipmentIds.first,
        config: config,
        numbers: GameRepository.instance.numbers,
        rng: DefaultRng(seed: 7),
      ),
      throwsStateError,
    );
  });

  test('无存档选奖 → 抛错（不发放）', () async {
    final config = GameRepository.instance.bossGauntletConfig!;
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.delete(0);
    });
    await expectLater(
      svc().chooseReward(
        chosenEquipmentDefId: config.rewardCandidateEquipmentIds.first,
        config: config,
        numbers: GameRepository.instance.numbers,
        rng: DefaultRng(seed: 7),
      ),
      throwsStateError,
    );
    expect(await IsarSetup.instance.equipments.count(), 0, reason: '未发装备');
  });

  test('重复通关 chooseReward：经验/领悟点取半（§6.2）·不重复记通关/首通', () async {
    final config = GameRepository.instance.bossGauntletConfig!;
    final chosen = config.rewardCandidateEquipmentIds.first;
    // 已通关存档 + 非首通会话（重复通关态）。
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!
        ..clearedGauntletIds = [GauntletService.gauntletId];
      await IsarSetup.instance.saveDatas.put(save);
    });
    await putAwaitingRun(
      candidates: config.rewardCandidateEquipmentIds,
      firstClearPending: false,
    );
    final before = (await IsarSetup.instance.characters.get(1))!;
    final expBefore = before.experience;
    final insightBefore = before.insightPoints;

    await svc().chooseReward(
      chosenEquipmentDefId: chosen,
      config: config,
      numbers: GameRepository.instance.numbers,
      rng: DefaultRng(seed: 7),
      now: DateTime(2026, 7, 17, 12),
    );

    final after = (await IsarSetup.instance.characters.get(1))!;
    expect(
      after.experience - expBefore,
      config.firstClearRewardExp ~/ 2,
      reason: '重复通关经验取半',
    );
    expect(
      after.insightPoints - insightBefore,
      config.firstClearRewardInsight ~/ 2,
      reason: '重复通关领悟点取半',
    );
    expect(await ownedCount(chosen), 1, reason: '装备照发');
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    expect(save.clearedGauntletIds, hasLength(1), reason: '已通关不重复记');
    expect(save.duanhunFirstClearedAt, isNull, reason: '非首通不重记首通时间');
    expect(
      save.skillUnlockProgress.isUnlocked(config.firstClearRewardSkillId),
      isFalse,
      reason: '非首通不走首通秘籍解锁',
    );
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('chooseReward 有主线进度行：经验照发（cleared 集参与层锁判定）', () async {
    final config = GameRepository.instance.bossGauntletConfig!;
    final chosen = config.rewardCandidateEquipmentIds.first;
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.mainlineProgress.put(
        MainlineProgress()
          ..saveDataId = 0
          ..clearedStageIds = ['stage_01_01'],
      );
    });
    await putAwaitingRun(candidates: config.rewardCandidateEquipmentIds);
    final expBefore = (await IsarSetup.instance.characters.get(1))!.experience;

    await svc().chooseReward(
      chosenEquipmentDefId: chosen,
      config: config,
      numbers: GameRepository.instance.numbers,
      rng: DefaultRng(seed: 7),
    );

    final after = (await IsarSetup.instance.characters.get(1))!;
    expect(
      after.experience - expBefore,
      config.firstClearRewardExp,
      reason: '首通全额经验照发（进度行存在亦不影响发放）',
    );
  });

  test('chooseReward 奖励经验跨层：经层锁门禁判定后升层（发布上限内）', () async {
    final config = GameRepository.instance.bossGauntletConfig!;
    final chosen = config.rewardCandidateEquipmentIds.first;
    await putAwaitingRun(candidates: config.rewardCandidateEquipmentIds);
    // 经验调到当前层阈值-1：首通经验必触发一次跨层 → 走 isLayerLocked 判定。
    final repo = GameRepository.instance;
    final before = (await IsarSetup.instance.characters.get(1))!;
    final threshold = repo
        .getRealm(before.realmTier, before.realmLayer)
        .experienceToNext;
    await IsarSetup.instance.writeTxn(() async {
      final ch = (await IsarSetup.instance.characters.get(1))!
        ..experience = threshold - 1;
      await IsarSetup.instance.characters.put(ch);
    });

    await svc().chooseReward(
      chosenEquipmentDefId: chosen,
      config: config,
      numbers: GameRepository.instance.numbers,
      rng: DefaultRng(seed: 7),
    );

    final after = (await IsarSetup.instance.characters.get(1))!;
    final next = CharacterAdvancementService.nextLayer(
      before.realmTier,
      before.realmLayer,
    )!;
    expect(after.realmTier, next.tier);
    expect(after.realmLayer, next.layer, reason: '发布上限内不被拦·升一层');
    expect(
      after.experience,
      config.firstClearRewardExp - 1,
      reason: 'threshold-1 + 首通经验 - threshold',
    );
  });
}
