import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/models/attributes.dart';
import 'package:wuxia_idle/data/models/character.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/data/models/forging_slot.dart';
import 'package:wuxia_idle/data/models/skill_usage_entry.dart';
import 'package:wuxia_idle/data/models/technique.dart';

void main() {
  group('Character.create', () {
    test('应一次填齐所有 late 字段并允许默认值兜底', () {
      final attrs = Attributes()
        ..constitution = 6
        ..enlightenment = 8
        ..agility = 5
        ..fortune = 4;
      final t = DateTime(2026, 5, 1);

      final c = Character.create(
        name: '苏惊鸿',
        realmTier: RealmTier.erLiu,
        realmLayer: RealmLayer.yuanShu,
        attributes: attrs,
        rarity: RarityTier.ziYou,
        lineageRole: LineageRole.founder,
        createdAt: t,
      );

      expect(c.name, '苏惊鸿');
      expect(c.realmTier, RealmTier.erLiu);
      expect(c.realmLayer, RealmLayer.yuanShu);
      expect(identical(c.attributes, attrs), isTrue);
      expect(c.rarity, RarityTier.ziYou);
      expect(c.lineageRole, LineageRole.founder);
      expect(c.createdAt, t);

      expect(c.internalForce, 0);
      expect(c.internalForceMax, 500);
      expect(c.assistTechniqueIds, isEmpty);
      expect(c.discipleIds, isEmpty);
      expect(c.learnedSkillIds, isEmpty);
      expect(c.isAlive, isTrue);
      expect(c.isActive, isFalse);
    });
  });

  group('Equipment.create', () {
    test('未传 forgingSlots 时应自动填齐 3 个空槽 (索引 1/2/3)', () {
      final t = DateTime(2026, 5, 3);

      final e = Equipment.create(
        defId: 'weapon_qing_feng_jian',
        tier: EquipmentTier.liQi,
        slot: EquipmentSlot.weapon,
        obtainedAt: t,
        obtainedFrom: '奇遇·古剑冢',
      );

      expect(e.forgingSlots, hasLength(3));
      expect(e.forgingSlots.map((s) => s.slotIndex), [1, 2, 3]);
      expect(e.forgingSlots.every((s) => !s.unlocked), isTrue);
      expect(e.lores, isEmpty);
      expect(e.previousOwnerCharacterIds, isEmpty);
      expect(e.battleCount, 0);
    });

    test('显式传入 forgingSlots 时应保留传入对象', () {
      final custom = [
        ForgingSlot()
          ..slotIndex = 1
          ..unlocked = true
          ..type = ForgingSlotType.pierce
          ..bonusValue = 15,
        ForgingSlot()..slotIndex = 2,
        ForgingSlot()..slotIndex = 3,
      ];
      final e = Equipment.create(
        defId: 'x',
        tier: EquipmentTier.liQi,
        slot: EquipmentSlot.weapon,
        obtainedAt: DateTime(2026),
        obtainedFrom: 'test',
        forgingSlots: custom,
      );

      expect(identical(e.forgingSlots, custom), isTrue);
      expect(e.forgingSlots.first.unlocked, isTrue);
    });
  });

  group('EquipmentResonance', () {
    test('battleCount 应映射到正确的 ResonanceStage 与加成', () {
      final cases = <int, (ResonanceStage, double)>{
        0: (ResonanceStage.shengShu, 1.0),
        99: (ResonanceStage.shengShu, 1.0),
        100: (ResonanceStage.chenShou, 1.10),
        499: (ResonanceStage.chenShou, 1.10),
        500: (ResonanceStage.moQi, 1.20),
        1999: (ResonanceStage.moQi, 1.20),
        2000: (ResonanceStage.xinJianTongLing, 1.30),
        99999: (ResonanceStage.xinJianTongLing, 1.30),
      };
      for (final entry in cases.entries) {
        final e = Equipment.create(
          defId: 'x',
          tier: EquipmentTier.liQi,
          slot: EquipmentSlot.weapon,
          obtainedAt: DateTime(2026),
          obtainedFrom: 't',
          battleCount: entry.key,
        );
        expect(e.resonanceStage, entry.value.$1, reason: 'battleCount=${entry.key}');
        expect(e.resonanceBonus, entry.value.$2, reason: 'battleCount=${entry.key}');
      }
    });

    test('inheritFrom 应保留 70% battleCount 并标记为遗物', () {
      final e = Equipment.create(
        defId: 'x',
        tier: EquipmentTier.liQi,
        slot: EquipmentSlot.weapon,
        obtainedAt: DateTime(2026),
        obtainedFrom: 't',
        battleCount: 1000,
      );

      e.inheritFrom(7);

      expect(e.battleCount, 700);
      expect(e.isLineageHeritage, isTrue);
      expect(e.previousOwnerCharacterIds, [7]);
    });
  });

  group('Technique.create', () {
    test('应初始化 cultivationLayer 为 chuKui 且 progress 为 0', () {
      final tech = Technique.create(
        defId: 'tech_yi_jin_jing',
        ownerCharacterId: 1,
        tier: TechniqueTier.menPaiJueXue,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: DateTime(2026, 5, 2),
      );

      expect(tech.cultivationLayer, CultivationLayer.chuKui);
      expect(tech.cultivationProgress, 0);
      expect(tech.cultivationProgressToNext, 100);
      expect(tech.skillUsageCount, isEmpty);
      expect(tech.wasMainBeforeReset, isFalse);
    });
  });

  group('TechniqueDispersion.disperse', () {
    test('应把 progress 减半、role 转 assist、wasMain 标记为 true', () {
      final tech = Technique.create(
        defId: 'tech_yi_jin_jing',
        ownerCharacterId: 1,
        tier: TechniqueTier.menPaiJueXue,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: DateTime(2026, 5, 2),
        cultivationProgress: 481,
        skillUsageCount: [
          SkillUsageEntry()
            ..skillId = 'skill_yi_jin_jing_1'
            ..count = 1240,
        ],
      );

      tech.disperse();

      expect(tech.cultivationProgress, 240);
      expect(tech.role, TechniqueRole.assist);
      expect(tech.wasMainBeforeReset, isTrue);
      expect(tech.skillUsageCount.single.count, 1240, reason: '招式使用记录不应被散功清除');
    });
  });
}
