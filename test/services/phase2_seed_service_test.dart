import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/models/character.dart';
import 'package:wuxia_idle/data/models/encounter_progress.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/data/models/inventory_item.dart';
import 'package:wuxia_idle/data/models/mainline_progress.dart';
import 'package:wuxia_idle/data/models/save_data.dart';
import 'package:wuxia_idle/data/models/technique.dart';
import 'package:wuxia_idle/services/phase2_seed_service.dart';
import 'package:wuxia_idle/services/stage_battle_setup.dart';

/// T32 子提交 3a：[Phase2SeedService] 真 Isar 落地测试。
///
/// 沿用 [enhancement_persist_test] 的 setUp 套路：临时目录 + IsarSetup.init +
/// GameRepository.loadAllDefs（rootBundle 不可用 → 走文件系统）。
///
/// 5 用例覆盖：
///   - seedP1 → 完整 fixture 字段断言
///   - seedP2 → battleCount=99
///   - seedP3 → 散功前 fixture（IF 10000 + yuanMan/1500 主修 + daCheng 辅修）
///   - seedP4 → 双装备（主 battleCount=2000 / 对照 battleCount=0）
///   - clear 语义：预先脏数据 → seedP1 → 仅余 fixture
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_seed_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<int> readQty(ItemType type) async {
    final row = await IsarSetup.instance.inventoryItems
        .filter()
        .itemTypeEqualTo(type)
        .findFirst();
    return row?.quantity ?? 0;
  }

  test('seedP1 → 1 角色 + 1 件 +0 利器装备 + 1000 磨剑石 / 100 心血结晶', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP1();

    final isar = IsarSetup.instance;
    expect(await isar.characters.count(), 1);
    expect(await isar.equipments.count(), 1);
    expect(await isar.techniques.count(), 0);
    expect(await isar.inventoryItems.count(), 2);

    final ch = await isar.characters.get(1);
    expect(ch, isNotNull);
    expect(ch!.realmTier, RealmTier.erLiu);
    expect(ch.realmLayer, RealmLayer.yuanShu);
    expect(ch.equippedWeaponId, isNotNull);

    final eq = await isar.equipments.get(ch.equippedWeaponId!);
    expect(eq, isNotNull);
    expect(eq!.defId, 'weapon_liqi_long_quan');
    expect(eq.tier, EquipmentTier.liQi);
    expect(eq.slot, EquipmentSlot.weapon);
    expect(eq.enhanceLevel, 0);
    expect(eq.battleCount, 0);
    expect(eq.ownerCharacterId, 1);

    expect(await readQty(ItemType.moJianShi), 1000);
    expect(await readQty(ItemType.xinXueJieJing), 100);
  });

  test('seedP2 → battleCount=99 装备 + 充足材料', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP2();

    final isar = IsarSetup.instance;
    expect(await isar.equipments.count(), 1);
    final eqs = await isar.equipments.where().findAll();
    expect(eqs.single.battleCount, 99);
    expect(eqs.single.enhanceLevel, 0);
    expect(eqs.single.ownerCharacterId, 1);

    expect(await readQty(ItemType.moJianShi), 2000);
    expect(await readQty(ItemType.xinXueJieJing), 200);
  });

  test('seedP3 → IF 10000 + yuanMan/1500 主修 + daCheng 辅修', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();

    final isar = IsarSetup.instance;
    expect(await isar.characters.count(), 1);
    expect(await isar.equipments.count(), 0);
    expect(await isar.techniques.count(), 2);

    final ch = await isar.characters.get(1);
    expect(ch, isNotNull);
    expect(ch!.internalForce, 10000);
    expect(ch.internalForceMax, 10000);
    expect(ch.school, TechniqueSchool.gangMeng);
    expect(ch.mainTechniqueId, isNotNull);
    expect(ch.assistTechniqueIds.length, 1);

    final main = await isar.techniques.get(ch.mainTechniqueId!);
    expect(main, isNotNull);
    expect(main!.role, TechniqueRole.main);
    expect(main.defId, 'tech_gangmeng_mingjia');
    expect(main.cultivationLayer, CultivationLayer.yuanMan);
    expect(main.cultivationProgress, 1500);
    expect(main.cultivationProgressToNext, 1500); // yuanMan → dianFeng 阈值
    expect(main.ownerCharacterId, 1);

    final assist = await isar.techniques.get(ch.assistTechniqueIds.single);
    expect(assist, isNotNull);
    expect(assist!.role, TechniqueRole.assist);
    expect(assist.defId, 'tech_yinrou_mingjia');
    expect(assist.cultivationLayer, CultivationLayer.daCheng);
    expect(assist.cultivationProgressToNext, 900); // daCheng → yuanMan 阈值
    expect(assist.ownerCharacterId, 1);
  });

  test('seedP4 → 2 件 +0 利器（主 battleCount=2000 已装 / 对照 battleCount=0 未装）',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP4();

    final isar = IsarSetup.instance;
    expect(await isar.characters.count(), 1);
    expect(await isar.equipments.count(), 2);

    final ch = await isar.characters.get(1);
    expect(ch, isNotNull);
    expect(ch!.equippedWeaponId, isNotNull);

    final eqMain = await isar.equipments.get(ch.equippedWeaponId!);
    expect(eqMain, isNotNull);
    expect(eqMain!.battleCount, 2000);
    expect(eqMain.enhanceLevel, 0);
    expect(eqMain.ownerCharacterId, 1);

    final all = await isar.equipments.where().findAll();
    final eqRef = all.firstWhere((e) => e.id != eqMain.id);
    expect(eqRef.battleCount, 0);
    expect(eqRef.enhanceLevel, 0);
    expect(eqRef.ownerCharacterId, isNull, reason: '对照装备未装备，留在背包');

    expect(await readQty(ItemType.moJianShi), 2000);
    expect(await readQty(ItemType.xinXueJieJing), 200);
  });

  test('clear 语义：seedP1 会清掉前一次 seedP3 的全部数据，只留新 fixture', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final isar = IsarSetup.instance;
    expect(await isar.techniques.count(), 2);

    await Phase2SeedService(isar: IsarSetup.instance).seedP1();

    expect(await isar.characters.count(), 1);
    expect(await isar.equipments.count(), 1);
    expect(await isar.techniques.count(), 0, reason: 'P3 的 2 本心法应被清空');

    final ch = await isar.characters.get(1);
    expect(ch?.mainTechniqueId, isNull);
    expect(ch?.assistTechniqueIds, isEmpty);

    final eq = await isar.equipments.where().findFirst();
    expect(eq?.defId, 'weapon_liqi_long_quan');
    expect(eq?.battleCount, 0);
  });

  // ── Phase 3 Week 4 T54 · seedMasterDisciple ────────────────────────────────

  test('seedMasterDisciple → 3 师徒 + 师徒关系双向 + 祖师 id=1 + 默认入阵',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final isar = IsarSetup.instance;

    expect(await isar.characters.count(), 3);

    final founder = await isar.characters.get(1);
    expect(founder, isNotNull);
    expect(founder!.lineageRole, LineageRole.founder);
    expect(founder.isFounder, isTrue);
    expect(founder.realmTier, RealmTier.yiLiu);
    expect(founder.discipleIds.length, 2);
    expect(founder.name, '祖师');

    final firstDisciple = await isar.characters.get(founder.discipleIds[0]);
    expect(firstDisciple!.lineageRole, LineageRole.disciple);
    expect(firstDisciple.realmTier, RealmTier.erLiu);
    expect(firstDisciple.masterId, 1);
    expect(firstDisciple.name, '大弟子');

    final secondDisciple = await isar.characters.get(founder.discipleIds[1]);
    expect(secondDisciple!.lineageRole, LineageRole.disciple);
    expect(secondDisciple.realmTier, RealmTier.sanLiu);
    expect(secondDisciple.masterId, 1);
    expect(secondDisciple.name, '二弟子');

    final save = await isar.saveDatas.get(0);
    expect(save!.activeCharacterIds, [
      founder.id,
      firstDisciple.id,
      secondDisciple.id,
    ]);
    expect(save.founderCharacterId, 1);
  });

  test('seedMasterDisciple → 3 师徒各自有主修 + 装备齐 weapon/armor/accessory',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final isar = IsarSetup.instance;

    for (final id in [1, 2, 3]) {
      final ch = await isar.characters.get(id);
      expect(ch!.mainTechniqueId, isNotNull, reason: '$id 必须有主修');
      if (id == 1) {
        expect(ch.assistTechniqueIds.length, 1);
      } else {
        expect(ch.assistTechniqueIds, isEmpty);
      }
      expect(ch.equippedWeaponId, isNotNull);
      expect(ch.equippedArmorId, isNotNull);
      expect(ch.equippedAccessoryId, isNotNull);
    }

    expect(await isar.equipments.count(), 9);
    expect(await isar.techniques.count(), 4);
  });

  test('seedMasterDisciple → 主修流派透传到 character.school', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final isar = IsarSetup.instance;

    final founder = await isar.characters.get(1);
    expect(founder!.school, TechniqueSchool.gangMeng);

    final firstDisciple = await isar.characters.get(2);
    expect(firstDisciple!.school, TechniqueSchool.lingQiao);

    final secondDisciple = await isar.characters.get(3);
    expect(secondDisciple!.school, TechniqueSchool.yinRou);
  });

  test('seedMasterDisciple 反复调用 reseed 一致（_clearAll 保证干净）',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final isar = IsarSetup.instance;

    expect(await isar.characters.count(), 3);
    expect(await isar.equipments.count(), 9);
    expect(await isar.techniques.count(), 4);
    final founder = await isar.characters.get(1);
    expect(founder!.discipleIds.length, 2);
  });

  test('销账 #25：seedMasterDisciple 后 stage_01_01 buildTeams 不再 fail-fast',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final stage = GameRepository.instance.getStage('stage_01_01');

    // 不抛"未修主修"——3 师徒都有 mainTechniqueId
    final (left, right) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(stage);
    expect(left.length, 3, reason: '玩家左队 3 师徒入阵');
    expect(right, isNotEmpty, reason: 'stage_01_01 enemyTeam 非空');
  });

  test('seedMasterDisciple 后 P1 → 业务表清空但 SaveData.activeCharacterIds 不动',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple();
    final isar = IsarSetup.instance;
    final saveBefore = await isar.saveDatas.get(0);
    expect(saveBefore!.activeCharacterIds.length, 3);

    await Phase2SeedService(isar: IsarSetup.instance).seedP1();
    expect(await isar.characters.count(), 1);

    final saveAfter = await isar.saveDatas.get(0);
    // P1 不动 SaveData（既有体例）→ activeCharacterIds 残留指向已被 _clearAll
    // 清掉的 id=2/3。这是已知的 P1 fixture 缺陷（挂账 #25），seedMasterDisciple
    // 自己不破坏既有体例。
    expect(saveAfter!.activeCharacterIds, [1, 2, 3]);
    expect(await isar.characters.get(2), isNull);
    expect(await isar.characters.get(3), isNull);
  });

  // ── W12 fix · seedVisualCheckW7W11 ──────────────────────────────────────────

  test('seedVisualCheckW7W11 → 师徒齐 + Ch1 01-04 标 cleared + stage_01_05 可挑战',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW7W11();
    final isar = IsarSetup.instance;

    // 1. 师徒种子保留（沿用 seedMasterDisciple 行为）
    expect(await isar.characters.count(), 3);
    final save = await isar.saveDatas.get(0);
    expect(save!.activeCharacterIds, [1, 2, 3]);

    // 2. MainlineProgress 含 4 个 stage_01_xx
    final progress = await isar.mainlineProgress.where().findFirst();
    expect(progress, isNotNull);
    expect(progress!.clearedStageIds, [
      'stage_01_01',
      'stage_01_02',
      'stage_01_03',
      'stage_01_04',
    ]);
    expect(progress.clearedAt.length, 4);
  });

  test('seedVisualCheckW7W11 反复调用 → MainlineProgress 幂等不重复 append',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW7W11();
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW7W11();
    final isar = IsarSetup.instance;
    final progress = await isar.mainlineProgress.where().findFirst();
    expect(progress!.clearedStageIds.length, 4,
        reason: 'recordVictory 幂等：重复种子不重复 append');
  });

  // ── W14-3 fix · seedVisualCheckW14_3 ────────────────────────────────────────

  test('seedVisualCheckW14_3 → EncounterProgress.unlockedSkillIds 覆盖 tier 1-7',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW14_3();
    final isar = IsarSetup.instance;

    final progress = await isar.encounterProgress.where().findFirst();
    expect(progress, isNotNull, reason: '应通过 EncounterService.getOrCreate 创建');
    expect(progress!.unlockedSkillIds.length, 7,
        reason: 'tier 1-7 各取 1 个 encounter skill');

    // 各 unlocked id 都能在 repo 中找到 + 对应 tier 唯一覆盖 1-7
    final repo = GameRepository.instance;
    final unlockedTiers = <int>{};
    for (final id in progress.unlockedSkillIds) {
      final skill = repo.getSkill(id);
      expect(skill.isEncounterSkill, isTrue,
          reason: '$id 应是 encounter skill');
      unlockedTiers.add(skill.tier!);
    }
    expect(unlockedTiers, {1, 2, 3, 4, 5, 6, 7});
  });

  test('seedVisualCheckW14_3 → 大弟子 (id=2) 预装备 tier 3 encounter skill',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW14_3();
    final isar = IsarSetup.instance;

    final disciple = await isar.characters.get(2);
    expect(disciple, isNotNull);
    expect(disciple!.equippedEncounterSkillId, isNotNull,
        reason: '大弟子 slot 应填充 1 个 encounter skill');

    final equipped = GameRepository.instance.getSkill(
      disciple.equippedEncounterSkillId!,
    );
    expect(equipped.isEncounterSkill, isTrue);
    expect(equipped.tier, 3,
        reason: '大弟子 erLiu (RealmTier.index=2) 装 tier 3 通过锁死校验');
  });

  test('seedVisualCheckW14_3 反复调用 → unlock 池仍 7（覆盖而非 append）',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW14_3();
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW14_3();
    final isar = IsarSetup.instance;

    final progress = await isar.encounterProgress.where().findFirst();
    expect(progress!.unlockedSkillIds.length, 7,
        reason: '反复调用 → unlockedSkillIds 覆盖,不重复 append');
    final disciple = await isar.characters.get(2);
    expect(disciple!.equippedEncounterSkillId, isNotNull);
  });
}
