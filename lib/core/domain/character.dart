import 'package:isar_community/isar.dart';

import '../../features/sect/domain/sect_rank.dart';
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

  /// 心法领悟点 wallet（W15 #30 闭关 techniqueLearnPoints 落点 / GDD §7.2）。
  ///
  /// 闭关收功累加，[TechniqueLearningService.learn] 生产路径将从此读。
  /// Demo 单角色为主，每角色独立 wallet，不做跨角色共享（祖师攒徒孙不继承）。
  int insightPoints = 0;

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

  /// 是否入派(P4.1 §12.2 Q3=A 复用 Character + Q2=C 双向 fk)。
  ///
  /// `true` 时 [sectId] + [sectRank] 必非 null;`SectMemberService.recruit/dismiss`
  /// writeTxn 时与 `Sect.memberCount` 同步维护(founder 也 `isInSect=true`,
  /// 但 `Sect.memberCount` 不含 founder 本人)。
  bool isInSect = false;

  /// 双向 fk → `Sect.id`(P4.1 §12.2 Q2=C · [isInSect]=true 时必非 null)。
  int? sectId;

  /// 门派阶位三阶(P4.1 §12.2 Q5=A · [isInSect]=true 时必非 null)。
  ///
  /// 组织层阶位 ≠ 修炼境界(GDD §5.3 不破七阶锁,详 [SectRank] doc)。
  @Enumerated(EnumType.name)
  SectRank? sectRank;

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
    int insightPoints = 0,
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
    bool isInSect = false,
    int? sectId,
    SectRank? sectRank,
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
      ..insightPoints = insightPoints
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
      ..attributeBonusFromAdventure = attributeBonusFromAdventure
      ..isInSect = isInSect
      ..sectId = sectId
      ..sectRank = sectRank;
  }
}
