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
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/data/defs/boss_gauntlet_config.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// C2.5 断魂庄失败结算（§6.3）：战败 / 认输离庄统一结算。
///
/// 只发「已击败精英经验」给全体参战（含途中倒下者·层锁受发布上限）+ 按战末快照结算
/// 轻/重伤（倒下者重伤·存活者轻伤·不扣永久内力）+ 返还托管补给 + 关会话；装备/秘籍/
/// 领悟点/最终奖励全部失去；不记 `clearedGauntletIds`。幂等：无 active 会话 → no-op。
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_failure_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  BossGauntletConfig config() => GameRepository.instance.bossGauntletConfig!;
  NumbersConfig numbers() => GameRepository.instance.numbers;
  GauntletService svc() =>
      GauntletService(IsarSetup.instance, itemDefs: itemDefs);

  ActivityMemberSnapshot member({
    int id = 1,
    int maxHp = 5000,
    int currentHp = 2000,
    bool downed = false,
  }) => ActivityMemberSnapshot()
    ..characterId = id
    ..maxHp = maxHp
    ..maxQi = 100
    ..currentHp = currentHp
    ..currentQi = 50
    ..isDowned = downed;

  /// 造进行中会话。默认 `currentStage=3`（Boss 关）·`inBattle`（战败态：advance 败不推进
  /// 停当前关）。members 用 [member] 构造（maxHp>0 表已战斗过）。
  Future<void> putRun({
    int currentStage = 3,
    GauntletPhase phase = GauntletPhase.inBattle,
    required List<ActivityMemberSnapshot> members,
    List<String> escrowDefIds = const [],
    List<int> escrowLoaded = const [],
    List<int> escrowUsed = const [],
  }) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 0
          ..currentStage = currentStage
          ..sessionPhase = phase
          ..members = members
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

  /// 把 char1 经验清零（二流层阈值 »100·+100 精英经验不触层跃迁 → 精确断言）。
  Future<void> zeroExp(int id) async {
    await IsarSetup.instance.writeTxn(() async {
      final ch = (await IsarSetup.instance.characters.get(id))!;
      ch.experience = 0;
      await IsarSetup.instance.characters.put(ch);
    });
  }

  test('战败结算：已击败精英经验发全体参战 + 返还托管 + 关会话（Boss 关败=2 精英）', () async {
    await zeroExp(1);
    await putRun(
      members: [member()],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [2],
      escrowUsed: [1],
    );
    await putInventory('item_liaoshangdan', 0); // 已移入托管

    await svc().settleDefeat(
      config: config(),
      numbers: numbers(),
      now: DateTime(2026, 7, 17, 12),
    );

    // ① 已击败 2 精英 → 发 2×eliteRewardExp（非整包 firstClearRewardExp）。
    final expAfter = (await IsarSetup.instance.characters.get(1))!.experience;
    expect(expAfter, 2 * config().eliteRewardExp, reason: '两精英经验（各一份）');
    // ② 返还托管（Loaded-Used=2-1=1）。
    expect(await qtyOf('item_liaoshangdan'), 1);
    // ③ 关会话。
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('战败结算：途中倒下者照常得精英经验（§6.3 含倒下者）', () async {
    await zeroExp(1);
    await putRun(members: [member(downed: true, currentHp: 0)]);

    await svc().settleDefeat(config: config(), numbers: numbers());

    final expAfter = (await IsarSetup.instance.characters.get(1))!.experience;
    expect(expAfter, 2 * config().eliteRewardExp, reason: '倒下者仍得已击败精英经验');
  });

  test('战败结算：倒下者结重伤（injuryHoursRemaining>0·不扣永久内力）', () async {
    final ifBefore = (await IsarSetup.instance.characters.get(
      1,
    ))!.internalForce;
    await putRun(members: [member(downed: true, currentHp: 0)]);

    await svc().settleDefeat(config: config(), numbers: numbers());

    final ch = (await IsarSetup.instance.characters.get(1))!;
    expect(ch.injuryHoursRemaining, greaterThan(0), reason: '倒下者重伤');
    expect(ch.internalForce, ifBefore, reason: '不扣永久内力（§6.3）');
  });

  test('战败结算：存活者结轻伤（lightInjuryStacks>0·非重伤）', () async {
    await putRun(members: [member(downed: false, currentHp: 1800)]);

    await svc().settleDefeat(config: config(), numbers: numbers());

    final ch = (await IsarSetup.instance.characters.get(1))!;
    expect(ch.lightInjuryStacks, greaterThan(0), reason: '存活者轻伤');
    expect(ch.injuryHoursRemaining, 0, reason: '存活者不进重伤');
  });

  test('失败结算：装备/领悟点/秘籍/最终奖励全失·不记通关（§6.3）', () async {
    final insightBefore = (await IsarSetup.instance.characters.get(
      1,
    ))!.insightPoints;
    await putRun(members: [member()]);

    await svc().settleDefeat(config: config(), numbers: numbers());

    // ① 无命名装备发放。
    for (final defId in config().rewardCandidateEquipmentIds) {
      expect(
        await IsarSetup.instance.equipments
            .filter()
            .defIdEqualTo(defId)
            .count(),
        0,
        reason: '不发候选装备 $defId',
      );
    }
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    // ② 领悟点不变。
    expect(
      (await IsarSetup.instance.characters.get(1))!.insightPoints,
      insightBefore,
      reason: '失败不发领悟点',
    );
    // ③ 首通秘籍未解锁。
    expect(
      save.skillUnlockProgress.isUnlocked(config().firstClearRewardSkillId),
      isFalse,
      reason: '失败不解锁秘籍',
    );
    // ④ 不记通关（防重键不写·下次仍算首通）。
    expect(
      save.clearedGauntletIds,
      isNot(contains(GauntletService.gauntletId)),
    );
    expect(save.duanhunFirstClearedAt, isNull);
  });

  test('认输离庄（interlude）：结已胜精英经验 + 关会话', () async {
    await zeroExp(1);
    // interlude=通关第 2 关后停整备（currentStage 已推进到 3）→ 已胜 2 精英。
    await putRun(
      currentStage: 3,
      phase: GauntletPhase.interlude,
      members: [member()],
    );

    await svc().settleDefeat(config: config(), numbers: numbers());

    final expAfter = (await IsarSetup.instance.characters.get(1))!.experience;
    expect(expAfter, 2 * config().eliteRewardExp, reason: '认输保留已胜 2 精英经验');
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0, reason: '关会话');
  });

  test('首关战败（currentStage=1·0 精英）：不发精英经验', () async {
    await zeroExp(1);
    await putRun(
      currentStage: 1,
      members: [member(downed: true, currentHp: 0)],
    );

    await svc().settleDefeat(config: config(), numbers: numbers());

    final expAfter = (await IsarSetup.instance.characters.get(1))!.experience;
    expect(expAfter, 0, reason: '首关即败无已击败精英→无经验');
  });

  test('awaitingRewardChoice（Boss 已胜）→ 抛错（应走 chooseReward）', () async {
    await putRun(
      phase: GauntletPhase.awaitingRewardChoice,
      members: [member()],
    );
    await expectLater(
      svc().settleDefeat(config: config(), numbers: numbers()),
      throwsStateError,
    );
  });

  test('路线 C 历史多人已推进会话：发精英经验、返托管、无附伤并关会话', () async {
    await zeroExp(1);
    await putRun(
      members: [member(), member(id: 999, downed: true, currentHp: 0)],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [2],
      escrowUsed: [1],
    );
    await putInventory('item_liaoshangdan', 0);

    expect(
      await svc().retireLegacyMultiplayer(config: config(), numbers: numbers()),
      GauntletLegacyRetirement.settledProgress,
    );
    final ch = (await IsarSetup.instance.characters.get(1))!;
    expect(ch.experience, 2 * config().eliteRewardExp);
    expect(ch.lightInjuryStacks, 0);
    expect(ch.injuryHoursRemaining, 0);
    expect(await qtyOf('item_liaoshangdan'), 1);
    expect(await svc().activeRun(), isNull);
  });

  test('路线 C 历史多人已胜 Boss：保留 awaitingRewardChoice 供玩家选奖', () async {
    await putRun(
      phase: GauntletPhase.awaitingRewardChoice,
      members: [member(), member(id: 999)],
    );

    expect(
      await svc().retireLegacyMultiplayer(config: config(), numbers: numbers()),
      GauntletLegacyRetirement.preservedRewardChoice,
    );
    expect(
      (await svc().activeRun())?.sessionPhase,
      GauntletPhase.awaitingRewardChoice,
    );
  });

  test('幂等：无 active 会话 → no-op 不抛', () async {
    await svc().settleDefeat(config: config(), numbers: numbers());
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('战败结算有主线进度行：精英经验照发（cleared 集参与层锁判定）', () async {
    await zeroExp(1);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.mainlineProgress.put(
        MainlineProgress()
          ..saveDataId = IsarSetup.currentSlotId
          ..clearedStageIds = ['stage_01_01'],
      );
    });
    await putRun(members: [member()]);

    await svc().settleDefeat(config: config(), numbers: numbers());

    final expAfter = (await IsarSetup.instance.characters.get(1))!.experience;
    expect(expAfter, 2 * config().eliteRewardExp, reason: '两精英经验照发');
  });

  test('战败精英经验跨层：经层锁门禁判定后升层（发布上限内）', () async {
    // 经验调到当前层阈值-1：2 精英经验必触发一次跨层 → 走 isLayerLocked 判定。
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
    await putRun(members: [member()]);

    await svc().settleDefeat(config: config(), numbers: numbers());

    final after = (await IsarSetup.instance.characters.get(1))!;
    final next = CharacterAdvancementService.nextLayer(
      before.realmTier,
      before.realmLayer,
    )!;
    expect(after.realmTier, next.tier);
    expect(after.realmLayer, next.layer, reason: '发布上限内不被拦·升一层');
    expect(
      after.experience,
      2 * config().eliteRewardExp - 1,
      reason: 'threshold-1 + 2 精英经验 - threshold',
    );
  });
}
