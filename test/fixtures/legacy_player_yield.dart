import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/island_building_type.dart';
import 'package:wuxia_idle/core/domain/sect_rank.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';

part 'legacy_player_yield.g.dart';

/// Frozen 0.49 persisted fields from 342d1927529b8306582431be597ef1975bd69deb.
/// Only Dart type names differ; @Name retains the original Isar identities.
/// These schemas deliberately omit the 0.50 passive ledger and product stocks,
/// while retaining every field which already existed in the 0.49 models.
@collection
@Name('SaveData')
class LegacyPlayerYieldSaveData {
  Id id = 0;
  int slotId = 1;
  String? slotName;
  late String saveVersion;
  late DateTime createdAt;
  late DateTime lastSavedAt;
  late DateTime lastOnlineAt;
  String? sectName;
  int? founderCharacterId;
  List<int> activeCharacterIds = [];
  int totalPlaySeconds = 0;
  bool isOnboardingCompleted = false;
  int highestTowerLayer = 0;
  DateTime? towerLeaderboardSyncedAt;
  int tutorialStep = 0;
  List<int> tutorialHintsRead = [];
  bool recruitmentOffered = false;
  List<int> recruitedDiscipleIds = [];
  List<String> triggeredBossRecruitStageIds = [];
  List<String> triggeredDiscipleJoinStageIds = [];
  List<String> grantedMilestoneEquipmentIds = [];
  List<SkillUnlockEntry> skillUnlockProgress = [];
  int totalPassiveMojianshi = 0;
  int totalPassiveExperience = 0;
  List<LegacyPlayerYieldIslandBuildingState> islandBuildings = [];
  DateTime? islandLastSettledAt;
  int? sweepReadinessPoints;
  DateTime? sweepReadinessLastRecoveredAt;
  bool jianghuJourneyUnlocked = false;
  int baicaoMaxDepth = 0;
  int expeditionRunSerial = 0;
  int gauntletRunSerial = 0;
  List<String> clearedGauntletIds = [];
  DateTime? duanhunFirstClearedAt;
  int duanhunClearedCyclesMax = 0;
  List<String> grantedTicketMilestoneIds = [];
}

@collection
@Name('Character')
class LegacyPlayerYieldCharacter {
  Id id = Isar.autoIncrement;
  late String name;
  @Enumerated(EnumType.name)
  late RealmTier realmTier;
  @Enumerated(EnumType.name)
  late RealmLayer realmLayer;
  int internalForce = 0;
  int internalForceMax = 500;
  double innerBreathDisorderHoursRemaining = 0;
  double innerDemonResidueHoursRemaining = 0;
  int lightInjuryStacks = 0;
  double injuryHoursRemaining = 0;
  int experience = 0;
  int experienceToNextLayer = 100;
  int level = 1;
  int levelExp = 0;
  int insightPoints = 0;
  late Attributes attributes;
  @Enumerated(EnumType.name)
  RarityTier rarity = RarityTier.biaoZhun;
  @Enumerated(EnumType.name)
  TechniqueSchool? school;
  int? mainTechniqueId;
  List<int> assistTechniqueIds = [];
  int? equippedWeaponId;
  int? equippedArmorId;
  int? equippedAccessoryId;
  List<String> learnedSkillIds = [];
  String? mainSkillId1;
  String? mainSkillId2;
  String? assistSkillId;
  String? resonanceSkillId;
  String? ultimateSkillId;
  String? keySkillId;
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
  bool isInSect = false;
  int? sectId;
  @Enumerated(EnumType.name)
  SectRank? sectRank;
  String? portraitPath;
  String? founderCreationSchoolId;
  String? founderCreationOriginId;
  String? founderCreationFateId;
  late DateTime createdAt;
}

@embedded
@Name('IslandBuildingState')
class LegacyPlayerYieldIslandBuildingState {
  @Enumerated(EnumType.name)
  BuildingType type = BuildingType.tieJiangChang;
  int level = 1;
  double stored = 0;
  String? activeRecipeId;
}
