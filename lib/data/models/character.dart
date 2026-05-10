import 'package:isar/isar.dart';

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
