import 'package:isar_community/isar.dart';

import 'attributes.dart';
import 'enums.dart';

part 'character.g.dart';

/// 角色（data_schema.md §4.2 / GDD §7.1）。
///
/// 玩家可控角色（祖师 / 弟子 / 徒孙）。Demo 阶段最多 3 个。
@collection
class Character {
  Id id = Isar.autoIncrement;

  late String name;

  @Enumerated(EnumType.name)
  late RealmTier realmTier;

  @Enumerated(EnumType.name)
  late RealmLayer realmLayer;

  int internalForce = 0;
  int internalForceMax = 500;
  int experience = 0;
  int experienceToNextLayer = 100;

  late Attributes attributes;

  @Enumerated(EnumType.name)
  late RarityTier rarity;

  @Enumerated(EnumType.name)
  TechniqueSchool? school;

  int? mainTechniqueId;
  List<int> assistTechniqueIds = [];

  int? equippedWeaponId;
  int? equippedArmorId;
  int? equippedAccessoryId;

  List<String> learnedSkillIds = [];

  /// 装备的奇遇专属招式 id(C-W14-3-A,单 slot)。
  ///
  /// **每角色独立**(平行 equippedWeaponId 等),奇遇 unlock 池是账号级
  /// (EncounterProgress.unlockedSkillIds),装备 slot 是角色级。装/卸经
  /// [EncounterService.equipEncounterSkill] / [unequipEncounterSkill],
  /// canEquip 检查境界 ≥ tier(GDD §5.3 三系锁死)。
  String? equippedEncounterSkillId;

  @Index()
  bool isActive = false;

  bool isInRetreat = false;
  int? currentRetreatSessionId;

  int? masterId;
  List<int> discipleIds = [];

  @Enumerated(EnumType.name)
  late LineageRole lineageRole;

  bool isFounder = false;
  bool isAlive = true;
  int birthInGameYear = 0;

  int attributeBonusFromAdventure = 0;

  late DateTime createdAt;

  Character();

  /// 工厂方法：一次性初始化所有 late 字段，避免 LateInitializationError。
  factory Character.create({
    required String name,
    required RealmTier realmTier,
    required RealmLayer realmLayer,
    required Attributes attributes,
    required RarityTier rarity,
    required LineageRole lineageRole,
    required DateTime createdAt,
    int internalForce = 0,
    int internalForceMax = 500,
    int experience = 0,
    int experienceToNextLayer = 100,
    TechniqueSchool? school,
    int? mainTechniqueId,
    List<int>? assistTechniqueIds,
    int? equippedWeaponId,
    int? equippedArmorId,
    int? equippedAccessoryId,
    List<String>? learnedSkillIds,
    String? equippedEncounterSkillId,
    bool isActive = false,
    bool isInRetreat = false,
    int? currentRetreatSessionId,
    int? masterId,
    List<int>? discipleIds,
    bool isFounder = false,
    bool isAlive = true,
    int birthInGameYear = 0,
    int attributeBonusFromAdventure = 0,
  }) {
    return Character()
      ..name = name
      ..realmTier = realmTier
      ..realmLayer = realmLayer
      ..attributes = attributes
      ..rarity = rarity
      ..lineageRole = lineageRole
      ..createdAt = createdAt
      ..internalForce = internalForce
      ..internalForceMax = internalForceMax
      ..experience = experience
      ..experienceToNextLayer = experienceToNextLayer
      ..school = school
      ..mainTechniqueId = mainTechniqueId
      ..assistTechniqueIds = assistTechniqueIds ?? []
      ..equippedWeaponId = equippedWeaponId
      ..equippedArmorId = equippedArmorId
      ..equippedAccessoryId = equippedAccessoryId
      ..learnedSkillIds = learnedSkillIds ?? []
      ..equippedEncounterSkillId = equippedEncounterSkillId
      ..isActive = isActive
      ..isInRetreat = isInRetreat
      ..currentRetreatSessionId = currentRetreatSessionId
      ..masterId = masterId
      ..discipleIds = discipleIds ?? []
      ..isFounder = isFounder
      ..isAlive = isAlive
      ..birthInGameYear = birthInGameYear
      ..attributeBonusFromAdventure = attributeBonusFromAdventure;
  }
}
