import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/cultivation/application/skill_loadout_service.dart';

/// SkillLoadoutService 装配 gate + autoFill 落库测试（P1b Task3）。
///
/// - 用真 Isar 实例（IsarSetup.init + tempDir）。
/// - equipSkill 测：加载真 yaml（GameRepository.loadAllDefs），用奇遇招（有 tier）测 gate。
///   tier-5 奇遇招需 realmTier.index >= 4（jueDing），xueTu（index=0）装不进 → TierLocked。
/// - applyAutoFill 测：直接构造 SkillDef 注入，不依赖 GameRepository skillDefs。
/// - unequipSlot 测：不依赖 GameRepository。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (p) => File(p).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_skill_loadout_svc_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// 创建测试用 Character，返回已入库的 id。
  Future<int> seedCharacter({
    RealmTier realmTier = RealmTier.xueTu,
    String? mainSkillId1,
    String? mainSkillId2,
    String? assistSkillId,
    String? resonanceSkillId,
    String? ultimateSkillId,
  }) async {
    final isar = IsarSetup.instance;
    late int charId;
    await isar.writeTxn(() async {
      final c = Character.create(
        name: '测试弟子',
        realmTier: realmTier,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes()
          ..constitution = 5
          ..enlightenment = 5
          ..agility = 5
          ..fortune = 5,
        rarity: RarityTier.xunChang,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026, 1, 1),
        mainSkillId1: mainSkillId1,
        mainSkillId2: mainSkillId2,
        assistSkillId: assistSkillId,
        resonanceSkillId: resonanceSkillId,
        ultimateSkillId: ultimateSkillId,
      );
      charId = await isar.characters.put(c);
    });
    return charId;
  }

  /// 构造最简 SkillDef（心法招，tier=null → canEquipAtRealm 恒 true）。
  SkillDef makeSkillDef({
    required String id,
    int powerMultiplier = 1000,
    int? tier,
  }) =>
      SkillDef(
        id: id,
        name: id,
        description: '',
        type: SkillType.powerSkill,
        powerMultiplier: powerMultiplier,
        internalForceCost: 50,
        cooldownTurns: 2,
        requiresManualTrigger: false,
        visualEffect: 'none',
        tier: tier,
      );

  // ─────────────────────────────────────────────────────────────────────────────
  // 测试 1: equipSkill 低境界装高 tier 招 → SlotEquipTierLocked，槽不变
  // ─────────────────────────────────────────────────────────────────────────────
  test('equipSkill 低境界装 tier-5 奇遇招 → SlotEquipTierLocked 且槽不变', () async {
    // tier-5 招需 realmTier.index >= 4（jueDing），xueTu.index=0 → 装不进
    const tierHighSkillId = 'skill_encounter_water_qi'; // encounter_skills.yaml tier=5

    final charId = await seedCharacter(realmTier: RealmTier.xueTu);
    final svc = SkillLoadoutService(IsarSetup.instance);

    final result = await svc.equipSkill(
      characterId: charId,
      slot: SkillSlot.main1,
      skillId: tierHighSkillId,
    );

    expect(result, isA<SlotEquipTierLocked>());

    // 槽应当保持 null（未写入）
    final c = await IsarSetup.instance.characters.get(charId);
    expect(c?.mainSkillId1, isNull);
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 测试 2: equipSkill 境界达标 → 槽写入 skillId
  // ─────────────────────────────────────────────────────────────────────────────
  test('equipSkill 境界达标（tier-1 招 + xueTu）→ 槽写入 skillId', () async {
    // tier-1 招需 realmTier.index >= 0，xueTu.index=0 → 恰好通过
    const tier1SkillId = 'skill_encounter_jichu_buxi'; // encounter_skills.yaml tier=1

    final charId = await seedCharacter(realmTier: RealmTier.xueTu);
    final svc = SkillLoadoutService(IsarSetup.instance);

    final result = await svc.equipSkill(
      characterId: charId,
      slot: SkillSlot.main1,
      skillId: tier1SkillId,
    );

    expect(result, isA<SlotEquipSucceeded>());

    final c = await IsarSetup.instance.characters.get(charId);
    expect(c?.mainSkillId1, tier1SkillId);
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 测试 3: applyAutoFill → 角色 5 槽按 autoFill 结果落库
  // ─────────────────────────────────────────────────────────────────────────────
  test('applyAutoFill → 角色 5 槽按 autoFill 结果落库', () async {
    // 直接构造 SkillDef，不依赖 GameRepository.skillDefs
    // ultimatePowerThreshold=1400，power>=1400 → 大招槽，power<1400 → 主修槽
    final main1 = makeSkillDef(id: 'test_main_a', powerMultiplier: 1200); // < 1400
    final main2 = makeSkillDef(id: 'test_main_b', powerMultiplier: 1100); // < 1400
    final ult = makeSkillDef(id: 'test_ult', powerMultiplier: 1500);      // >= 1400
    final assist = makeSkillDef(id: 'test_assist', powerMultiplier: 900);
    final joint = makeSkillDef(id: 'test_joint', powerMultiplier: 800);

    final charId = await seedCharacter(realmTier: RealmTier.xueTu);
    final svc = SkillLoadoutService(IsarSetup.instance);

    await svc.applyAutoFill(
      characterId: charId,
      mainTechniqueSkills: [main1, main2, ult],
      assistTechniqueSkills: [assist],
      jointSkill: joint,
      ultimatePowerThreshold: 1400,
    );

    final c = await IsarSetup.instance.characters.get(charId);
    // 主修 2 槽：power 降序，main1(1200) > main2(1100)
    expect(c?.mainSkillId1, 'test_main_a');
    expect(c?.mainSkillId2, 'test_main_b');
    // 辅修槽
    expect(c?.assistSkillId, 'test_assist');
    // 共鸣槽
    expect(c?.resonanceSkillId, 'test_joint');
    // 大招槽
    expect(c?.ultimateSkillId, 'test_ult');
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 测试 4: unequipSlot → 槽置 null
  // ─────────────────────────────────────────────────────────────────────────────
  test('unequipSlot → 槽置 null', () async {
    final charId = await seedCharacter(
      realmTier: RealmTier.xueTu,
      mainSkillId1: 'some_skill_id',
      assistSkillId: 'another_skill',
    );
    final svc = SkillLoadoutService(IsarSetup.instance);

    await svc.unequipSlot(characterId: charId, slot: SkillSlot.main1);

    final c = await IsarSetup.instance.characters.get(charId);
    expect(c?.mainSkillId1, isNull);
    // 其他槽未受影响
    expect(c?.assistSkillId, 'another_skill');
  });
}
