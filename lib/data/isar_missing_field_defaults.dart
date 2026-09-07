import 'package:isar_community/isar.dart';
import '../core/domain/character.dart';
import '../core/domain/equipment.dart';
import '../core/domain/forging_slot.dart';
import '../core/domain/inventory_item.dart';
import '../core/domain/island_building_state.dart';
import '../core/domain/reward_entry.dart';
import '../core/domain/save_data.dart';
import '../core/domain/skill_unlock_entry.dart';
import '../core/domain/skill_usage_entry.dart';
import '../core/domain/technique.dart';
import '../features/activity/domain/activity_member_snapshot.dart';
import '../features/activity/domain/durable_activity_combat_run.dart';
import '../features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import '../features/encounter/domain/encounter_progress.dart';
import '../features/expedition/domain/expedition_milestone_record.dart';
import '../features/expedition/domain/expedition_run.dart';
import '../features/mainline/domain/mainline_progress.dart';
import '../features/progressive_unlock/domain/progressive_unlock_receipt.dart';
import '../features/reward/domain/reward_claim_receipt.dart';
import '../features/seclusion/domain/retreat_session.dart';
import '../features/tower/domain/tower_personal_record.dart';
import '../features/tower/domain/tower_progress.dart';

/// Exact missing-property normalization for save version 0.48.0.
/// Call only inside the selected database transaction. No IDs or history are inferred.
abstract final class IsarMissingFieldDefaults {
  static const missingLong = -9223372036854775808;

  static const repairedFields = <String>{
    'ActivityMemberSnapshot.currentHp',
    'ActivityMemberSnapshot.currentQi',
    'ActivityMemberSnapshot.maxHp',
    'ActivityMemberSnapshot.maxQi',
    'BiomeMinutes.minutes',
    'BossGauntletRun.currentStage',
    'BossGauntletRun.cycleIndex',
    'Character.attributeBonusFromAdventure',
    'Character.birthInGameYear',
    'Character.experience',
    'Character.experienceToNextLayer',
    'Character.injuryHoursRemaining',
    'Character.innerBreathDisorderHoursRemaining',
    'Character.innerDemonResidueHoursRemaining',
    'Character.insightPoints',
    'Character.internalForce',
    'Character.level',
    'Character.levelExp',
    'Character.lightInjuryStacks',
    'EncounterProgress.attributeGainsAgility',
    'EncounterProgress.attributeGainsConstitution',
    'EncounterProgress.attributeGainsEnlightenment',
    'EncounterProgress.attributeGainsFortune',
    'Equipment.baseAttack',
    'Equipment.baseHealth',
    'Equipment.baseSpeed',
    'Equipment.battleCount',
    'Equipment.enhanceLevel',
    'ExpeditionMilestoneRecord.cycleIndex',
    'ExpeditionMilestoneRecord.recordVersion',
    'ExpeditionRun.currentNode',
    'ExpeditionRun.cycleIndex',
    'ForgingSlot.bonusValue',
    'InventoryItem.quantity',
    'IslandBuildingState.level',
    'IslandBuildingState.stored',
    'MainlineProgress.currentChapterIndex',
    'ProgressiveUnlockReceipt.receiptVersion',
    'RetreatSession.durationHours',
    'RewardClaimReceipt.receiptVersion',
    'RewardEntry.quantity',
    'SaveData.baicaoMaxDepth',
    'SaveData.duanhunClearedCyclesMax',
    'SaveData.expeditionRunSerial',
    'SaveData.gauntletRunSerial',
    'SaveData.highestTowerLayer',
    'SaveData.totalPassiveExperience',
    'SaveData.totalPassiveMojianshi',
    'SaveData.totalPlaySeconds',
    'SaveData.tutorialStep',
    'SchoolKillCount.count',
    'SkillUnlockEntry.fragmentCount',
    'SkillUsageEntry.count',
    'Technique.cultivationProgress',
    'TowerPersonalRecord.highestClearedFloor',
    'TowerPersonalRecord.recordVersion',
    'TowerProgress.currentCycleIndex',
    'TowerProgress.highestClearedFloor',
    'TowerProgress.maxClearedCycle',
    'TowerProgress.totalAttempts',
    'TowerProgress.totalDefeats',
    'WeatherMinutes.minutes',
  };

  static const deferredNumericFields = <String, String>{
    'ActivityMemberSnapshot.characterId':
        'Participant identity cannot be inferred from placeholder 0.',
    'Attributes.agility':
        'Birth attribute must not be invented from placeholder 5.',
    'Attributes.constitution':
        'Birth attribute must not be invented from placeholder 5.',
    'Attributes.enlightenment':
        'Birth attribute must not be invented from placeholder 5.',
    'Attributes.fortune':
        'Birth attribute must not be invented from placeholder 5.',
    'BossGauntletRun.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'BossGauntletRun.seed':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'BossMemory.defeatCount':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'BossMemory.groupIndex':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'BossMemory.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'Character.internalForceMax':
        'Realm-dependent maximum; placeholder 500 is not the historical maximum.',
    'DurableActivityCombatRun.cycleIndex':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'DurableActivityCombatRun.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'DurableActivityCombatRun.seed':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'EncounterProgress.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'EquipmentCatalogEntry.obtainedCount':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'EquipmentCatalogEntry.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'ExpeditionMilestoneRecord.nodeIndex':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'ExpeditionMilestoneRecord.nodeSeed':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'ExpeditionMilestoneRecord.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'ExpeditionMilestoneRecord.sourceParticipantId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'ExpeditionMilestoneRecord.sourceRunId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'ExpeditionRun.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'ExpeditionRun.seed':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'ForgingSlot.slotIndex':
        'Slot identity cannot be inferred from placeholder 1.',
    'MainlineProgress.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'MainlineSettlementJournal.loadoutVersion':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'MainlineSettlementJournal.participantId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'MainlineSettlementJournal.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'NpcRelation.level':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'NpcRelation.sourceCharacterId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'NpcRelation.targetCharacterId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'ProgressiveUnlockReceipt.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'PvpRecord.eloDelta':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'PvpRecord.leftSnapshotId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'PvpRecord.opponentSnapshotId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'PvpRecord.playerEloAfter':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'PvpRecord.playerEloBefore':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'PvpRecord.playerId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'PvpSnapshot.snapshotElo':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'Reputation.playerId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'Reputation.value':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'RetreatSession.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'RewardClaimReceipt.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'SaveData.slotId': 'Slot identity; static 1 cannot identify slot 2 or 3.',
    'Sect.founderId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'Sect.memberCount':
        'Existing membership is not reconstructed by placeholder 0.',
    'Sect.sectLevel':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'Sect.sectReputation':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'Sect.totalWins':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'SectEvent.sectId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'Technique.cultivationProgressToNext':
        'Live cultivation threshold depends on the historical layer.',
    'Technique.ownerCharacterId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'TowerPersonalRecord.participantId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'TowerPersonalRecord.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
    'TowerProgress.saveDataId':
        'No Dart initializer; identity, seed or historical data cannot be invented.',
  };

  static const deferredNonNumericFields = <String, String>{
    'Character.isAlive': 'False can mean a legitimately dead character.',
    'Lore.isPreset': 'False is used for actual player-created lore.',
    'Lore.addedAt':
        'Epoch is not distinguishable from a persisted timestamp; 2000 is a placeholder.',
    'Character.rarity': 'The first enum value is a legitimate birth rarity.',
    'BiomeMinutes.biome':
        'The first enum value is a legitimate biome identity.',
  };

  /// Older segments consume these rows before the final 0.48 segment.
  static Future<void> prepareLegacyInputsInTxn(Isar isar) async {
    await _repairRows(isar.collection<Character>(), _repairCharacter);
    await _repairRows(isar.collection<TowerProgress>(), _repairTowerProgress);
  }

  /// Final segment re-reads current rows, preserving writes from earlier segments.
  static Future<void> repairInTxn(Isar isar, SaveData save) async {
    _repairSaveData(save);
    await _repairRows(isar.collection<Character>(), _repairCharacter);
    await _repairRows(isar.collection<Equipment>(), _repairEquipment);
    await _repairRows(isar.collection<InventoryItem>(), _repairInventoryItem);
    await _repairRows(isar.collection<Technique>(), _repairTechnique);
    await _repairRows(
      isar.collection<DurableActivityCombatRun>(),
      _repairDurableActivityCombatRun,
    );
    await _repairRows(
      isar.collection<BossGauntletRun>(),
      _repairBossGauntletRun,
    );
    await _repairRows(
      isar.collection<EncounterProgress>(),
      _repairEncounterProgress,
    );
    await _repairRows(
      isar.collection<ExpeditionMilestoneRecord>(),
      _repairExpeditionMilestoneRecord,
    );
    await _repairRows(isar.collection<ExpeditionRun>(), _repairExpeditionRun);
    await _repairRows(
      isar.collection<MainlineProgress>(),
      _repairMainlineProgress,
    );
    await _repairRows(
      isar.collection<ProgressiveUnlockReceipt>(),
      _repairProgressiveUnlockReceipt,
    );
    await _repairRows(
      isar.collection<RewardClaimReceipt>(),
      _repairRewardClaimReceipt,
    );
    await _repairRows(isar.collection<RetreatSession>(), _repairRetreatSession);
    await _repairRows(
      isar.collection<TowerPersonalRecord>(),
      _repairTowerPersonalRecord,
    );
    await _repairRows(isar.collection<TowerProgress>(), _repairTowerProgress);
  }

  static Future<void> _repairRows<T>(
    IsarCollection<T> collection,
    bool Function(T) repair,
  ) async {
    for (final row in await collection.where().findAll()) {
      if (repair(row)) await collection.put(row);
    }
  }

  static bool _repairCharacter(Character row) {
    var changed = false;
    final defaults = Character();
    if (row.internalForce == missingLong) {
      row.internalForce = defaults.internalForce;
      changed = true;
    }
    if (row.innerBreathDisorderHoursRemaining.isNaN) {
      row.innerBreathDisorderHoursRemaining =
          defaults.innerBreathDisorderHoursRemaining;
      changed = true;
    }
    if (row.innerDemonResidueHoursRemaining.isNaN) {
      row.innerDemonResidueHoursRemaining =
          defaults.innerDemonResidueHoursRemaining;
      changed = true;
    }
    if (row.lightInjuryStacks == missingLong) {
      row.lightInjuryStacks = defaults.lightInjuryStacks;
      changed = true;
    }
    if (row.injuryHoursRemaining.isNaN) {
      row.injuryHoursRemaining = defaults.injuryHoursRemaining;
      changed = true;
    }
    if (row.experience == missingLong) {
      row.experience = defaults.experience;
      changed = true;
    }
    if (row.experienceToNextLayer == missingLong) {
      row.experienceToNextLayer = defaults.experienceToNextLayer;
      changed = true;
    }
    if (row.level == missingLong) {
      row.level = defaults.level;
      changed = true;
    }
    if (row.levelExp == missingLong) {
      row.levelExp = defaults.levelExp;
      changed = true;
    }
    if (row.insightPoints == missingLong) {
      row.insightPoints = defaults.insightPoints;
      changed = true;
    }
    if (row.birthInGameYear == missingLong) {
      row.birthInGameYear = defaults.birthInGameYear;
      changed = true;
    }
    if (row.attributeBonusFromAdventure == missingLong) {
      row.attributeBonusFromAdventure = defaults.attributeBonusFromAdventure;
      changed = true;
    }
    return changed;
  }

  static bool _repairEquipment(Equipment row) {
    var changed = false;
    final defaults = Equipment();
    if (row.baseAttack == missingLong) {
      row.baseAttack = defaults.baseAttack;
      changed = true;
    }
    if (row.baseHealth == missingLong) {
      row.baseHealth = defaults.baseHealth;
      changed = true;
    }
    if (row.baseSpeed == missingLong) {
      row.baseSpeed = defaults.baseSpeed;
      changed = true;
    }
    if (row.enhanceLevel == missingLong) {
      row.enhanceLevel = defaults.enhanceLevel;
      changed = true;
    }
    if (row.battleCount == missingLong) {
      row.battleCount = defaults.battleCount;
      changed = true;
    }
    for (final entry in row.forgingSlots) {
      if (_repairForgingSlot(entry)) changed = true;
    }
    return changed;
  }

  static bool _repairForgingSlot(ForgingSlot row) {
    var changed = false;
    final defaults = ForgingSlot();
    if (row.bonusValue == missingLong) {
      row.bonusValue = defaults.bonusValue;
      changed = true;
    }
    return changed;
  }

  static bool _repairInventoryItem(InventoryItem row) {
    var changed = false;
    final defaults = InventoryItem();
    if (row.quantity == missingLong) {
      row.quantity = defaults.quantity;
      changed = true;
    }
    return changed;
  }

  static bool _repairIslandBuildingState(IslandBuildingState row) {
    var changed = false;
    final defaults = IslandBuildingState();
    if (row.level == missingLong) {
      row.level = defaults.level;
      changed = true;
    }
    if (row.stored.isNaN) {
      row.stored = defaults.stored;
      changed = true;
    }
    return changed;
  }

  static bool _repairRewardEntry(RewardEntry row) {
    var changed = false;
    final defaults = RewardEntry();
    if (row.quantity == missingLong) {
      row.quantity = defaults.quantity;
      changed = true;
    }
    return changed;
  }

  static bool _repairSaveData(SaveData row) {
    var changed = false;
    final defaults = SaveData();
    if (row.totalPlaySeconds == missingLong) {
      row.totalPlaySeconds = defaults.totalPlaySeconds;
      changed = true;
    }
    if (row.highestTowerLayer == missingLong) {
      row.highestTowerLayer = defaults.highestTowerLayer;
      changed = true;
    }
    if (row.tutorialStep == missingLong) {
      row.tutorialStep = defaults.tutorialStep;
      changed = true;
    }
    if (row.totalPassiveMojianshi == missingLong) {
      row.totalPassiveMojianshi = defaults.totalPassiveMojianshi;
      changed = true;
    }
    if (row.totalPassiveExperience == missingLong) {
      row.totalPassiveExperience = defaults.totalPassiveExperience;
      changed = true;
    }
    if (row.baicaoMaxDepth == missingLong) {
      row.baicaoMaxDepth = defaults.baicaoMaxDepth;
      changed = true;
    }
    if (row.expeditionRunSerial == missingLong) {
      row.expeditionRunSerial = defaults.expeditionRunSerial;
      changed = true;
    }
    if (row.gauntletRunSerial == missingLong) {
      row.gauntletRunSerial = defaults.gauntletRunSerial;
      changed = true;
    }
    if (row.duanhunClearedCyclesMax == missingLong) {
      row.duanhunClearedCyclesMax = defaults.duanhunClearedCyclesMax;
      changed = true;
    }
    for (final entry in row.skillUnlockProgress) {
      if (_repairSkillUnlockEntry(entry)) changed = true;
    }
    for (final entry in row.islandBuildings) {
      if (_repairIslandBuildingState(entry)) changed = true;
    }
    return changed;
  }

  static bool _repairSkillUnlockEntry(SkillUnlockEntry row) {
    var changed = false;
    final defaults = SkillUnlockEntry();
    if (row.fragmentCount == missingLong) {
      row.fragmentCount = defaults.fragmentCount;
      changed = true;
    }
    return changed;
  }

  static bool _repairSkillUsageEntry(SkillUsageEntry row) {
    var changed = false;
    final defaults = SkillUsageEntry();
    if (row.count == missingLong) {
      row.count = defaults.count;
      changed = true;
    }
    return changed;
  }

  static bool _repairTechnique(Technique row) {
    var changed = false;
    final defaults = Technique();
    if (row.cultivationProgress == missingLong) {
      row.cultivationProgress = defaults.cultivationProgress;
      changed = true;
    }
    for (final entry in row.skillUsageCount) {
      if (_repairSkillUsageEntry(entry)) changed = true;
    }
    return changed;
  }

  static bool _repairActivityMemberSnapshot(ActivityMemberSnapshot row) {
    var changed = false;
    final defaults = ActivityMemberSnapshot();
    if (row.currentHp == missingLong) {
      row.currentHp = defaults.currentHp;
      changed = true;
    }
    if (row.currentQi == missingLong) {
      row.currentQi = defaults.currentQi;
      changed = true;
    }
    if (row.maxHp == missingLong) {
      row.maxHp = defaults.maxHp;
      changed = true;
    }
    if (row.maxQi == missingLong) {
      row.maxQi = defaults.maxQi;
      changed = true;
    }
    return changed;
  }

  static bool _repairDurableActivityCombatRun(DurableActivityCombatRun row) {
    var changed = false;
    for (final entry in row.members) {
      if (_repairActivityMemberSnapshot(entry)) changed = true;
    }
    return changed;
  }

  static bool _repairBossGauntletRun(BossGauntletRun row) {
    var changed = false;
    final defaults = BossGauntletRun();
    if (row.currentStage == missingLong) {
      row.currentStage = defaults.currentStage;
      changed = true;
    }
    if (row.cycleIndex == missingLong) {
      row.cycleIndex = defaults.cycleIndex;
      changed = true;
    }
    for (final entry in row.members) {
      if (_repairActivityMemberSnapshot(entry)) changed = true;
    }
    for (final entry in row.stagedRewards) {
      if (_repairRewardEntry(entry)) changed = true;
    }
    return changed;
  }

  static bool _repairEncounterProgress(EncounterProgress row) {
    var changed = false;
    final defaults = EncounterProgress();
    if (row.attributeGainsConstitution == missingLong) {
      row.attributeGainsConstitution = defaults.attributeGainsConstitution;
      changed = true;
    }
    if (row.attributeGainsEnlightenment == missingLong) {
      row.attributeGainsEnlightenment = defaults.attributeGainsEnlightenment;
      changed = true;
    }
    if (row.attributeGainsAgility == missingLong) {
      row.attributeGainsAgility = defaults.attributeGainsAgility;
      changed = true;
    }
    if (row.attributeGainsFortune == missingLong) {
      row.attributeGainsFortune = defaults.attributeGainsFortune;
      changed = true;
    }
    for (final entry in row.schoolKillCounts) {
      if (_repairSchoolKillCount(entry)) changed = true;
    }
    for (final entry in row.biomeMinutes) {
      if (_repairBiomeMinutes(entry)) changed = true;
    }
    for (final entry in row.weatherMinutes) {
      if (_repairWeatherMinutes(entry)) changed = true;
    }
    return changed;
  }

  static bool _repairSchoolKillCount(SchoolKillCount row) {
    var changed = false;
    final defaults = SchoolKillCount();
    if (row.count == missingLong) {
      row.count = defaults.count;
      changed = true;
    }
    return changed;
  }

  static bool _repairBiomeMinutes(BiomeMinutes row) {
    var changed = false;
    final defaults = BiomeMinutes();
    if (row.minutes == missingLong) {
      row.minutes = defaults.minutes;
      changed = true;
    }
    return changed;
  }

  static bool _repairWeatherMinutes(WeatherMinutes row) {
    var changed = false;
    final defaults = WeatherMinutes();
    if (row.minutes == missingLong) {
      row.minutes = defaults.minutes;
      changed = true;
    }
    return changed;
  }

  static bool _repairExpeditionMilestoneRecord(ExpeditionMilestoneRecord row) {
    var changed = false;
    final defaults = ExpeditionMilestoneRecord();
    if (row.recordVersion == missingLong) {
      row.recordVersion = defaults.recordVersion;
      changed = true;
    }
    if (row.cycleIndex == missingLong) {
      row.cycleIndex = defaults.cycleIndex;
      changed = true;
    }
    return changed;
  }

  static bool _repairExpeditionRun(ExpeditionRun row) {
    var changed = false;
    final defaults = ExpeditionRun();
    if (row.currentNode == missingLong) {
      row.currentNode = defaults.currentNode;
      changed = true;
    }
    if (row.cycleIndex == missingLong) {
      row.cycleIndex = defaults.cycleIndex;
      changed = true;
    }
    for (final entry in row.members) {
      if (_repairActivityMemberSnapshot(entry)) changed = true;
    }
    for (final entry in row.stagedRewards) {
      if (_repairRewardEntry(entry)) changed = true;
    }
    return changed;
  }

  static bool _repairMainlineProgress(MainlineProgress row) {
    var changed = false;
    final defaults = MainlineProgress();
    if (row.currentChapterIndex == missingLong) {
      row.currentChapterIndex = defaults.currentChapterIndex;
      changed = true;
    }
    return changed;
  }

  static bool _repairProgressiveUnlockReceipt(ProgressiveUnlockReceipt row) {
    var changed = false;
    final defaults = ProgressiveUnlockReceipt();
    if (row.receiptVersion == missingLong) {
      row.receiptVersion = defaults.receiptVersion;
      changed = true;
    }
    return changed;
  }

  static bool _repairRewardClaimReceipt(RewardClaimReceipt row) {
    var changed = false;
    final defaults = RewardClaimReceipt();
    if (row.receiptVersion == missingLong) {
      row.receiptVersion = defaults.receiptVersion;
      changed = true;
    }
    return changed;
  }

  static bool _repairRetreatSession(RetreatSession row) {
    var changed = false;
    final defaults = RetreatSession();
    if (row.durationHours == missingLong) {
      row.durationHours = defaults.durationHours;
      changed = true;
    }
    for (final entry in row.actualRewards) {
      if (_repairRewardEntry(entry)) changed = true;
    }
    return changed;
  }

  static bool _repairTowerPersonalRecord(TowerPersonalRecord row) {
    var changed = false;
    final defaults = TowerPersonalRecord();
    if (row.recordVersion == missingLong) {
      row.recordVersion = defaults.recordVersion;
      changed = true;
    }
    if (row.highestClearedFloor == missingLong) {
      row.highestClearedFloor = defaults.highestClearedFloor;
      changed = true;
    }
    return changed;
  }

  static bool _repairTowerProgress(TowerProgress row) {
    var changed = false;
    final defaults = TowerProgress();
    if (row.highestClearedFloor == missingLong) {
      row.highestClearedFloor = defaults.highestClearedFloor;
      changed = true;
    }
    if (row.totalAttempts == missingLong) {
      row.totalAttempts = defaults.totalAttempts;
      changed = true;
    }
    if (row.totalDefeats == missingLong) {
      row.totalDefeats = defaults.totalDefeats;
      changed = true;
    }
    if (row.currentCycleIndex == missingLong) {
      row.currentCycleIndex = defaults.currentCycleIndex;
      changed = true;
    }
    if (row.maxClearedCycle == missingLong) {
      row.maxClearedCycle = defaults.maxClearedCycle;
      changed = true;
    }
    return changed;
  }
}
