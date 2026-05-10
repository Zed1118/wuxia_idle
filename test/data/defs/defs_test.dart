import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/realm_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/models/enums.dart';

void main() {
  group('EquipmentDef.fromYaml', () {
    test('全字段解析 + 枚举反序列化 + schoolBias 可空', () {
      final y = <String, dynamic>{
        'id': 'weapon_qing_feng_jian',
        'name': '青锋剑',
        'tier': 'liQi',
        'slot': 'weapon',
        'schoolBias': 'lingQiao',
        'baseAttackMin': 600,
        'baseAttackMax': 750,
        'baseHealthMin': 0,
        'baseHealthMax': 0,
        'baseSpeedMin': 40,
        'baseSpeedMax': 55,
        'presetLoreIds': ['lore_qing_feng_origin'],
        'dropSourceTags': ['chapter_3', 'tower_15+'],
        'iconPath': 'assets/equipment/weapon_qing_feng_jian.png',
      };

      final def = EquipmentDef.fromYaml(y);

      expect(def.id, 'weapon_qing_feng_jian');
      expect(def.name, '青锋剑');
      expect(def.tier, EquipmentTier.liQi);
      expect(def.slot, EquipmentSlot.weapon);
      expect(def.schoolBias, TechniqueSchool.lingQiao);
      expect(def.baseAttackMin, 600);
      expect(def.baseAttackMax, 750);
      expect(def.baseSpeedMax, 55);
      expect(def.presetLoreIds, ['lore_qing_feng_origin']);
      expect(def.dropSourceTags, ['chapter_3', 'tower_15+']);
      expect(def.iconPath, 'assets/equipment/weapon_qing_feng_jian.png');
      expect(def.toString(), contains('weapon_qing_feng_jian'));
    });

    test('schoolBias 缺省 / 列表缺省解析为 null / 空 List', () {
      final def = EquipmentDef.fromYaml({
        'id': 'armor_basic',
        'name': '粗布衣',
        'tier': 'xunChang',
        'slot': 'armor',
        'baseAttackMin': 0,
        'baseAttackMax': 0,
        'baseHealthMin': 50,
        'baseHealthMax': 80,
        'baseSpeedMin': 0,
        'baseSpeedMax': 0,
        'iconPath': 'assets/equipment/armor_basic.png',
      });

      expect(def.schoolBias, isNull);
      expect(def.presetLoreIds, isEmpty);
      expect(def.dropSourceTags, isEmpty);
    });

    test('num → int 防御性转换（yaml 数字写法不一致也能吃下）', () {
      final def = EquipmentDef.fromYaml({
        'id': 'weapon_x',
        'name': '示例',
        'tier': 'haoJiaHuo',
        'slot': 'weapon',
        'baseAttackMin': 100.0,
        'baseAttackMax': 200,
        'baseHealthMin': 0,
        'baseHealthMax': 0,
        'baseSpeedMin': 10,
        'baseSpeedMax': 20.0,
        'presetLoreIds': const [],
        'dropSourceTags': const [],
        'iconPath': 'x.png',
      });

      expect(def.baseAttackMin, 100);
      expect(def.baseAttackMax, 200);
      expect(def.baseSpeedMax, 20);
    });
  });

  group('TechniqueDef.fromYaml', () {
    test('全字段解析 + 枚举反序列化', () {
      final def = TechniqueDef.fromYaml({
        'id': 'tech_yi_jin_jing',
        'name': '易筋经',
        'tier': 'menPaiJueXue',
        'school': 'gangMeng',
        'description': '少林七十二绝技之首。',
        'skillIds': [
          'skill_yi_jin_jing_1',
          'skill_yi_jin_jing_2',
          'skill_yi_jin_jing_3',
        ],
        'internalForceGrowthBonus': 1.30,
        'speedBonus': 0,
        'acquireSourceTags': ['chapter_3_boss', 'shaolin_quest'],
      });

      expect(def.id, 'tech_yi_jin_jing');
      expect(def.tier, TechniqueTier.menPaiJueXue);
      expect(def.school, TechniqueSchool.gangMeng);
      expect(def.skillIds.length, 3);
      expect(def.internalForceGrowthBonus, 1.30);
      expect(def.speedBonus, 0);
      expect(def.acquireSourceTags, ['chapter_3_boss', 'shaolin_quest']);
      expect(def.toString(), contains('tech_yi_jin_jing'));
    });

    test('int → double 防御性转换（speedBonus 也吃 num）', () {
      final def = TechniqueDef.fromYaml({
        'id': 'tech_basic',
        'name': '入门吐纳',
        'tier': 'ruMenGong',
        'school': 'yinRou',
        'description': '入门级心法。',
        'skillIds': const [],
        'internalForceGrowthBonus': 1, // 写成 int
        'speedBonus': 5,
        'acquireSourceTags': const [],
      });

      expect(def.internalForceGrowthBonus, 1.0);
      expect(def.speedBonus, 5);
    });
  });

  group('SkillDef.fromYaml', () {
    test('全字段解析 + parentTechniqueDefId 可空', () {
      final def = SkillDef.fromYaml({
        'id': 'skill_kang_long_you_hui',
        'name': '亢龙有悔',
        'description': '降龙十八掌第一式。',
        'type': 'ultimate',
        'powerMultiplier': 5500,
        'internalForceCost': 800,
        'cooldownTurns': 5,
        'requiresManualTrigger': true,
        'parentTechniqueDefId': 'tech_xiang_long_shi_ba_zhang',
        'visualEffect': 'dragon_palm_gold',
      });

      expect(def.type, SkillType.ultimate);
      expect(def.powerMultiplier, 5500);
      expect(def.requiresManualTrigger, isTrue);
      expect(def.parentTechniqueDefId, 'tech_xiang_long_shi_ba_zhang');
      expect(def.toString(), contains('skill_kang_long_you_hui'));
    });

    test('武学领悟独立招式 parentTechniqueDefId 为 null', () {
      final def = SkillDef.fromYaml({
        'id': 'skill_listen_rain_sword',
        'name': '听雨剑',
        'description': '竹林听雨所悟。',
        'type': 'powerSkill',
        'powerMultiplier': 1500,
        'internalForceCost': 200,
        'cooldownTurns': 2,
        'requiresManualTrigger': false,
        'parentTechniqueDefId': null,
        'visualEffect': 'rain_sword',
      });

      expect(def.parentTechniqueDefId, isNull);
      expect(def.type, SkillType.powerSkill);
    });
  });

  group('StageDef + EnemyDef.fromYaml', () {
    test('完整爬塔 Boss 关卡（enemyTeam 1 个）', () {
      final def = StageDef.fromYaml({
        'id': 'tower_layer_15',
        'name': '问鼎江湖·第十五层',
        'stageType': 'tower',
        'chapterIndex': null,
        'towerLayer': 15,
        'requiredRealm': 'erLiu',
        'enemyTeam': [
          {
            'id': 'enemy_ghost_blade',
            'name': '鬼影刀客',
            'realmTier': 'erLiu',
            'realmLayer': 'huaJing',
            'school': 'lingQiao',
            'baseHp': 18000,
            'baseAttack': 1200,
            'baseSpeed': 180,
            'skillIds': ['skill_ghost_step', 'skill_ghost_blade_ult'],
            'iconPath': 'assets/enemies/ghost_blade.png',
          },
        ],
        'isBossStage': true,
        'narrativeId': 'narr_tower_15_boss',
        'dropEquipmentDefIds': ['weapon_ghost_blade', 'armor_dark_robe'],
        'dropItemDefIds': ['item_mojianshi', 'item_xinxuejiejing'],
        'baseExpReward': 1500,
        'difficultyMultiplier': 1.85,
      });

      expect(def.stageType, StageType.tower);
      expect(def.chapterIndex, isNull);
      expect(def.towerLayer, 15);
      expect(def.requiredRealm, RealmTier.erLiu);
      expect(def.enemyTeam.length, 1);
      expect(def.enemyTeam.first.realmLayer, RealmLayer.huaJing);
      expect(def.enemyTeam.first.school, TechniqueSchool.lingQiao);
      expect(def.isBossStage, isTrue);
      expect(def.narrativeId, 'narr_tower_15_boss');
      expect(def.difficultyMultiplier, 1.85);
      expect(def.toString(), contains('tower_layer_15'));
      expect(def.toString(), contains('enemies=1'));
    });

    test('剧情主线关卡 enemyTeam 为空 + isBossStage 缺省 false', () {
      final def = StageDef.fromYaml({
        'id': 'mainline_ch1_stage_1',
        'name': '出山',
        'stageType': 'mainline',
        'chapterIndex': 1,
        'requiredRealm': 'xueTu',
        'enemyTeam': const [],
        'narrativeId': 'narr_ch1_opening',
        'dropEquipmentDefIds': const [],
        'dropItemDefIds': const [],
        'baseExpReward': 0,
        'difficultyMultiplier': 1.0,
      });

      expect(def.enemyTeam, isEmpty);
      expect(def.isBossStage, isFalse);
      expect(def.towerLayer, isNull);
      expect(def.chapterIndex, 1);
    });

    test('enemyTeam 3 个上限（多个敌人）', () {
      final def = StageDef.fromYaml({
        'id': 'mainline_ch2_ambush',
        'name': '山道遇袭',
        'stageType': 'mainline',
        'chapterIndex': 2,
        'requiredRealm': 'sanLiu',
        'enemyTeam': List.generate(
          3,
          (i) => {
            'id': 'enemy_thief_$i',
            'name': '山贼$i',
            'realmTier': 'sanLiu',
            'realmLayer': 'qiMeng',
            'school': 'gangMeng',
            'baseHp': 800,
            'baseAttack': 100,
            'baseSpeed': 60,
            'skillIds': const [],
            'iconPath': 'assets/enemies/thief.png',
          },
        ),
        'isBossStage': false,
        'dropEquipmentDefIds': const [],
        'dropItemDefIds': const [],
        'baseExpReward': 100,
        'difficultyMultiplier': 1.0,
      });

      expect(def.enemyTeam.length, 3);
      expect(def.enemyTeam[2].name, '山贼2');
    });
  });

  group('RealmDef.fromYaml', () {
    test('xueTu/qiMeng = absoluteLevel 1，三系锁死字段一致', () {
      final def = RealmDef.fromYaml({
        'tier': 'xueTu',
        'layer': 'qiMeng',
        'absoluteLevel': 1,
        'internalForceMax': 100,
        'experienceToNext': 50,
        'equipmentTierCap': 'xunChang',
        'techniqueTierCap': 'ruMenGong',
      });

      expect(def.tier, RealmTier.xueTu);
      expect(def.layer, RealmLayer.qiMeng);
      expect(def.absoluteLevel, 1);
      expect(def.internalForceMax, 100);
      expect(def.equipmentTierCap, EquipmentTier.xunChang);
      expect(def.techniqueTierCap, TechniqueTier.ruMenGong);
      expect(def.toString(), contains('lv=1'));
    });

    test('wuSheng/dengFeng = absoluteLevel 49（武圣极境）', () {
      final def = RealmDef.fromYaml({
        'tier': 'wuSheng',
        'layer': 'dengFeng',
        'absoluteLevel': 49,
        'internalForceMax': 15000,
        'experienceToNext': 0,
        'equipmentTierCap': 'shenWu',
        'techniqueTierCap': 'chuanShuoShenGong',
      });

      expect(def.absoluteLevel, 49);
      expect(def.internalForceMax, 15000);
      expect(def.equipmentTierCap, EquipmentTier.shenWu);
      expect(def.techniqueTierCap, TechniqueTier.chuanShuoShenGong);
    });
  });
}
