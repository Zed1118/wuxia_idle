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
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
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
}
