import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/island_building_type.dart';
import 'package:wuxia_idle/core/domain/sect_rank.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_source.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_contract.dart';

part 'legacy_numeric_fields.g.dart';

/// Real older collections, omitting the reviewed 0.48 numeric properties.

@embedded
@Name('Attributes')
class Legacy048Attributes {
  int constitution = 5;
  int enlightenment = 5;
  int agility = 5;
  int fortune = 5;
}

@collection
@Name('Character')
class Legacy048Character {
  Id id = 1;
  String name = 'legacy_name';
  @Enumerated(EnumType.name)
  RealmTier realmTier = RealmTier.values.first;
  @Enumerated(EnumType.name)
  RealmLayer realmLayer = RealmLayer.values.first;
  int internalForceMax = 500;
  Legacy048Attributes attributes = Legacy048Attributes();
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
  bool isActive = false;
  bool isInRetreat = false;
  int? currentRetreatSessionId;
  int? masterId;
  List<int> discipleIds = [];
  @Enumerated(EnumType.name)
  LineageRole lineageRole = LineageRole.values.first;
  bool isFounder = false;
  bool isAlive = true;
  bool isInSect = false;
  int? sectId;
  @Enumerated(EnumType.name)
  SectRank? sectRank;
  String? portraitPath;
  String? founderCreationSchoolId;
  String? founderCreationOriginId;
  String? founderCreationFateId;
  DateTime createdAt = DateTime.utc(2026, 9, 6);
}

@collection
@Name('Equipment')
class Legacy048Equipment {
  Id id = 1;
  String defId = 'legacy_defId';
  String? customName;
  @Enumerated(EnumType.name)
  EquipmentTier tier = EquipmentTier.values.first;
  @Enumerated(EnumType.name)
  EquipmentSlot slot = EquipmentSlot.values.first;
  @Enumerated(EnumType.name)
  TechniqueSchool? school;
  int? ownerCharacterId;
  bool isLineageHeritage = false;
  bool isLocked = false;
  List<int> previousOwnerCharacterIds = [];
  List<Legacy048ForgingSlot> forgingSlots = [Legacy048ForgingSlot()];
  List<Legacy048Lore> lores = [Legacy048Lore()];
  DateTime obtainedAt = DateTime.utc(2026, 9, 6);
  String obtainedFrom = 'legacy_obtainedFrom';
}

@embedded
@Name('ForgingSlot')
class Legacy048ForgingSlot {
  int slotIndex = 1;
  @Enumerated(EnumType.name)
  ForgingSlotType? type;
  bool unlocked = false;
  String? specialSkillId;
}

@collection
@Name('GameEvent')
class Legacy048GameEvent {
  Id id = 1;
  @Enumerated(EnumType.name)
  GameEventType eventType = GameEventType.values.first;
  String title = 'legacy_title';
  String summary = 'legacy_summary';
  int? relatedCharacterId;
  List<String> relatedEntityIds = [];
  DateTime occurredAt = DateTime.utc(2026, 9, 6);
  bool isRead = false;
}

@collection
@Name('InventoryItem')
class Legacy048InventoryItem {
  Id id = 1;
  String defId = 'legacy_defId';
  @Enumerated(EnumType.name)
  ItemType itemType = ItemType.values.first;
  DateTime firstObtainedAt = DateTime.utc(2026, 9, 6);
  DateTime lastObtainedAt = DateTime.utc(2026, 9, 6);
}

@embedded
@Name('IslandBuildingState')
class Legacy048IslandBuildingState {
  @Enumerated(EnumType.name)
  BuildingType type = BuildingType.tieJiangChang;
  String? activeRecipeId;
}

@embedded
@Name('Lore')
class Legacy048Lore {
  String text = '';
  bool isPreset = true;
  DateTime addedAt = DateTime(2000);
  String? triggerEventDesc;
}

@embedded
@Name('RewardEntry')
class Legacy048RewardEntry {
  String rewardKey = '';
}

@collection
@Name('SaveData')
class Legacy048SaveData {
  Id id = 0;
  int slotId = 1;
  String? slotName;
  String saveVersion = '0.47.0';
  DateTime createdAt = DateTime.utc(2026, 9, 6);
  DateTime lastSavedAt = DateTime.utc(2026, 9, 6);
  DateTime lastOnlineAt = DateTime.utc(2026, 9, 6);
  String? sectName;
  int? founderCharacterId;
  List<int> activeCharacterIds = [];
  bool isOnboardingCompleted = false;
  DateTime? towerLeaderboardSyncedAt;
  List<int> tutorialHintsRead = [];
  bool recruitmentOffered = false;
  List<int> recruitedDiscipleIds = [];
  List<String> triggeredBossRecruitStageIds = [];
  List<String> triggeredDiscipleJoinStageIds = [];
  List<String> grantedMilestoneEquipmentIds = [];
  List<Legacy048SkillUnlockEntry> skillUnlockProgress = [
    Legacy048SkillUnlockEntry(),
  ];
  List<Legacy048IslandBuildingState> islandBuildings = [
    Legacy048IslandBuildingState(),
  ];
  DateTime? islandLastSettledAt;
  int? sweepReadinessPoints;
  DateTime? sweepReadinessLastRecoveredAt;
  bool jianghuJourneyUnlocked = false;
  List<String> clearedGauntletIds = [];
  DateTime? duanhunFirstClearedAt;
  List<String> grantedTicketMilestoneIds = [];
}

@embedded
@Name('SkillUnlockEntry')
class Legacy048SkillUnlockEntry {
  String skillId = '';
  bool unlocked = false;
}

@embedded
@Name('SkillUsageEntry')
class Legacy048SkillUsageEntry {
  String skillId = '';
}

@collection
@Name('Technique')
class Legacy048Technique {
  Id id = 1;
  String defId = 'legacy_defId';
  int ownerCharacterId = 1;
  @Enumerated(EnumType.name)
  TechniqueTier tier = TechniqueTier.values.first;
  @Enumerated(EnumType.name)
  TechniqueSchool school = TechniqueSchool.values.first;
  @Enumerated(EnumType.name)
  CultivationLayer cultivationLayer = CultivationLayer.chuKui;
  int cultivationProgressToNext = 100;
  List<Legacy048SkillUsageEntry> skillUsageCount = [Legacy048SkillUsageEntry()];
  @Enumerated(EnumType.name)
  TechniqueRole role = TechniqueRole.values.first;
  bool wasMainBeforeReset = false;
  DateTime learnedAt = DateTime.utc(2026, 9, 6);
}

@embedded
@Name('ActivityMemberSnapshot')
class Legacy048ActivityMemberSnapshot {
  int characterId = 0;
  List<int> reservedEquipmentIds = [];
  List<int> reservedTechniqueIds = [];
  bool isDowned = false;
  List<String> skillCooldownKeys = [];
  List<int> skillCooldownTurns = [];
}

@collection
@Name('DurableActivityCombatRun')
class Legacy048DurableActivityCombatRun {
  Id id = 1;
  int saveDataId = 1;
  @Enumerated(EnumType.name)
  DurableActivityKind kind = DurableActivityKind.values.first;
  String contentId = 'legacy_contentId';
  String loadoutPlanId = 'legacy_loadoutPlanId';
  String stageId = 'legacy_stageId';
  int cycleIndex = 1;
  int seed = 1;
  @Enumerated(EnumType.name)
  ActivityContentKind contentKind = ActivityContentKind.values.first;
  @Enumerated(EnumType.name)
  ActivityParticipationMode participation =
      ActivityParticipationMode.values.first;
  @Enumerated(EnumType.name)
  ActivityController controller = ActivityController.values.first;
  @Enumerated(EnumType.name)
  ActivityClock clock = ActivityClock.values.first;
  @Enumerated(EnumType.name)
  ActivityEntryKind entryKind = ActivityEntryKind.values.first;
  List<Legacy048ActivityMemberSnapshot> members = [
    Legacy048ActivityMemberSnapshot(),
  ];
  DateTime participantCreatedAt = DateTime.utc(2026, 9, 6);
  String participantName = 'legacy_participantName';
  @Enumerated(EnumType.name)
  Formation? formation;
  @Enumerated(EnumType.name)
  DurableActivityPhase phase = DurableActivityPhase.active;
  @Enumerated(EnumType.name)
  DurableActivityOutcome outcome = DurableActivityOutcome.none;
  DateTime startedAt = DateTime.utc(2026, 9, 6);
  DateTime lastAdvancedAt = DateTime.utc(2026, 9, 6);
  DateTime? settlementAppliedAt;
  DateTime? closedAt;
}

@collection
@Name('BossMemory')
class Legacy048BossMemory {
  Id id = 1;
  int saveDataId = 1;
  String bossKey = 'legacy_bossKey';
  @Enumerated(EnumType.name)
  BossMemorySource source = BossMemorySource.values.first;
  int groupIndex = 1;
  String bossName = 'legacy_bossName';
  DateTime? firstClearedAt;
  bool isPreRecord = false;
  int? totalDamage;
  int? critCount;
  int? totalTicks;
  String? topContributorName;
  int? topContributorDamage;
  String? treasureName;
  @Enumerated(EnumType.name)
  EquipmentTier? treasureTier;
  List<String> rosterNames = [];
  List<String> rosterPortraits = [];
  int defeatCount = 1;
}

@collection
@Name('BossGauntletRun')
class Legacy048BossGauntletRun {
  Id id = 1;
  int saveDataId = 1;
  int seed = 1;
  bool cycleSeedEnabled = false;
  @enumerated
  GauntletPhase sessionPhase = GauntletPhase.inBattle;
  List<Legacy048ActivityMemberSnapshot> members = [
    Legacy048ActivityMemberSnapshot(),
  ];
  List<String> escrowItemDefIds = [];
  List<int> escrowLoadedQty = [];
  List<int> escrowUsedQty = [];
  List<String> rewardCandidateDefIds = [];
  bool isFirstClearPending = false;
  List<Legacy048RewardEntry> stagedRewards = [Legacy048RewardEntry()];
}

@collection
@Name('EncounterProgress')
class Legacy048EncounterProgress {
  Id id = 1;
  int saveDataId = 1;
  List<String> triggeredEncounterIds = [];
  List<Legacy048SchoolKillCount> schoolKillCounts = [
    Legacy048SchoolKillCount(),
  ];
  List<Legacy048BiomeMinutes> biomeMinutes = [Legacy048BiomeMinutes()];
  List<Legacy048WeatherMinutes> weatherMinutes = [Legacy048WeatherMinutes()];
  List<String> unlockedSkillIds = [];
  DateTime createdAt = DateTime.utc(2026, 9, 6);
}

@embedded
@Name('SchoolKillCount')
class Legacy048SchoolKillCount {
  @enumerated
  TechniqueSchool school = TechniqueSchool.gangMeng;
}

@embedded
@Name('BiomeMinutes')
class Legacy048BiomeMinutes {
  @enumerated
  EncounterBiome biome = EncounterBiome.mountainForest;
}

@embedded
@Name('WeatherMinutes')
class Legacy048WeatherMinutes {
  @enumerated
  EncounterWeather weather = EncounterWeather.clear;
}

@collection
@Name('ExpeditionMilestoneRecord')
class Legacy048ExpeditionMilestoneRecord {
  Id id = 1;
  String recordKey = 'legacy_recordKey';
  int saveDataId = 1;
  String routeId = 'legacy_routeId';
  String milestoneId = 'legacy_milestoneId';
  int nodeIndex = 1;
  int nodeSeed = 1;
  int sourceRunId = 1;
  int sourceParticipantId = 1;
  DateTime discoveredAt = DateTime.utc(2026, 9, 6);
  DateTime? manualClearedAt;
}

@collection
@Name('ExpeditionRun')
class Legacy048ExpeditionRun {
  Id id = 1;
  int saveDataId = 1;
  @enumerated
  ExpeditionPolicy policy = ExpeditionPolicy.values.first;
  int seed = 1;
  DateTime departedAt = DateTime.utc(2026, 9, 6);
  DateTime? lastSettledAt;
  List<Legacy048ActivityMemberSnapshot> members = [
    Legacy048ActivityMemberSnapshot(),
  ];
  List<Legacy048RewardEntry> stagedRewards = [Legacy048RewardEntry()];
  bool defeated = false;
}

@collection
@Name('NpcRelation')
class Legacy048NpcRelation {
  Id id = 1;
  int sourceCharacterId = 1;
  int targetCharacterId = 1;
  String type = 'legacy_type';
  int level = 1;
  DateTime updatedAt = DateTime.utc(2026, 9, 6);
}

@collection
@Name('Reputation')
class Legacy048Reputation {
  Id id = 1;
  int playerId = 1;
  String factionId = 'legacy_factionId';
  int value = 1;
  DateTime updatedAt = DateTime.utc(2026, 9, 6);
}

@collection
@Name('MainlineProgress')
class Legacy048MainlineProgress {
  Id id = 1;
  int saveDataId = 1;
  List<String> clearedStageIds = [];
  List<DateTime> clearedAt = [];
  List<String> clearedStageCycleKeys = [];
  List<String> clearedChapterCycleKeys = [];
}

@collection
@Name('MainlineSettlementJournal')
class Legacy048MainlineSettlementJournal {
  Id id = 1;
  String settlementId = 'legacy_settlementId';
  int saveDataId = 1;
  String runId = 'legacy_runId';
  String stageId = 'legacy_stageId';
  int participantId = 1;
  int loadoutVersion = 1;
  String loadoutSnapshotId = 'legacy_loadoutSnapshotId';
  List<String> loadoutSnapshotIds = [];
  @Enumerated(EnumType.name)
  MainlineSettlementPhase phase = MainlineSettlementPhase.prepared;
  @Enumerated(EnumType.name)
  MainlinePostSettlementAction postSettlementAction =
      MainlinePostSettlementAction.none;
  List<String> pendingEffectIds = [];
  List<String> completedEffectIds = [];
  DateTime createdAt = DateTime.utc(2026, 9, 6);
  DateTime updatedAt = DateTime.utc(2026, 9, 6);
  DateTime? coreAppliedAt;
  DateTime? closedAt;
}

@collection
@Name('ProgressiveUnlockReceipt')
class Legacy048ProgressiveUnlockReceipt {
  Id id = 1;
  String receiptKey = 'legacy_receiptKey';
  int saveDataId = 1;
  @Enumerated(EnumType.name)
  ProgressiveUnlockId unlockId = ProgressiveUnlockId.values.first;
  @Enumerated(EnumType.name)
  ProgressiveUnlockState highestState = ProgressiveUnlockState.values.first;
  DateTime firstObservedAt = DateTime.utc(2026, 9, 6);
  DateTime updatedAt = DateTime.utc(2026, 9, 6);
  DateTime? openedAt;
  DateTime? sealAcknowledgedAt;
}

@collection
@Name('PvpRecord')
class Legacy048PvpRecord {
  Id id = 1;
  String matchId = 'legacy_matchId';
  int playerId = 1;
  int opponentSnapshotId = 1;
  int leftSnapshotId = 1;
  int? winnerId;
  int playerEloBefore = 1;
  int playerEloAfter = 1;
  int eloDelta = 1;
  DateTime timestamp = DateTime.utc(2026, 9, 6);
}

@collection
@Name('PvpSnapshot')
class Legacy048PvpSnapshot {
  Id id = 1;
  String snapshotJson = 'legacy_snapshotJson';
  int snapshotElo = 1;
  DateTime takenAt = DateTime.utc(2026, 9, 6);
}

@collection
@Name('RewardClaimReceipt')
class Legacy048RewardClaimReceipt {
  Id id = 1;
  String claimKey = 'legacy_claimKey';
  int saveDataId = 1;
  @Enumerated(EnumType.name)
  RewardContentKind contentKind = RewardContentKind.values.first;
  String contentId = 'legacy_contentId';
  @Enumerated(EnumType.name)
  RewardLayer layer = RewardLayer.values.first;
  @Enumerated(EnumType.name)
  RewardScope scope = RewardScope.values.first;
  int? participantId;
  String? occurrenceId;
  String sourceSettlementId = 'legacy_sourceSettlementId';
  bool isHistoricalTombstone = false;
  DateTime createdAt = DateTime.utc(2026, 9, 6);
}

@collection
@Name('RetreatSession')
class Legacy048RetreatSession {
  Id id = 1;
  int saveDataId = 1;
  @enumerated
  RetreatMapType mapType = RetreatMapType.values.first;
  @Enumerated(EnumType.name)
  RealmTier? realmTierAtStart;
  DateTime startedAt = DateTime.utc(2026, 9, 6);
  DateTime? completedAt;
  @enumerated
  RetreatStatus status = RetreatStatus.active;
  List<Legacy048RewardEntry> actualRewards = [Legacy048RewardEntry()];
}

@collection
@Name('Sect')
class Legacy048Sect {
  Id id = 1;
  String name = 'legacy_name';
  int founderId = 1;
  int sectLevel = 1;
  int sectReputation = 1;
  int totalWins = 1;
  DateTime createdAt = DateTime.utc(2026, 9, 6);
  DateTime? lastEventAt;
  DateTime? lastTickAt;
  List<String> territoryIds = [];
  int memberCount = 0;
}

@collection
@Name('SectEvent')
class Legacy048SectEvent {
  Id id = 1;
  int sectId = 1;
  @Enumerated(EnumType.name)
  SectEventType type = SectEventType.values.first;
  @Enumerated(EnumType.name)
  SectEventStatus status = SectEventStatus.values.first;
  DateTime triggeredAt = DateTime.utc(2026, 9, 6);
  DateTime? resolvedAt;
  String narrativeId = 'legacy_narrativeId';
  int? reputationDelta;
}

@collection
@Name('TowerPersonalRecord')
class Legacy048TowerPersonalRecord {
  Id id = 1;
  String recordKey = 'legacy_recordKey';
  int saveDataId = 1;
  int participantId = 1;
  int? bestClearTimeMs;
  DateTime createdAt = DateTime.utc(2026, 9, 6);
  DateTime updatedAt = DateTime.utc(2026, 9, 6);
  DateTime lastClearedAt = DateTime.utc(2026, 9, 6);
}

@collection
@Name('TowerProgress')
class Legacy048TowerProgress {
  Id id = 1;
  int saveDataId = 1;
  DateTime? highestClearedAt;
  DateTime createdAt = DateTime.utc(2026, 9, 6);
  List<int> perFloorClearTimes = [];
  int? bestClearTime;
  DateTime? lastClearedAt;
}

@collection
@Name('EquipmentCatalogEntry')
class Legacy048EquipmentCatalogEntry {
  Id id = 1;
  int saveDataId = 1;
  String defId = 'legacy_defId';
  DateTime? firstObtainedAt;
  String firstObtainedFrom = 'legacy_firstObtainedFrom';
  int obtainedCount = 1;
  bool isPreRecord = false;
}

const legacyNumericSchemas = <CollectionSchema>[
  Legacy048CharacterSchema,
  Legacy048EquipmentSchema,
  Legacy048GameEventSchema,
  Legacy048InventoryItemSchema,
  Legacy048SaveDataSchema,
  Legacy048TechniqueSchema,
  Legacy048DurableActivityCombatRunSchema,
  Legacy048BossMemorySchema,
  Legacy048BossGauntletRunSchema,
  Legacy048EncounterProgressSchema,
  Legacy048ExpeditionMilestoneRecordSchema,
  Legacy048ExpeditionRunSchema,
  Legacy048NpcRelationSchema,
  Legacy048ReputationSchema,
  Legacy048MainlineProgressSchema,
  Legacy048MainlineSettlementJournalSchema,
  Legacy048ProgressiveUnlockReceiptSchema,
  Legacy048PvpRecordSchema,
  Legacy048PvpSnapshotSchema,
  Legacy048RewardClaimReceiptSchema,
  Legacy048RetreatSessionSchema,
  Legacy048SectSchema,
  Legacy048SectEventSchema,
  Legacy048TowerPersonalRecordSchema,
  Legacy048TowerProgressSchema,
  Legacy048EquipmentCatalogEntrySchema,
];

Future<void> seedLegacyNumericRows(Isar db, {int slotId = 1}) async {
  await db.writeTxn(() async {
    await db.collection<Legacy048Character>().put(Legacy048Character());
    await db.collection<Legacy048Equipment>().put(Legacy048Equipment());
    await db.collection<Legacy048GameEvent>().put(Legacy048GameEvent());
    await db.collection<Legacy048InventoryItem>().put(Legacy048InventoryItem());
    await db.collection<Legacy048SaveData>().put(
      Legacy048SaveData()..slotId = slotId,
    );
    await db.collection<Legacy048Technique>().put(Legacy048Technique());
    await db.collection<Legacy048DurableActivityCombatRun>().put(
      Legacy048DurableActivityCombatRun(),
    );
    await db.collection<Legacy048BossMemory>().put(Legacy048BossMemory());
    await db.collection<Legacy048BossGauntletRun>().put(
      Legacy048BossGauntletRun(),
    );
    await db.collection<Legacy048EncounterProgress>().put(
      Legacy048EncounterProgress(),
    );
    await db.collection<Legacy048ExpeditionMilestoneRecord>().put(
      Legacy048ExpeditionMilestoneRecord(),
    );
    await db.collection<Legacy048ExpeditionRun>().put(Legacy048ExpeditionRun());
    await db.collection<Legacy048NpcRelation>().put(Legacy048NpcRelation());
    await db.collection<Legacy048Reputation>().put(Legacy048Reputation());
    await db.collection<Legacy048MainlineProgress>().put(
      Legacy048MainlineProgress(),
    );
    await db.collection<Legacy048MainlineSettlementJournal>().put(
      Legacy048MainlineSettlementJournal(),
    );
    await db.collection<Legacy048ProgressiveUnlockReceipt>().put(
      Legacy048ProgressiveUnlockReceipt(),
    );
    await db.collection<Legacy048PvpRecord>().put(Legacy048PvpRecord());
    await db.collection<Legacy048PvpSnapshot>().put(Legacy048PvpSnapshot());
    await db.collection<Legacy048RewardClaimReceipt>().put(
      Legacy048RewardClaimReceipt(),
    );
    await db.collection<Legacy048RetreatSession>().put(
      Legacy048RetreatSession(),
    );
    await db.collection<Legacy048Sect>().put(Legacy048Sect());
    await db.collection<Legacy048SectEvent>().put(Legacy048SectEvent());
    await db.collection<Legacy048TowerPersonalRecord>().put(
      Legacy048TowerPersonalRecord(),
    );
    await db.collection<Legacy048TowerProgress>().put(Legacy048TowerProgress());
    await db.collection<Legacy048EquipmentCatalogEntry>().put(
      Legacy048EquipmentCatalogEntry(),
    );
  });
}
