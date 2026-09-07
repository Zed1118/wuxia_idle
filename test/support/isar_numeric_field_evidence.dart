import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/island_building_state.dart';
import 'package:wuxia_idle/core/domain/reward_entry.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';
import 'package:wuxia_idle/core/domain/skill_usage_entry.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_progress.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock_receipt.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/tower/domain/tower_personal_record.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

final class NumericFieldEvidence {
  const NumericFieldEvidence(
    this.key,
    this.rootSchema,
    this.path,
    this.isDouble,
    this.defaultValue,
    this.read,
    this.write,
  );
  final String key;
  final String rootSchema;
  final List<String> path;
  final bool isDouble;
  final num Function() defaultValue;
  final Future<List<num>> Function(Isar) read;
  final Future<void> Function(Isar, num) write;
}

final numericFieldEvidence = <NumericFieldEvidence>[
  NumericFieldEvidence(
    'Character.internalForce',
    'Character',
    ['internalForce'],
    false,
    () => Character().internalForce,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.internalForce];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.internalForce = value.toInt();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Character.innerBreathDisorderHoursRemaining',
    'Character',
    ['innerBreathDisorderHoursRemaining'],
    true,
    () => Character().innerBreathDisorderHoursRemaining,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.innerBreathDisorderHoursRemaining];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.innerBreathDisorderHoursRemaining = value.toDouble();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Character.innerDemonResidueHoursRemaining',
    'Character',
    ['innerDemonResidueHoursRemaining'],
    true,
    () => Character().innerDemonResidueHoursRemaining,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.innerDemonResidueHoursRemaining];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.innerDemonResidueHoursRemaining = value.toDouble();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Character.lightInjuryStacks',
    'Character',
    ['lightInjuryStacks'],
    false,
    () => Character().lightInjuryStacks,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.lightInjuryStacks];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.lightInjuryStacks = value.toInt();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Character.injuryHoursRemaining',
    'Character',
    ['injuryHoursRemaining'],
    true,
    () => Character().injuryHoursRemaining,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.injuryHoursRemaining];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.injuryHoursRemaining = value.toDouble();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Character.experience',
    'Character',
    ['experience'],
    false,
    () => Character().experience,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.experience];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.experience = value.toInt();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Character.experienceToNextLayer',
    'Character',
    ['experienceToNextLayer'],
    false,
    () => Character().experienceToNextLayer,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.experienceToNextLayer];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.experienceToNextLayer = value.toInt();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Character.level',
    'Character',
    ['level'],
    false,
    () => Character().level,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.level];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.level = value.toInt();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Character.levelExp',
    'Character',
    ['levelExp'],
    false,
    () => Character().levelExp,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.levelExp];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.levelExp = value.toInt();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Character.insightPoints',
    'Character',
    ['insightPoints'],
    false,
    () => Character().insightPoints,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.insightPoints];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.insightPoints = value.toInt();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Character.birthInGameYear',
    'Character',
    ['birthInGameYear'],
    false,
    () => Character().birthInGameYear,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.birthInGameYear];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.birthInGameYear = value.toInt();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Character.attributeBonusFromAdventure',
    'Character',
    ['attributeBonusFromAdventure'],
    false,
    () => Character().attributeBonusFromAdventure,
    (db) async {
      final row = (await db.collection<Character>().get(1))!;
      return [row.attributeBonusFromAdventure];
    },
    (db, value) async {
      final row = (await db.collection<Character>().get(1))!;
      row.attributeBonusFromAdventure = value.toInt();
      await db.collection<Character>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Equipment.baseAttack',
    'Equipment',
    ['baseAttack'],
    false,
    () => Equipment().baseAttack,
    (db) async {
      final row = (await db.collection<Equipment>().get(1))!;
      return [row.baseAttack];
    },
    (db, value) async {
      final row = (await db.collection<Equipment>().get(1))!;
      row.baseAttack = value.toInt();
      await db.collection<Equipment>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Equipment.baseHealth',
    'Equipment',
    ['baseHealth'],
    false,
    () => Equipment().baseHealth,
    (db) async {
      final row = (await db.collection<Equipment>().get(1))!;
      return [row.baseHealth];
    },
    (db, value) async {
      final row = (await db.collection<Equipment>().get(1))!;
      row.baseHealth = value.toInt();
      await db.collection<Equipment>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Equipment.baseSpeed',
    'Equipment',
    ['baseSpeed'],
    false,
    () => Equipment().baseSpeed,
    (db) async {
      final row = (await db.collection<Equipment>().get(1))!;
      return [row.baseSpeed];
    },
    (db, value) async {
      final row = (await db.collection<Equipment>().get(1))!;
      row.baseSpeed = value.toInt();
      await db.collection<Equipment>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Equipment.enhanceLevel',
    'Equipment',
    ['enhanceLevel'],
    false,
    () => Equipment().enhanceLevel,
    (db) async {
      final row = (await db.collection<Equipment>().get(1))!;
      return [row.enhanceLevel];
    },
    (db, value) async {
      final row = (await db.collection<Equipment>().get(1))!;
      row.enhanceLevel = value.toInt();
      await db.collection<Equipment>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Equipment.battleCount',
    'Equipment',
    ['battleCount'],
    false,
    () => Equipment().battleCount,
    (db) async {
      final row = (await db.collection<Equipment>().get(1))!;
      return [row.battleCount];
    },
    (db, value) async {
      final row = (await db.collection<Equipment>().get(1))!;
      row.battleCount = value.toInt();
      await db.collection<Equipment>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ForgingSlot.bonusValue',
    'Equipment',
    ['forgingSlots', 'bonusValue'],
    false,
    () => ForgingSlot().bonusValue,
    (db) async {
      final row = (await db.collection<Equipment>().get(1))!;
      return [row.forgingSlots.single.bonusValue];
    },
    (db, value) async {
      final row = (await db.collection<Equipment>().get(1))!;
      row.forgingSlots.single.bonusValue = value.toInt();
      await db.collection<Equipment>().put(row);
    },
  ),
  NumericFieldEvidence(
    'InventoryItem.quantity',
    'InventoryItem',
    ['quantity'],
    false,
    () => InventoryItem().quantity,
    (db) async {
      final row = (await db.collection<InventoryItem>().get(1))!;
      return [row.quantity];
    },
    (db, value) async {
      final row = (await db.collection<InventoryItem>().get(1))!;
      row.quantity = value.toInt();
      await db.collection<InventoryItem>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SaveData.totalPlaySeconds',
    'SaveData',
    ['totalPlaySeconds'],
    false,
    () => SaveData().totalPlaySeconds,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.totalPlaySeconds];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.totalPlaySeconds = value.toInt();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SaveData.highestTowerLayer',
    'SaveData',
    ['highestTowerLayer'],
    false,
    () => SaveData().highestTowerLayer,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.highestTowerLayer];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.highestTowerLayer = value.toInt();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SaveData.tutorialStep',
    'SaveData',
    ['tutorialStep'],
    false,
    () => SaveData().tutorialStep,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.tutorialStep];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.tutorialStep = value.toInt();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SaveData.totalPassiveMojianshi',
    'SaveData',
    ['totalPassiveMojianshi'],
    false,
    () => SaveData().totalPassiveMojianshi,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.totalPassiveMojianshi];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.totalPassiveMojianshi = value.toInt();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SaveData.totalPassiveExperience',
    'SaveData',
    ['totalPassiveExperience'],
    false,
    () => SaveData().totalPassiveExperience,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.totalPassiveExperience];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.totalPassiveExperience = value.toInt();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SaveData.baicaoMaxDepth',
    'SaveData',
    ['baicaoMaxDepth'],
    false,
    () => SaveData().baicaoMaxDepth,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.baicaoMaxDepth];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.baicaoMaxDepth = value.toInt();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SaveData.expeditionRunSerial',
    'SaveData',
    ['expeditionRunSerial'],
    false,
    () => SaveData().expeditionRunSerial,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.expeditionRunSerial];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.expeditionRunSerial = value.toInt();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SaveData.gauntletRunSerial',
    'SaveData',
    ['gauntletRunSerial'],
    false,
    () => SaveData().gauntletRunSerial,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.gauntletRunSerial];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.gauntletRunSerial = value.toInt();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SaveData.duanhunClearedCyclesMax',
    'SaveData',
    ['duanhunClearedCyclesMax'],
    false,
    () => SaveData().duanhunClearedCyclesMax,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.duanhunClearedCyclesMax];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.duanhunClearedCyclesMax = value.toInt();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SkillUnlockEntry.fragmentCount',
    'SaveData',
    ['skillUnlockProgress', 'fragmentCount'],
    false,
    () => SkillUnlockEntry().fragmentCount,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.skillUnlockProgress.single.fragmentCount];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.skillUnlockProgress.single.fragmentCount = value.toInt();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'IslandBuildingState.level',
    'SaveData',
    ['islandBuildings', 'level'],
    false,
    () => IslandBuildingState().level,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.islandBuildings.single.level];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.islandBuildings.single.level = value.toInt();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'IslandBuildingState.stored',
    'SaveData',
    ['islandBuildings', 'stored'],
    true,
    () => IslandBuildingState().stored,
    (db) async {
      final row = (await db.collection<SaveData>().get(0))!;
      return [row.islandBuildings.single.stored];
    },
    (db, value) async {
      final row = (await db.collection<SaveData>().get(0))!;
      row.islandBuildings.single.stored = value.toDouble();
      await db.collection<SaveData>().put(row);
    },
  ),
  NumericFieldEvidence(
    'Technique.cultivationProgress',
    'Technique',
    ['cultivationProgress'],
    false,
    () => Technique().cultivationProgress,
    (db) async {
      final row = (await db.collection<Technique>().get(1))!;
      return [row.cultivationProgress];
    },
    (db, value) async {
      final row = (await db.collection<Technique>().get(1))!;
      row.cultivationProgress = value.toInt();
      await db.collection<Technique>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SkillUsageEntry.count',
    'Technique',
    ['skillUsageCount', 'count'],
    false,
    () => SkillUsageEntry().count,
    (db) async {
      final row = (await db.collection<Technique>().get(1))!;
      return [row.skillUsageCount.single.count];
    },
    (db, value) async {
      final row = (await db.collection<Technique>().get(1))!;
      row.skillUsageCount.single.count = value.toInt();
      await db.collection<Technique>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.currentHp',
    'DurableActivityCombatRun',
    ['members', 'currentHp'],
    false,
    () => ActivityMemberSnapshot().currentHp,
    (db) async {
      final row = (await db.collection<DurableActivityCombatRun>().get(1))!;
      return [row.members.single.currentHp];
    },
    (db, value) async {
      final row = (await db.collection<DurableActivityCombatRun>().get(1))!;
      row.members.single.currentHp = value.toInt();
      await db.collection<DurableActivityCombatRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.currentQi',
    'DurableActivityCombatRun',
    ['members', 'currentQi'],
    false,
    () => ActivityMemberSnapshot().currentQi,
    (db) async {
      final row = (await db.collection<DurableActivityCombatRun>().get(1))!;
      return [row.members.single.currentQi];
    },
    (db, value) async {
      final row = (await db.collection<DurableActivityCombatRun>().get(1))!;
      row.members.single.currentQi = value.toInt();
      await db.collection<DurableActivityCombatRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.maxHp',
    'DurableActivityCombatRun',
    ['members', 'maxHp'],
    false,
    () => ActivityMemberSnapshot().maxHp,
    (db) async {
      final row = (await db.collection<DurableActivityCombatRun>().get(1))!;
      return [row.members.single.maxHp];
    },
    (db, value) async {
      final row = (await db.collection<DurableActivityCombatRun>().get(1))!;
      row.members.single.maxHp = value.toInt();
      await db.collection<DurableActivityCombatRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.maxQi',
    'DurableActivityCombatRun',
    ['members', 'maxQi'],
    false,
    () => ActivityMemberSnapshot().maxQi,
    (db) async {
      final row = (await db.collection<DurableActivityCombatRun>().get(1))!;
      return [row.members.single.maxQi];
    },
    (db, value) async {
      final row = (await db.collection<DurableActivityCombatRun>().get(1))!;
      row.members.single.maxQi = value.toInt();
      await db.collection<DurableActivityCombatRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'BossGauntletRun.currentStage',
    'BossGauntletRun',
    ['currentStage'],
    false,
    () => BossGauntletRun().currentStage,
    (db) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      return [row.currentStage];
    },
    (db, value) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      row.currentStage = value.toInt();
      await db.collection<BossGauntletRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'BossGauntletRun.cycleIndex',
    'BossGauntletRun',
    ['cycleIndex'],
    false,
    () => BossGauntletRun().cycleIndex,
    (db) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      return [row.cycleIndex];
    },
    (db, value) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      row.cycleIndex = value.toInt();
      await db.collection<BossGauntletRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.currentHp',
    'BossGauntletRun',
    ['members', 'currentHp'],
    false,
    () => ActivityMemberSnapshot().currentHp,
    (db) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      return [row.members.single.currentHp];
    },
    (db, value) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      row.members.single.currentHp = value.toInt();
      await db.collection<BossGauntletRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.currentQi',
    'BossGauntletRun',
    ['members', 'currentQi'],
    false,
    () => ActivityMemberSnapshot().currentQi,
    (db) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      return [row.members.single.currentQi];
    },
    (db, value) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      row.members.single.currentQi = value.toInt();
      await db.collection<BossGauntletRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.maxHp',
    'BossGauntletRun',
    ['members', 'maxHp'],
    false,
    () => ActivityMemberSnapshot().maxHp,
    (db) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      return [row.members.single.maxHp];
    },
    (db, value) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      row.members.single.maxHp = value.toInt();
      await db.collection<BossGauntletRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.maxQi',
    'BossGauntletRun',
    ['members', 'maxQi'],
    false,
    () => ActivityMemberSnapshot().maxQi,
    (db) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      return [row.members.single.maxQi];
    },
    (db, value) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      row.members.single.maxQi = value.toInt();
      await db.collection<BossGauntletRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'RewardEntry.quantity',
    'BossGauntletRun',
    ['stagedRewards', 'quantity'],
    false,
    () => RewardEntry().quantity,
    (db) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      return [row.stagedRewards.single.quantity];
    },
    (db, value) async {
      final row = (await db.collection<BossGauntletRun>().get(1))!;
      row.stagedRewards.single.quantity = value.toInt();
      await db.collection<BossGauntletRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'EncounterProgress.attributeGainsConstitution',
    'EncounterProgress',
    ['attributeGainsConstitution'],
    false,
    () => EncounterProgress().attributeGainsConstitution,
    (db) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      return [row.attributeGainsConstitution];
    },
    (db, value) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      row.attributeGainsConstitution = value.toInt();
      await db.collection<EncounterProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'EncounterProgress.attributeGainsEnlightenment',
    'EncounterProgress',
    ['attributeGainsEnlightenment'],
    false,
    () => EncounterProgress().attributeGainsEnlightenment,
    (db) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      return [row.attributeGainsEnlightenment];
    },
    (db, value) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      row.attributeGainsEnlightenment = value.toInt();
      await db.collection<EncounterProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'EncounterProgress.attributeGainsAgility',
    'EncounterProgress',
    ['attributeGainsAgility'],
    false,
    () => EncounterProgress().attributeGainsAgility,
    (db) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      return [row.attributeGainsAgility];
    },
    (db, value) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      row.attributeGainsAgility = value.toInt();
      await db.collection<EncounterProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'EncounterProgress.attributeGainsFortune',
    'EncounterProgress',
    ['attributeGainsFortune'],
    false,
    () => EncounterProgress().attributeGainsFortune,
    (db) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      return [row.attributeGainsFortune];
    },
    (db, value) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      row.attributeGainsFortune = value.toInt();
      await db.collection<EncounterProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'SchoolKillCount.count',
    'EncounterProgress',
    ['schoolKillCounts', 'count'],
    false,
    () => SchoolKillCount().count,
    (db) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      return [row.schoolKillCounts.single.count];
    },
    (db, value) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      row.schoolKillCounts.single.count = value.toInt();
      await db.collection<EncounterProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'BiomeMinutes.minutes',
    'EncounterProgress',
    ['biomeMinutes', 'minutes'],
    false,
    () => BiomeMinutes().minutes,
    (db) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      return [row.biomeMinutes.single.minutes];
    },
    (db, value) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      row.biomeMinutes.single.minutes = value.toInt();
      await db.collection<EncounterProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'WeatherMinutes.minutes',
    'EncounterProgress',
    ['weatherMinutes', 'minutes'],
    false,
    () => WeatherMinutes().minutes,
    (db) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      return [row.weatherMinutes.single.minutes];
    },
    (db, value) async {
      final row = (await db.collection<EncounterProgress>().get(1))!;
      row.weatherMinutes.single.minutes = value.toInt();
      await db.collection<EncounterProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ExpeditionMilestoneRecord.recordVersion',
    'ExpeditionMilestoneRecord',
    ['recordVersion'],
    false,
    () => ExpeditionMilestoneRecord().recordVersion,
    (db) async {
      final row = (await db.collection<ExpeditionMilestoneRecord>().get(1))!;
      return [row.recordVersion];
    },
    (db, value) async {
      final row = (await db.collection<ExpeditionMilestoneRecord>().get(1))!;
      row.recordVersion = value.toInt();
      await db.collection<ExpeditionMilestoneRecord>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ExpeditionMilestoneRecord.cycleIndex',
    'ExpeditionMilestoneRecord',
    ['cycleIndex'],
    false,
    () => ExpeditionMilestoneRecord().cycleIndex,
    (db) async {
      final row = (await db.collection<ExpeditionMilestoneRecord>().get(1))!;
      return [row.cycleIndex];
    },
    (db, value) async {
      final row = (await db.collection<ExpeditionMilestoneRecord>().get(1))!;
      row.cycleIndex = value.toInt();
      await db.collection<ExpeditionMilestoneRecord>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ExpeditionRun.currentNode',
    'ExpeditionRun',
    ['currentNode'],
    false,
    () => ExpeditionRun().currentNode,
    (db) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      return [row.currentNode];
    },
    (db, value) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      row.currentNode = value.toInt();
      await db.collection<ExpeditionRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ExpeditionRun.cycleIndex',
    'ExpeditionRun',
    ['cycleIndex'],
    false,
    () => ExpeditionRun().cycleIndex,
    (db) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      return [row.cycleIndex];
    },
    (db, value) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      row.cycleIndex = value.toInt();
      await db.collection<ExpeditionRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.currentHp',
    'ExpeditionRun',
    ['members', 'currentHp'],
    false,
    () => ActivityMemberSnapshot().currentHp,
    (db) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      return [row.members.single.currentHp];
    },
    (db, value) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      row.members.single.currentHp = value.toInt();
      await db.collection<ExpeditionRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.currentQi',
    'ExpeditionRun',
    ['members', 'currentQi'],
    false,
    () => ActivityMemberSnapshot().currentQi,
    (db) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      return [row.members.single.currentQi];
    },
    (db, value) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      row.members.single.currentQi = value.toInt();
      await db.collection<ExpeditionRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.maxHp',
    'ExpeditionRun',
    ['members', 'maxHp'],
    false,
    () => ActivityMemberSnapshot().maxHp,
    (db) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      return [row.members.single.maxHp];
    },
    (db, value) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      row.members.single.maxHp = value.toInt();
      await db.collection<ExpeditionRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ActivityMemberSnapshot.maxQi',
    'ExpeditionRun',
    ['members', 'maxQi'],
    false,
    () => ActivityMemberSnapshot().maxQi,
    (db) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      return [row.members.single.maxQi];
    },
    (db, value) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      row.members.single.maxQi = value.toInt();
      await db.collection<ExpeditionRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'RewardEntry.quantity',
    'ExpeditionRun',
    ['stagedRewards', 'quantity'],
    false,
    () => RewardEntry().quantity,
    (db) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      return [row.stagedRewards.single.quantity];
    },
    (db, value) async {
      final row = (await db.collection<ExpeditionRun>().get(1))!;
      row.stagedRewards.single.quantity = value.toInt();
      await db.collection<ExpeditionRun>().put(row);
    },
  ),
  NumericFieldEvidence(
    'MainlineProgress.currentChapterIndex',
    'MainlineProgress',
    ['currentChapterIndex'],
    false,
    () => MainlineProgress().currentChapterIndex,
    (db) async {
      final row = (await db.collection<MainlineProgress>().get(1))!;
      return [row.currentChapterIndex];
    },
    (db, value) async {
      final row = (await db.collection<MainlineProgress>().get(1))!;
      row.currentChapterIndex = value.toInt();
      await db.collection<MainlineProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'ProgressiveUnlockReceipt.receiptVersion',
    'ProgressiveUnlockReceipt',
    ['receiptVersion'],
    false,
    () => ProgressiveUnlockReceipt().receiptVersion,
    (db) async {
      final row = (await db.collection<ProgressiveUnlockReceipt>().get(1))!;
      return [row.receiptVersion];
    },
    (db, value) async {
      final row = (await db.collection<ProgressiveUnlockReceipt>().get(1))!;
      row.receiptVersion = value.toInt();
      await db.collection<ProgressiveUnlockReceipt>().put(row);
    },
  ),
  NumericFieldEvidence(
    'RewardClaimReceipt.receiptVersion',
    'RewardClaimReceipt',
    ['receiptVersion'],
    false,
    () => RewardClaimReceipt().receiptVersion,
    (db) async {
      final row = (await db.collection<RewardClaimReceipt>().get(1))!;
      return [row.receiptVersion];
    },
    (db, value) async {
      final row = (await db.collection<RewardClaimReceipt>().get(1))!;
      row.receiptVersion = value.toInt();
      await db.collection<RewardClaimReceipt>().put(row);
    },
  ),
  NumericFieldEvidence(
    'RetreatSession.durationHours',
    'RetreatSession',
    ['durationHours'],
    false,
    () => RetreatSession().durationHours,
    (db) async {
      final row = (await db.collection<RetreatSession>().get(1))!;
      return [row.durationHours];
    },
    (db, value) async {
      final row = (await db.collection<RetreatSession>().get(1))!;
      row.durationHours = value.toInt();
      await db.collection<RetreatSession>().put(row);
    },
  ),
  NumericFieldEvidence(
    'RewardEntry.quantity',
    'RetreatSession',
    ['actualRewards', 'quantity'],
    false,
    () => RewardEntry().quantity,
    (db) async {
      final row = (await db.collection<RetreatSession>().get(1))!;
      return [row.actualRewards.single.quantity];
    },
    (db, value) async {
      final row = (await db.collection<RetreatSession>().get(1))!;
      row.actualRewards.single.quantity = value.toInt();
      await db.collection<RetreatSession>().put(row);
    },
  ),
  NumericFieldEvidence(
    'TowerPersonalRecord.recordVersion',
    'TowerPersonalRecord',
    ['recordVersion'],
    false,
    () => TowerPersonalRecord().recordVersion,
    (db) async {
      final row = (await db.collection<TowerPersonalRecord>().get(1))!;
      return [row.recordVersion];
    },
    (db, value) async {
      final row = (await db.collection<TowerPersonalRecord>().get(1))!;
      row.recordVersion = value.toInt();
      await db.collection<TowerPersonalRecord>().put(row);
    },
  ),
  NumericFieldEvidence(
    'TowerPersonalRecord.highestClearedFloor',
    'TowerPersonalRecord',
    ['highestClearedFloor'],
    false,
    () => TowerPersonalRecord().highestClearedFloor,
    (db) async {
      final row = (await db.collection<TowerPersonalRecord>().get(1))!;
      return [row.highestClearedFloor];
    },
    (db, value) async {
      final row = (await db.collection<TowerPersonalRecord>().get(1))!;
      row.highestClearedFloor = value.toInt();
      await db.collection<TowerPersonalRecord>().put(row);
    },
  ),
  NumericFieldEvidence(
    'TowerProgress.highestClearedFloor',
    'TowerProgress',
    ['highestClearedFloor'],
    false,
    () => TowerProgress().highestClearedFloor,
    (db) async {
      final row = (await db.collection<TowerProgress>().get(1))!;
      return [row.highestClearedFloor];
    },
    (db, value) async {
      final row = (await db.collection<TowerProgress>().get(1))!;
      row.highestClearedFloor = value.toInt();
      await db.collection<TowerProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'TowerProgress.totalAttempts',
    'TowerProgress',
    ['totalAttempts'],
    false,
    () => TowerProgress().totalAttempts,
    (db) async {
      final row = (await db.collection<TowerProgress>().get(1))!;
      return [row.totalAttempts];
    },
    (db, value) async {
      final row = (await db.collection<TowerProgress>().get(1))!;
      row.totalAttempts = value.toInt();
      await db.collection<TowerProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'TowerProgress.totalDefeats',
    'TowerProgress',
    ['totalDefeats'],
    false,
    () => TowerProgress().totalDefeats,
    (db) async {
      final row = (await db.collection<TowerProgress>().get(1))!;
      return [row.totalDefeats];
    },
    (db, value) async {
      final row = (await db.collection<TowerProgress>().get(1))!;
      row.totalDefeats = value.toInt();
      await db.collection<TowerProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'TowerProgress.currentCycleIndex',
    'TowerProgress',
    ['currentCycleIndex'],
    false,
    () => TowerProgress().currentCycleIndex,
    (db) async {
      final row = (await db.collection<TowerProgress>().get(1))!;
      return [row.currentCycleIndex];
    },
    (db, value) async {
      final row = (await db.collection<TowerProgress>().get(1))!;
      row.currentCycleIndex = value.toInt();
      await db.collection<TowerProgress>().put(row);
    },
  ),
  NumericFieldEvidence(
    'TowerProgress.maxClearedCycle',
    'TowerProgress',
    ['maxClearedCycle'],
    false,
    () => TowerProgress().maxClearedCycle,
    (db) async {
      final row = (await db.collection<TowerProgress>().get(1))!;
      return [row.maxClearedCycle];
    },
    (db, value) async {
      final row = (await db.collection<TowerProgress>().get(1))!;
      row.maxClearedCycle = value.toInt();
      await db.collection<TowerProgress>().put(row);
    },
  ),
];
