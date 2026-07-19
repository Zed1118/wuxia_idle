import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `gauntlet_providers` 行为测（2026-07-19 夜批 coverage 补强，基线 57/99 行;
/// 既有 screen 测走 override 隔离 UI,本真 provider 路径未覆盖）。
///
/// 真 Isar + 真 GameRepository + 真 `GauntletService.enter` 生产入口建会话,钉:
///   - service/activeGauntlet/config 三读
///   - loadoutInfo:断魂帖计数 + 补给筛(gauntlet*Pct>0)按 defId 排序
///   - candidates:非祖师存活池 + 主修/占用标注
///   - interludeView:成员名查表 + 托管剩余 + 疗伤标
///   - rewardView:候选装备 def 解析成卡
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_prov_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.invalidate(isarProvider);
    return container;
  }

  Character makeChar({
    required String name,
    bool isFounder = false,
    bool isAlive = true,
    int? mainTechniqueId,
  }) {
    final realm = GameRepository.instance.getRealm(
      RealmTier.xueTu,
      RealmLayer.qiMeng,
    );
    return Character.create(
      name: name,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
      createdAt: DateTime(2026, 7, 19),
      internalForce: realm.internalForceMax,
      internalForceMax: realm.internalForceMax,
      experienceToNextLayer: realm.experienceToNext,
      isFounder: isFounder,
      isAlive: isAlive,
      mainTechniqueId: mainTechniqueId,
    );
  }

  Future<int> seedTechnique(int ownerId) async {
    final repo = GameRepository.instance;
    final tech = Technique.create(
      defId: 'tech_gangmeng_jichu',
      ownerCharacterId: ownerId,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 7, 19),
      cultivationProgressToNext:
          repo.numbers.cultivationProgressToNext[CultivationLayer.chuKui]!,
    );
    return IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.techniques.put(tech),
    );
  }

  Future<void> seedItem(String defId, int qty) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = defId
          ..itemType = ItemType.miscMaterial
          ..quantity = qty
          ..firstObtainedAt = DateTime(2026, 7, 19)
          ..lastObtainedAt = DateTime(2026, 7, 19),
      );
    });
  }

  /// 真生产入口 `GauntletService.enter` 建 active 会话(1 弟子 + 1 疗伤丹)。
  /// 返回 (runId, discipleId)。
  Future<(int, int)> enterRun() async {
    final isar = IsarSetup.instance;
    late int discipleId;
    await isar.writeTxn(() async {
      discipleId = await isar.characters.put(makeChar(name: '入场弟子'));
    });
    final techId = await seedTechnique(discipleId);
    await isar.writeTxn(() async {
      final c = (await isar.characters.get(discipleId))!
        ..mainTechniqueId = techId;
      await isar.characters.put(c);
    });
    await seedItem(GauntletService.ticketDefId, 1);
    await seedItem('item_liaoshangdan', 2);
    final runId =
        await GauntletService(
          isar,
          itemDefs: GameRepository.instance.itemDefs,
        ).enter(
          characterIds: [discipleId],
          supplies: const {'item_liaoshangdan': 2},
          supplyCap: GameRepository.instance.bossGauntletConfig!.supplyCap,
        );
    return (runId, discipleId);
  }

  test('service:activeGauntlet/config 三读', () async {
    // null 路径:setUp 已 init,先 close+reset 回「未 init」态再断言。
    await IsarSetup.close();
    IsarSetup.resetForTest();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(gauntletServiceProvider), isNull);
    expect(await container.read(activeGauntletProvider.future), isNull);

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    expect(container.read(gauntletServiceProvider), isNotNull);
    expect(
      await container.read(activeGauntletProvider.future),
      isNull,
      reason: '无会话 → null',
    );
    expect(
      container.read(gauntletConfigProvider),
      isNotNull,
      reason: 'GameRepository 已加载 → 配置直读',
    );

    final (runId, _) = await enterRun();
    container.invalidate(activeGauntletProvider);
    final active = await container.read(activeGauntletProvider.future);
    expect(active!.id, runId, reason: 'enter 后 active 会话可读');
  });

  test('loadoutInfo:断魂帖计数 + 补给按 defId 排序与持有数', () async {
    // null 路径:先 close+reset 回「未 init」态。
    await IsarSetup.close();
    IsarSetup.resetForTest();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final empty = await container.read(gauntletLoadoutInfoProvider.future);
    expect(empty.ticketCount, 0);
    expect(empty.supplies, isEmpty, reason: 'Isar 未 init → 兜底空');

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    await seedItem(GauntletService.ticketDefId, 3);
    await seedItem('item_liaoshangdan', 5);
    container.invalidate(gauntletLoadoutInfoProvider);

    final info = await container.read(gauntletLoadoutInfoProvider.future);
    expect(info.ticketCount, 3);
    expect(info.supplies, isNotEmpty, reason: 'yaml 含 gauntlet*Pct>0 补给 def');
    final sorted = info.supplies.map((s) => s.defId).toList()..sort();
    expect(
      info.supplies.map((s) => s.defId).toList(),
      sorted,
      reason: '按 defId 稳定排序',
    );
    final pill = info.supplies.firstWhere(
      (s) => s.defId == 'item_liaoshangdan',
    );
    expect(pill.owned, 5, reason: '持有数取普通库存');
    expect(pill.name, isNotEmpty);
  });

  test('candidates:非祖师存活池 + 主修/阵亡标注', () async {
    final isar = IsarSetup.instance;
    late int withTechId, noTechId;
    await isar.writeTxn(() async {
      await isar.characters.put(makeChar(name: '祖师', isFounder: true));
      withTechId = await isar.characters.put(makeChar(name: '有主修'));
      noTechId = await isar.characters.put(makeChar(name: '无主修'));
      await isar.characters.put(makeChar(name: '亡者', isAlive: false));
    });
    final techId = await seedTechnique(withTechId);
    await isar.writeTxn(() async {
      final c = (await isar.characters.get(withTechId))!
        ..mainTechniqueId = techId;
      await isar.characters.put(c);
    });
    final container = makeContainer();

    final candidates = await container.read(gauntletCandidatesProvider.future);

    final ids = candidates.map((c) => c.character.id).toSet();
    expect(
      ids.containsAll([withTechId, noTechId]),
      isTrue,
      reason: '非祖师存活弟子都入池',
    );
    expect(
      candidates.any((c) => c.character.isFounder),
      isFalse,
      reason: '祖师坐镇不入场',
    );
    expect(
      candidates.any((c) => !c.character.isAlive),
      isFalse,
      reason: '亡者排除',
    );
    final withTech = candidates.firstWhere((c) => c.character.id == withTechId);
    expect(withTech.hasMainTechnique, isTrue);
    expect(withTech.occupied, isFalse);
    expect(withTech.selectable, isTrue);
    final noTech = candidates.firstWhere((c) => c.character.id == noTechId);
    expect(noTech.hasMainTechnique, isFalse);
    expect(noTech.selectable, isFalse, reason: '未修主修 UI 标灰');
  });

  test('interludeView:成员名查表 + 托管剩余 + 疗伤标;非 interlude → null', () async {
    final (runId, discipleId) = await enterRun();
    final container = makeContainer();
    expect(
      await container.read(gauntletInterludeViewProvider.future),
      isNull,
      reason: 'enter 初态 inBattle → 非 interlude 返 null',
    );

    await IsarSetup.instance.writeTxn(() async {
      final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!
        ..sessionPhase = GauntletPhase.interlude;
      await IsarSetup.instance.bossGauntletRuns.put(run);
    });
    container.invalidate(gauntletInterludeViewProvider);

    final view = await container.read(gauntletInterludeViewProvider.future);
    expect(view, isNotNull);
    expect(view!.stage, 1);
    expect(view.members.single.characterId, discipleId);
    expect(view.members.single.name, '入场弟子', reason: '角色名经 Character 查表');
    expect(view.supplies.single.defId, 'item_liaoshangdan');
    expect(view.supplies.single.remaining, 2, reason: '装入 2 - 已用 0');
    expect(
      view.supplies.single.isHeal,
      isTrue,
      reason: '疗伤丹 gauntletHpHealPct>0 → 须择目标',
    );
  });

  test('rewardView:候选装备 def 解析成卡;非待选相位 → null', () async {
    final (runId, _) = await enterRun();
    final container = makeContainer();
    expect(
      await container.read(gauntletRewardViewProvider.future),
      isNull,
      reason: 'inBattle 相位 → null',
    );

    final defIds = GameRepository.instance.equipmentDefs.keys.take(2).toList();
    await IsarSetup.instance.writeTxn(() async {
      final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!
        ..sessionPhase = GauntletPhase.awaitingRewardChoice
        ..rewardCandidateDefIds = defIds
        ..isFirstClearPending = true;
      await IsarSetup.instance.bossGauntletRuns.put(run);
    });
    container.invalidate(gauntletRewardViewProvider);

    final view = await container.read(gauntletRewardViewProvider.future);
    expect(view, isNotNull);
    expect(view!.isFirstClear, isTrue);
    expect(view.candidates, hasLength(2));
    final first = view.candidates.first;
    final def = GameRepository.instance.equipmentDefs[first.defId]!;
    expect(first.name, def.name);
    expect(first.tier, def.tier);
    expect(first.attackMin, def.baseAttackMin, reason: '属性区间经 def 查表');
  });
}
