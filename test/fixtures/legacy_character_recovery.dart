import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/sect_rank.dart';

part 'legacy_character_recovery.g.dart';

/// Frozen 0.51 Character fields from 02994529f.
/// The persisted collection identity is unchanged; recoverySettledAt is absent.
@collection
@Name('Character')
class LegacyCharacterRecovery {
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
  double passiveExperienceRemainder = 0;
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
