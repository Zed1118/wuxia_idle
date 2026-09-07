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
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 9e55c268695333242e93e90f98eb70dbc459efcd; '
        'field: 9e55c268695333242e93e90f98eb70dbc459efcd.',
    'Attributes.agility':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 1aeb94c593814ecaa873c8f36700a78b7a1aa945; '
        'field: 1aeb94c593814ecaa873c8f36700a78b7a1aa945.',
    'Attributes.constitution':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 1aeb94c593814ecaa873c8f36700a78b7a1aa945; '
        'field: 1aeb94c593814ecaa873c8f36700a78b7a1aa945.',
    'Attributes.enlightenment':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 1aeb94c593814ecaa873c8f36700a78b7a1aa945; '
        'field: 1aeb94c593814ecaa873c8f36700a78b7a1aa945.',
    'Attributes.fortune':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 1aeb94c593814ecaa873c8f36700a78b7a1aa945; '
        'field: 1aeb94c593814ecaa873c8f36700a78b7a1aa945.',
    'BossGauntletRun.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 7a06a2abaab9749629ed471685dc76b503cc5531; '
        'field: 7a06a2abaab9749629ed471685dc76b503cc5531.',
    'BossGauntletRun.seed':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 7a06a2abaab9749629ed471685dc76b503cc5531; '
        'field: 7a06a2abaab9749629ed471685dc76b503cc5531.',
    'BossMemory.defeatCount':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: bdee80d577e6563be4d01e64bfc89ee46ccd57e8; '
        'field: bdee80d577e6563be4d01e64bfc89ee46ccd57e8.',
    'BossMemory.groupIndex':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: bdee80d577e6563be4d01e64bfc89ee46ccd57e8; '
        'field: bdee80d577e6563be4d01e64bfc89ee46ccd57e8.',
    'BossMemory.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: bdee80d577e6563be4d01e64bfc89ee46ccd57e8; '
        'field: bdee80d577e6563be4d01e64bfc89ee46ccd57e8.',
    'Character.internalForceMax':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 549991ec8b2146e5cfac898c04078314cda82181; '
        'field: 549991ec8b2146e5cfac898c04078314cda82181.',
    'DurableActivityCombatRun.cycleIndex':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: fedad8812b81f10b44d2fca02b71bcfc0975c0fb; '
        'field: fedad8812b81f10b44d2fca02b71bcfc0975c0fb.',
    'DurableActivityCombatRun.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: fedad8812b81f10b44d2fca02b71bcfc0975c0fb; '
        'field: fedad8812b81f10b44d2fca02b71bcfc0975c0fb.',
    'DurableActivityCombatRun.seed':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: fedad8812b81f10b44d2fca02b71bcfc0975c0fb; '
        'field: fedad8812b81f10b44d2fca02b71bcfc0975c0fb.',
    'EncounterProgress.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 1027431d6eff64f0e3d5f8c026bd3a669c284440; '
        'field: 1027431d6eff64f0e3d5f8c026bd3a669c284440.',
    'EquipmentCatalogEntry.obtainedCount':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: a150a93018a0c7418117b26c67f6bbe39806e691; '
        'field: a150a93018a0c7418117b26c67f6bbe39806e691.',
    'EquipmentCatalogEntry.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: a150a93018a0c7418117b26c67f6bbe39806e691; '
        'field: a150a93018a0c7418117b26c67f6bbe39806e691.',
    'ExpeditionMilestoneRecord.nodeIndex':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 80d95a1415c73f168786836a7de28eb474f32e08; '
        'field: 80d95a1415c73f168786836a7de28eb474f32e08.',
    'ExpeditionMilestoneRecord.nodeSeed':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 80d95a1415c73f168786836a7de28eb474f32e08; '
        'field: 80d95a1415c73f168786836a7de28eb474f32e08.',
    'ExpeditionMilestoneRecord.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 80d95a1415c73f168786836a7de28eb474f32e08; '
        'field: 80d95a1415c73f168786836a7de28eb474f32e08.',
    'ExpeditionMilestoneRecord.sourceParticipantId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 80d95a1415c73f168786836a7de28eb474f32e08; '
        'field: 80d95a1415c73f168786836a7de28eb474f32e08.',
    'ExpeditionMilestoneRecord.sourceRunId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 80d95a1415c73f168786836a7de28eb474f32e08; '
        'field: 80d95a1415c73f168786836a7de28eb474f32e08.',
    'ExpeditionRun.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 2726b63fb63f6f15217c9de0bf65042daf13eea8; '
        'field: 2726b63fb63f6f15217c9de0bf65042daf13eea8.',
    'ExpeditionRun.seed':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 2726b63fb63f6f15217c9de0bf65042daf13eea8; '
        'field: 2726b63fb63f6f15217c9de0bf65042daf13eea8.',
    'ForgingSlot.slotIndex':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 1aeb94c593814ecaa873c8f36700a78b7a1aa945; '
        'field: 1aeb94c593814ecaa873c8f36700a78b7a1aa945.',
    'MainlineProgress.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 0f97327ca586fad3c651a4569a830bff7be9f0d8; '
        'field: 0f97327ca586fad3c651a4569a830bff7be9f0d8.',
    'MainlineSettlementJournal.loadoutVersion':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 6d9902600fbb076b3e344fb9710a9209c9fe1a55; '
        'field: 6d9902600fbb076b3e344fb9710a9209c9fe1a55.',
    'MainlineSettlementJournal.participantId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 6d9902600fbb076b3e344fb9710a9209c9fe1a55; '
        'field: 6d9902600fbb076b3e344fb9710a9209c9fe1a55.',
    'MainlineSettlementJournal.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 6d9902600fbb076b3e344fb9710a9209c9fe1a55; '
        'field: 6d9902600fbb076b3e344fb9710a9209c9fe1a55.',
    'NpcRelation.level':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 7c88ed2c00eb88ef7ef43606cb602b1c3b65abec; '
        'field: 7c88ed2c00eb88ef7ef43606cb602b1c3b65abec.',
    'NpcRelation.sourceCharacterId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 7c88ed2c00eb88ef7ef43606cb602b1c3b65abec; '
        'field: 7c88ed2c00eb88ef7ef43606cb602b1c3b65abec.',
    'NpcRelation.targetCharacterId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 7c88ed2c00eb88ef7ef43606cb602b1c3b65abec; '
        'field: 7c88ed2c00eb88ef7ef43606cb602b1c3b65abec.',
    'ProgressiveUnlockReceipt.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 05727c830763dee29e5b41dd54b8025ab1354660; '
        'field: 05727c830763dee29e5b41dd54b8025ab1354660.',
    'PvpRecord.eloDelta':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: a90282ee0b81edb46db35e18cb30b79f199b8248; '
        'field: a90282ee0b81edb46db35e18cb30b79f199b8248.',
    'PvpRecord.leftSnapshotId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: a90282ee0b81edb46db35e18cb30b79f199b8248; '
        'field: a90282ee0b81edb46db35e18cb30b79f199b8248.',
    'PvpRecord.opponentSnapshotId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: a90282ee0b81edb46db35e18cb30b79f199b8248; '
        'field: a90282ee0b81edb46db35e18cb30b79f199b8248.',
    'PvpRecord.playerEloAfter':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: a90282ee0b81edb46db35e18cb30b79f199b8248; '
        'field: a90282ee0b81edb46db35e18cb30b79f199b8248.',
    'PvpRecord.playerEloBefore':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: a90282ee0b81edb46db35e18cb30b79f199b8248; '
        'field: a90282ee0b81edb46db35e18cb30b79f199b8248.',
    'PvpRecord.playerId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: a90282ee0b81edb46db35e18cb30b79f199b8248; '
        'field: a90282ee0b81edb46db35e18cb30b79f199b8248.',
    'PvpSnapshot.snapshotElo':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: a90282ee0b81edb46db35e18cb30b79f199b8248; '
        'field: a90282ee0b81edb46db35e18cb30b79f199b8248.',
    'Reputation.playerId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 7c88ed2c00eb88ef7ef43606cb602b1c3b65abec; '
        'field: 7c88ed2c00eb88ef7ef43606cb602b1c3b65abec.',
    'Reputation.value':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 7c88ed2c00eb88ef7ef43606cb602b1c3b65abec; '
        'field: 7c88ed2c00eb88ef7ef43606cb602b1c3b65abec.',
    'RetreatSession.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 091c51f370e89b2dda7b50b5fddec2ecc5295c9c; '
        'field: 091c51f370e89b2dda7b50b5fddec2ecc5295c9c.',
    'RewardClaimReceipt.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: d2c5185fa307c065fdf67a981e51637fee5de1cd; '
        'field: d2c5185fa307c065fdf67a981e51637fee5de1cd.',
    'SaveData.slotId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 549991ec8b2146e5cfac898c04078314cda82181; '
        'field: 549991ec8b2146e5cfac898c04078314cda82181.',
    'Sect.founderId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 0dff1f667f7ce80e5396e9b8140b7f55fc5632d2; '
        'field: 0dff1f667f7ce80e5396e9b8140b7f55fc5632d2.',
    'Sect.memberCount':
        'B: entity introduced at 0dff1f667f7ce80e5396e9b8140b7f55fc5632d2; '
        'field added at 5378c2a3f10eaf92fd4af2dcee254eff002e6474. '
        'Approved 1A: SectMemberCountRepair (0.49.0) rebuilds negative caches '
        'from verified membership; ambiguous rows remain unchanged and reported.',
    'Sect.sectLevel':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 0dff1f667f7ce80e5396e9b8140b7f55fc5632d2; '
        'field: 0dff1f667f7ce80e5396e9b8140b7f55fc5632d2.',
    'Sect.sectReputation':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 0dff1f667f7ce80e5396e9b8140b7f55fc5632d2; '
        'field: 0dff1f667f7ce80e5396e9b8140b7f55fc5632d2.',
    'Sect.totalWins':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 0dff1f667f7ce80e5396e9b8140b7f55fc5632d2; '
        'field: 0dff1f667f7ce80e5396e9b8140b7f55fc5632d2.',
    'SectEvent.sectId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 0dff1f667f7ce80e5396e9b8140b7f55fc5632d2; '
        'field: 0dff1f667f7ce80e5396e9b8140b7f55fc5632d2.',
    'Technique.cultivationProgressToNext':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 549991ec8b2146e5cfac898c04078314cda82181; '
        'field: 549991ec8b2146e5cfac898c04078314cda82181.',
    'Technique.ownerCharacterId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 549991ec8b2146e5cfac898c04078314cda82181; '
        'field: 549991ec8b2146e5cfac898c04078314cda82181.',
    'TowerPersonalRecord.participantId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: a04567dbb541f8db1a23417aab91a5bb31f273cf; '
        'field: a04567dbb541f8db1a23417aab91a5bb31f273cf.',
    'TowerPersonalRecord.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: a04567dbb541f8db1a23417aab91a5bb31f273cf; '
        'field: a04567dbb541f8db1a23417aab91a5bb31f273cf.',
    'TowerProgress.saveDataId':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 71a78d4889b5632a049e34fdca0e8192db52f2eb; '
        'field: 71a78d4889b5632a049e34fdca0e8192db52f2eb.',
  };

  static const deferredNonNumericFields = <String, String>{
    'Character.isAlive':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 549991ec8b2146e5cfac898c04078314cda82181; '
        'field: 549991ec8b2146e5cfac898c04078314cda82181.',
    'Lore.isPreset':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 1aeb94c593814ecaa873c8f36700a78b7a1aa945; '
        'field: 1aeb94c593814ecaa873c8f36700a78b7a1aa945.',
    'Lore.addedAt':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 1aeb94c593814ecaa873c8f36700a78b7a1aa945; '
        'field: 1aeb94c593814ecaa873c8f36700a78b7a1aa945.',
    'Character.rarity':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: 549991ec8b2146e5cfac898c04078314cda82181; '
        'field: 549991ec8b2146e5cfac898c04078314cda82181.',
    'BiomeMinutes.biome':
        'A: entity and field introduced together; no missing-field exposure. '
        'Entity: e08c8e7068f15a715223c1046135b02c2def8634; '
        'field: e08c8e7068f15a715223c1046135b02c2def8634.',
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
