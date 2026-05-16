import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_progress.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';

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

  // ── W15-r2 · seedVisualCheckW15R2 ────────────────────────────────────────────

  test(
      'seedVisualCheckW15R2 → 6 件 tier 5-7 装备入背包 + 不入 equippedXxxId 槽位',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW15R2();
    final isar = IsarSetup.instance;

    final allEqs = await isar.equipments.where().findAll();
    // base seedMasterDisciple 9 件起手 + W15-r2 6 件 = 15 件
    expect(allEqs.length, 15, reason: 'P5 9 件起手 + r2 6 件 = 15');

    final r2 = allEqs
        .where((e) => e.obtainedFrom == 'visual_check_w15_r2')
        .toList();
    expect(r2.length, 6, reason: 'r2 obtainedFrom 标记 6 件');

    // tier 5-7 各 2 件覆盖 weapon/armor/accessory
    final tiers = r2.map((e) => e.tier).toSet();
    expect(
      tiers,
      containsAll({EquipmentTier.zhongQi, EquipmentTier.baoWu, EquipmentTier.shenWu}),
      reason: 'r2 必含 tier 5/6/7 各装备',
    );

    // 6 件全 ownerCharacterId=1(祖师持有,但不入 equippedXxxId)
    expect(r2.every((e) => e.ownerCharacterId == 1), isTrue);
    final founder = await isar.characters.get(1);
    final r2Ids = r2.map((e) => e.id).toSet();
    expect(r2Ids.contains(founder!.equippedWeaponId), isFalse,
        reason: '境界一流锁死,tier 5-7 不可装备(GDD §5.3)');
    expect(r2Ids.contains(founder.equippedArmorId), isFalse);
    expect(r2Ids.contains(founder.equippedAccessoryId), isFalse);
  });

  test('seedVisualCheckW15R2 含 VC 基础(Ch1 01-04 cleared + 3 师徒)', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW15R2();
    final isar = IsarSetup.instance;

    // 3 师徒(沿用 seedVisualCheckW7W11 → seedMasterDisciple)
    final chars = await isar.characters.where().findAll();
    expect(chars.length, 3);

    // Ch1 01-04 cleared(沿用 seedVisualCheckW7W11)
    final progress = await isar.mainlineProgress.where().findFirst();
    expect(progress!.clearedStageIds,
        containsAll({'stage_01_01', 'stage_01_02', 'stage_01_03', 'stage_01_04'}));
  });

  // ── W15 共鸣/强化/开锋 · seedVisualCheckW15Resonance ────────────────────────

  test(
      'seedVisualCheckW15Resonance → 6 件武器入背包,'
      'battleCount / enhanceLevel / forgingSlots 按 spec 落',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance)
        .seedVisualCheckW15Resonance();
    final isar = IsarSetup.instance;

    final allEqs = await isar.equipments.where().findAll();
    // base seedMasterDisciple 9 件起手 + 共鸣 fixture 6 件 = 15 件
    expect(allEqs.length, 15, reason: 'P5 9 件起手 + 共鸣 fixture 6 件 = 15');

    final res = allEqs
        .where((e) => e.obtainedFrom == 'visual_check_w15_resonance')
        .toList();
    expect(res.length, 6, reason: '共鸣 fixture obtainedFrom 标记 6 件');

    // 6 件 ownerCharacterId=1(祖师持有,但不入 equippedXxxId)
    expect(res.every((e) => e.ownerCharacterId == 1), isTrue);
    final founder = await isar.characters.get(1);
    final resIds = res.map((e) => e.id).toSet();
    expect(resIds.contains(founder!.equippedWeaponId), isFalse,
        reason: '武器槽位走 seedMasterDisciple 默认,fixture 6 件不抢槽');

    // 按 defId 索引断言每件 battleCount / enhanceLevel / 已开锋槽数
    final byDefId = {for (final e in res) e.defId: e};
    final expectations = <String, ({int bc, int el, int slots})>{
      'weapon_xunchang_tie_jian': (bc: 0, el: 0, slots: 0),
      'weapon_xiangyang_chang_jian': (bc: 200, el: 5, slots: 0),
      'weapon_haojiahuo_xuan_hua_fu': (bc: 800, el: 10, slots: 1),
      'weapon_liqi_pan_long_dao': (bc: 2500, el: 15, slots: 2),
      'weapon_zhongqi_qing_xu_jian': (bc: 1500, el: 19, slots: 3),
      'weapon_shenwu_tian_wen_jian': (bc: 5000, el: 0, slots: 0),
    };
    for (final entry in expectations.entries) {
      final eq = byDefId[entry.key];
      expect(eq, isNotNull, reason: '${entry.key} 必入背包');
      expect(eq!.battleCount, entry.value.bc,
          reason: '${entry.key} battleCount 应为 ${entry.value.bc}');
      expect(eq.enhanceLevel, entry.value.el,
          reason: '${entry.key} enhanceLevel 应为 ${entry.value.el}');
      final unlockedSlots =
          eq.forgingSlots.where((s) => s.unlocked).length;
      expect(unlockedSlots, entry.value.slots,
          reason: '${entry.key} 已开锋槽数应为 ${entry.value.slots}');
    }
  });

  test('seedVisualCheckW15Resonance → 共鸣度 4 阶段全覆盖', () async {
    await Phase2SeedService(isar: IsarSetup.instance)
        .seedVisualCheckW15Resonance();
    final isar = IsarSetup.instance;

    final res = await isar.equipments
        .filter()
        .obtainedFromEqualTo('visual_check_w15_resonance')
        .findAll();

    final stages = res
        .map((e) => e.resonanceStage(GameRepository.instance.numbers))
        .toSet();
    expect(
      stages,
      containsAll(<ResonanceStage>{
        ResonanceStage.shengShu,
        ResonanceStage.chenShou,
        ResonanceStage.moQi,
        ResonanceStage.xinJianTongLing,
      }),
      reason: '共鸣 4 阶段必全覆盖(生疏/趁手/默契/心剑通灵)',
    );
  });

  test('seedVisualCheckW15Resonance → 师承遗物强制标(weapon_liqi_pan_long_dao)',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance)
        .seedVisualCheckW15Resonance();
    final isar = IsarSetup.instance;

    // 注意:P5 师徒祖师 starting_equipment 含 weapon_liqi_long_quan
    // (def 自带 isLineageHeritage=true),所以全 collection 至少 2 件师承遗物。
    // 本 fixture 用强制标(forceLineageHeritage=true)在 weapon_liqi_pan_long_dao
    // 上,filter by obtainedFrom 锁定 fixture 那一件。
    final heritages = await isar.equipments
        .filter()
        .obtainedFromEqualTo('visual_check_w15_resonance')
        .isLineageHeritageEqualTo(true)
        .findAll();
    expect(heritages.length, 1,
        reason: 'fixture 强制标 1 件师承遗物 weapon_liqi_pan_long_dao');
    expect(heritages.first.defId, 'weapon_liqi_pan_long_dao');
  });

  test('seedVisualCheckW15Resonance → forgingSlots type 配置自洽',
      () async {
    await Phase2SeedService(isar: IsarSetup.instance)
        .seedVisualCheckW15Resonance();
    final isar = IsarSetup.instance;

    final res = await isar.equipments
        .filter()
        .obtainedFromEqualTo('visual_check_w15_resonance')
        .findAll();
    final byDefId = {for (final e in res) e.defId: e};

    // 全开锋装备(slots=3):weapon_zhongqi_qing_xu_jian
    final fullForged = byDefId['weapon_zhongqi_qing_xu_jian'];
    expect(fullForged, isNotNull);
    expect(fullForged!.forgingSlots[0].unlocked, isTrue);
    expect(fullForged.forgingSlots[0].type, ForgingSlotType.attack);
    expect(fullForged.forgingSlots[1].unlocked, isTrue);
    expect(fullForged.forgingSlots[1].type, ForgingSlotType.speed);
    expect(fullForged.forgingSlots[2].unlocked, isTrue);
    expect(fullForged.forgingSlots[2].type, ForgingSlotType.specialSkill);

    // 1 槽开锋装备(slots=1):weapon_haojiahuo_xuan_hua_fu
    final oneForged = byDefId['weapon_haojiahuo_xuan_hua_fu'];
    expect(oneForged, isNotNull);
    expect(oneForged!.forgingSlots[0].unlocked, isTrue);
    expect(oneForged.forgingSlots[0].type, ForgingSlotType.attack);
    expect(oneForged.forgingSlots[1].unlocked, isFalse);
    expect(oneForged.forgingSlots[2].unlocked, isFalse);
  });
}
