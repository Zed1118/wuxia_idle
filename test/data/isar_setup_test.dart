import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_usage_entry.dart';
import 'package:wuxia_idle/core/domain/technique.dart';

/// IsarSetup + 三个核心 Collection 的 round-trip 集成测试
/// （覆盖 T04 验收剩余 2 条 + T05 验收 SaveData 默认值/再打开读出）。
///
/// 用 `Isar.initializeIsarCore(download: true)` 在 dart test 环境下载
/// native lib（首次较慢，缓存在 `~/.dart_tool/isar/` 之后即时）。
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  group('IsarSetup', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_isar_test_');
    });

    tearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('首次 init 应自动建 SaveData(id=0) 并填默认值', () async {
      await IsarSetup.init(directory: tempDir, inspector: false);

      final save = await IsarSetup.instance.saveDatas.get(0);
      expect(save, isNotNull);
      expect(save!.id, 0);
      expect(save.slotId, 1);
      expect(save.saveVersion, '0.14.0',
          reason:
              'P4.1 1.1 Q6B SaveData 加 triggeredBossRecruitStageIds(Boss 招降防刷)');
      expect(save.activeCharacterIds, isEmpty);
      expect(save.totalPlaySeconds, 0);
      expect(save.isOnboardingCompleted, isFalse);
      expect(save.tutorialStep, 0);
      expect(save.tutorialHintsRead, isEmpty);
      expect(save.highestTowerLayer, 0);
      // 三个时间字段应是非常接近 now 的同一时刻
      final now = DateTime.now();
      expect(save.createdAt.difference(now).inSeconds.abs(), lessThan(5));
      expect(save.lastSavedAt, save.createdAt);
      expect(save.lastOnlineAt, save.createdAt);
    });

    test('已有 SaveData 时再次 init 应读出原值，不覆盖', () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      final originalCreatedAt =
          (await IsarSetup.instance.saveDatas.get(0))!.createdAt;
      await IsarSetup.instance.writeTxn(() async {
        final s = await IsarSetup.instance.saveDatas.get(0);
        s!
          ..sectName = '青锋门'
          ..highestTowerLayer = 7;
        await IsarSetup.instance.saveDatas.put(s);
      });
      await IsarSetup.close();

      await IsarSetup.init(directory: tempDir, inspector: false);
      final reopened = await IsarSetup.instance.saveDatas.get(0);
      expect(reopened!.createdAt, originalCreatedAt);
      expect(reopened.sectName, '青锋门');
      expect(reopened.highestTowerLayer, 7);
    });

    test('P1.y tutorialHintsRead 写入 [6,7] → close → reopen 读出 [6,7]', () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      await IsarSetup.instance.writeTxn(() async {
        final s = await IsarSetup.instance.saveDatas.get(0);
        s!.tutorialHintsRead = [6, 7];
        await IsarSetup.instance.saveDatas.put(s);
      });
      await IsarSetup.close();

      await IsarSetup.init(directory: tempDir, inspector: false);
      final reopened = await IsarSetup.instance.saveDatas.get(0);
      expect(reopened!.tutorialHintsRead, [6, 7]);
    });

    test('Character / Equipment / Technique 写入 + 读出字段完整一致', () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      final isar = IsarSetup.instance;

      final attrs = Attributes()
        ..constitution = 6
        ..enlightenment = 8
        ..agility = 5
        ..fortune = 4;
      final createdAt = DateTime(2026, 5, 1, 10);
      final c = Character.create(
        name: '苏惊鸿',
        realmTier: RealmTier.erLiu,
        realmLayer: RealmLayer.yuanShu,
        attributes: attrs,
        rarity: RarityTier.ziYou,
        lineageRole: LineageRole.founder,
        createdAt: createdAt,
        internalForce: 2400,
        internalForceMax: 3500,
        school: TechniqueSchool.gangMeng,
        assistTechniqueIds: [2, 3],
        learnedSkillIds: ['skill_a', 'skill_b'],
        isFounder: true,
        isActive: true,
        attributeBonusFromAdventure: 2,
      );

      final e = Equipment.create(
        defId: 'weapon_qing_feng_jian',
        tier: EquipmentTier.liQi,
        slot: EquipmentSlot.weapon,
        obtainedAt: DateTime(2026, 5, 3),
        obtainedFrom: '奇遇·古剑冢',
        school: TechniqueSchool.lingQiao,
        baseAttack: 680,
        baseSpeed: 45,
        enhanceLevel: 12,
        ownerCharacterId: 1,
        battleCount: 432,
        forgingSlots: [
          ForgingSlot()
            ..slotIndex = 1
            ..unlocked = true
            ..type = ForgingSlotType.pierce
            ..bonusValue = 15,
          ForgingSlot()..slotIndex = 2,
          ForgingSlot()..slotIndex = 3,
        ],
      );

      final t = Technique.create(
        defId: 'tech_yi_jin_jing',
        ownerCharacterId: 1,
        tier: TechniqueTier.menPaiJueXue,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: DateTime(2026, 5, 2),
        cultivationLayer: CultivationLayer.yuanMan,
        cultivationProgress: 480,
        cultivationProgressToNext: 800,
        skillUsageCount: [
          SkillUsageEntry()
            ..skillId = 'skill_yi_jin_jing_1'
            ..count = 1240,
        ],
      );

      await isar.writeTxn(() async {
        await isar.characters.put(c);
        await isar.equipments.put(e);
        await isar.techniques.put(t);
      });
      final cId = c.id;
      final eId = e.id;
      final tId = t.id;

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      final isar2 = IsarSetup.instance;

      final cBack = await isar2.characters.get(cId);
      expect(cBack, isNotNull);
      expect(cBack!.name, '苏惊鸿');
      expect(cBack.realmTier, RealmTier.erLiu);
      expect(cBack.realmLayer, RealmLayer.yuanShu);
      expect(cBack.attributes.constitution, 6);
      expect(cBack.attributes.enlightenment, 8);
      expect(cBack.attributes.total, 23);
      expect(cBack.school, TechniqueSchool.gangMeng);
      expect(cBack.assistTechniqueIds, [2, 3]);
      expect(cBack.learnedSkillIds, ['skill_a', 'skill_b']);
      expect(cBack.isFounder, isTrue);
      expect(cBack.isActive, isTrue);
      expect(cBack.attributeBonusFromAdventure, 2);
      expect(cBack.createdAt, createdAt);

      final eBack = await isar2.equipments.get(eId);
      expect(eBack, isNotNull);
      expect(eBack!.defId, 'weapon_qing_feng_jian');
      expect(eBack.tier, EquipmentTier.liQi);
      expect(eBack.slot, EquipmentSlot.weapon);
      expect(eBack.school, TechniqueSchool.lingQiao);
      expect(eBack.baseAttack, 680);
      expect(eBack.enhanceLevel, 12);
      expect(eBack.battleCount, 432);
      expect(eBack.forgingSlots, hasLength(3));
      expect(eBack.forgingSlots[0].unlocked, isTrue);
      expect(eBack.forgingSlots[0].type, ForgingSlotType.pierce);
      expect(eBack.forgingSlots[0].bonusValue, 15);

      final tBack = await isar2.techniques.get(tId);
      expect(tBack, isNotNull);
      expect(tBack!.defId, 'tech_yi_jin_jing');
      expect(tBack.tier, TechniqueTier.menPaiJueXue);
      expect(tBack.school, TechniqueSchool.gangMeng);
      expect(tBack.cultivationLayer, CultivationLayer.yuanMan);
      expect(tBack.cultivationProgress, 480);
      expect(tBack.skillUsageCount, hasLength(1));
      expect(tBack.skillUsageCount.first.skillId, 'skill_yi_jin_jing_1');
      expect(tBack.skillUsageCount.first.count, 1240);
    });

    test('@Index defId / ownerCharacterId 应可用 filter 查到', () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      final isar = IsarSetup.instance;

      final t = Technique.create(
        defId: 'tech_x',
        ownerCharacterId: 7,
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: DateTime(2026),
      );
      await isar.writeTxn(() => isar.techniques.put(t));

      final byDef =
          await isar.techniques.filter().defIdEqualTo('tech_x').findFirst();
      expect(byDef?.ownerCharacterId, 7);

      final byOwner = await isar.techniques
          .filter()
          .ownerCharacterIdEqualTo(7)
          .findAll();
      expect(byOwner, hasLength(1));
    });
  });
}
