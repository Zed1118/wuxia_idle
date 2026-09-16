import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/system_clock_provider.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/combat_shared/application/combat_content_providers.dart';
import 'package:wuxia_idle/features/combat_shared/domain/combat_stats_summary.dart';
import 'package:wuxia_idle/features/combat_shared/domain/hero_camera_data.dart';
import 'package:wuxia_idle/features/cultivation/domain/advancement_entry.dart';
import 'package:wuxia_idle/features/cultivation/domain/realm_progress_display.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_drop_result.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_progress.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/equipment/domain/resonance_upgrade_notice.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/jianghu/domain/npc_relation.dart';
import 'package:wuxia_idle/features/jianghu/domain/reputation.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_settlement.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock_receipt.dart';
import 'package:wuxia_idle/features/pvp/domain/pvp_record.dart';
import 'package:wuxia_idle/features/pvp/domain/pvp_snapshot.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';
import 'package:wuxia_idle/features/tower/application/tower_settlement.dart';
import 'package:wuxia_idle/features/tower/domain/tower_personal_record.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/weapon_codex/domain/equipment_catalog_entry.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

final _initialAt = DateTime.utc(2026, 9, 16, 12);
final _settlementAt = DateTime.utc(2026, 9, 16, 20);
const _seed = 20260917;

enum _SettlementPath {
  mainlineVictory,
  mainlineVictoryMilestone,
  mainlineDefeat,
  towerVictory,
  towerCombat,
}

typedef _SettlementFacts = ({Object? returned, Map<String, Object?> persisted});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameRepository repository;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
  });

  Future<_SettlementFacts> settle(
    _SettlementPath path, {
    DateTime? at,
    int? seed,
  }) => _settleInFreshDatabase(
    repository,
    path,
    at: at ?? _settlementAt,
    seed: seed ?? (path == _SettlementPath.towerVictory ? 2 : _seed),
  );

  for (final entry in const {
    _SettlementPath.mainlineVictory: '主线首关胜利含装备延续典故',
    _SettlementPath.mainlineVictoryMilestone: '群战终关胜利含里程碑装备',
    _SettlementPath.mainlineDefeat: '主线首章首领战败',
    _SettlementPath.towerVictory: '九霄塔第一层首通',
    _SettlementPath.towerCombat: '九霄塔第四层首领战败',
  }.entries) {
    test('${entry.value}：固定时钟与种子使完整返回和全部持久字段一致', () async {
      final first = await settle(entry.key);
      final repeated = await settle(entry.key);
      expect(repeated.returned, equals(first.returned));
      expect(repeated.persisted, equals(first.persisted));

      // 初始存档与输入快照不变，只换依赖时钟，证明结算实际消费了注入值。
      final later = await settle(
        entry.key,
        at: _settlementAt.add(const Duration(hours: 2)),
      );
      expect(later.persisted, isNot(equals(first.persisted)));

      if (entry.key == _SettlementPath.mainlineVictory ||
          entry.key == _SettlementPath.mainlineVictoryMilestone ||
          entry.key == _SettlementPath.towerVictory) {
        final differentSeed = await settle(entry.key, seed: 1);
        expect(differentSeed.returned, isNot(equals(first.returned)));
        expect(differentSeed.persisted, isNot(equals(first.persisted)));
      }
    });
  }
}

Future<_SettlementFacts> _settleInFreshDatabase(
  GameRepository repository,
  _SettlementPath path, {
  required DateTime at,
  required int seed,
}) async {
  final directory = await Directory.systemTemp.createTemp(
    'settlement_determinism_',
  );
  final clock = SystemClock.fixed(at);
  final container = ProviderContainer(
    overrides: [systemClockProvider.overrideWithValue(clock)],
  );
  try {
    await IsarSetup.init(directory: directory, inspector: false);
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.put(
        Character.create(
          name: '确定性守卫角色',
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes(),
          rarity: RarityTier.biaoZhun,
          lineageRole: LineageRole.founder,
          isFounder: true,
          createdAt: _initialAt,
          internalForce: 500,
          mainTechniqueId: path == _SettlementPath.mainlineDefeat ? 1 : null,
        )..id = 1,
      );
      if (path == _SettlementPath.mainlineDefeat) {
        await isar.techniques.put(
          Technique.create(
            defId: 'tech_gangmeng_jichu',
            ownerCharacterId: 1,
            tier: repository.getTechnique('tech_gangmeng_jichu').tier,
            school: TechniqueSchool.gangMeng,
            role: TechniqueRole.main,
            learnedAt: _initialAt,
            cultivationProgress: 50,
          )..id = 1,
        );
      }
      await isar.saveDatas.put(
        SaveData()
          ..id = 0
          ..slotId = IsarSetup.currentSlotId
          ..saveVersion = IsarSetup.currentSaveVersion
          ..createdAt = _initialAt
          ..lastSavedAt = _initialAt
          ..lastOnlineAt = _settlementAt
          ..passiveLastSettledAt = _settlementAt
          ..activeCharacterIds = [1]
          ..founderCharacterId = 1,
      );
    });

    // 每次重建四个有状态随机源，不复用上次已经消费的随机序列。
    final rng = DefaultRng(seed: seed);
    final mathRandom = math.Random(seed);
    final eventRandom = math.Random(seed);
    final milestoneRng = DefaultRng(seed: seed);
    final drops = container.read(dropServiceProvider);
    final mainlineDependencies = MainlineSettlementDependencies(
      readClock: () => clock,
      readNumbers: () => repository.numbers,
      readDropService: () => drops,
      readRng: () => rng,
      readMathRandom: () => mathRandom,
      readEventRandom: () => eventRandom,
      readMilestoneRng: () => milestoneRng,
      readTutorialService: () => null,
      readReputationService: () => null,
      readFestivalToday: () => null,
    );
    final towerDependencies = TowerSettlementDependencies(
      readClock: () => clock,
      readIsar: () => isar,
      readNumbers: () => repository.numbers,
      readDropService: () => drops,
      readRng: () => rng,
      readMathRandom: () => mathRandom,
      readEventRandom: () => eventRandom,
    );

    // 四个入口都不传 settlementAt，必须从依赖包读取时钟。
    final Object? returned;
    switch (path) {
      case _SettlementPath.mainlineVictory:
      case _SettlementPath.mainlineVictoryMilestone:
        final result = await applyVictoryResolution(
          dependencies: mainlineDependencies,
          stage: repository.getStage(
            path == _SettlementPath.mainlineVictory
                ? 'stage_01_01'
                : 'stage_mass_battle_05',
          ),
          expectedParticipantId: 1,
          rewardOccurrenceId: 'determinism-mainline-occurrence',
          settlementSnapshot: _snapshot(victory: true),
        );
        expect(result, isNotNull);
        if (path == _SettlementPath.mainlineVictory && seed == _seed) {
          final equipment = result!.drops.equipments.singleWhere(
            (equipment) => equipment.defId == 'armor_xunchang_bu_yi',
          );
          expect(equipment.obtainedAt, at);
          final addedLore = equipment.lores.where((lore) => !lore.isPreset);
          expect(addedLore, hasLength(1));
          expect(addedLore.single.addedAt, at);
          expect(await isar.equipments.get(equipment.id), isNotNull);
        }
        if (path == _SettlementPath.mainlineVictoryMilestone) {
          final save = await isar.saveDatas.get(0);
          expect(save!.grantedMilestoneEquipmentIds, isNotEmpty);
          for (final id in save.grantedMilestoneEquipmentIds) {
            final equipment = await isar.equipments
                .filter()
                .defIdEqualTo(id)
                .findFirst();
            expect(equipment, isNotNull);
            expect(equipment!.obtainedAt.isAtSameMomentAs(at), isTrue);
          }
        }
        returned = _mainlineVictoryFacts(result!);
      case _SettlementPath.mainlineDefeat:
        final result = await applyParticipantDefeatResolution(
          dependencies: mainlineDependencies,
          stage: repository.getStage('stage_01_05'),
          expectedParticipantId: 1,
          settlementSnapshot: _snapshot(victory: false),
        );
        expect(result, hasLength(1));
        expect(result.single.hasDefeatPenalty, isTrue);
        expect(result.single.injuryApplied, isTrue);
        returned = result.map(_defeatFacts).toList();
      case _SettlementPath.towerVictory:
        final result = await applyTowerVictorySettlement(
          dependencies: towerDependencies,
          floor: repository.getTowerFloor(1),
          participantId: 1,
          elapsedMs: 1000,
          rewardOccurrenceId: 'determinism-tower-occurrence',
          settlementSnapshot: _snapshot(victory: true),
        );
        expect(result.clearResult.isFirstClear, isTrue);
        expect(result.clearResult.highestAfter, 1);
        expect(result.drops.items, isNotEmpty);
        if (seed == 2) expect(result.drops.equipments, isNotEmpty);
        for (final equipment in result.drops.equipments) {
          expect(equipment.obtainedAt, at);
          expect(await isar.equipments.get(equipment.id), isNotNull);
          for (final lore in equipment.lores.where((lore) => !lore.isPreset)) {
            expect(lore.addedAt, at);
          }
        }
        returned = {
          'clearResult': {
            'isFirstClear': result.clearResult.isFirstClear,
            'highestAfter': result.clearResult.highestAfter,
          },
          'resolution': _towerCombatFacts(result.resolution),
          'skillDrop': _skillDropFacts(result.skillDrop),
          'drops': _dropFacts(result.drops),
        };
      case _SettlementPath.towerCombat:
        final result = await applyTowerCombatResolution(
          dependencies: towerDependencies,
          floor: repository.getTowerFloor(4),
          grantsFirstClearExperience: false,
          expectedParticipantId: 1,
          settlementSnapshot: _snapshot(victory: false),
        );
        expect(result.participantName, '确定性守卫角色');
        expect(result.heavyInjuryHoursAdded, greaterThan(0));
        returned = _towerCombatFacts(result);
    }

    final save = await isar.saveDatas.get(0);
    expect(save!.lastOnlineAt.isAtSameMomentAs(at), isTrue);
    expect(save.passiveLastSettledAt!.isAtSameMomentAs(at), isTrue);
    return (returned: returned, persisted: await _databaseFacts(isar));
  } finally {
    container.dispose();
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  }
}

CombatSettlementSnapshot _snapshot({required bool victory}) =>
    CombatSettlementSnapshot(
      result: victory ? BattleResult.leftWin : BattleResult.rightWin,
      totalTicks: 10,
      hadActions: true,
      playerCharacterId: 1,
      participants: [
        CombatParticipantSnapshot(
          characterId: 1,
          currentHp: victory ? 8000 : 0,
          maxHp: 8000,
        ),
      ],
      skillCasts: [],
      totalDamage: 100,
      criticalCount: 1,
      damageByCharacterId: {1: 100},
    );

Map<String, Object?> _mainlineVictoryFacts(MainlineVictorySettlement value) => {
  'drops': _dropFacts(value.drops),
  'advancements': value.advancements.map(_advancementFacts).toList(),
  'resonanceUpgrades': value.resonanceUpgrades.map(_resonanceFacts).toList(),
  'stats': _statsFacts(value.stats),
  'heroCamera': _heroFacts(value.heroCamera),
  'extraDisplayTiers': value.extraDisplayTiers
      .map((tier) => tier.name)
      .toList(),
  'characters': value.characters.map(_characterFacts).toList(),
  'skillDrop': _skillDropFacts(value.skillDrop),
};

Map<String, Object?> _towerCombatFacts(TowerCombatResolution value) => {
  'advancements': value.advancements.map(_advancementFacts).toList(),
  'resonanceUpgrades': value.resonanceUpgrades.map(_resonanceFacts).toList(),
  'stats': _statsFacts(value.stats),
  'heroCamera': _heroFacts(value.heroCamera),
  'participantName': value.participantName,
  'lightInjuryStacksAdded': value.lightInjuryStacksAdded,
  'heavyInjuryHoursAdded': value.heavyInjuryHoursAdded,
};

Map<String, Object?> _defeatFacts(DefeatLossEntry value) => {
  'characterName': value.characterName,
  'internalForceBefore': value.internalForceBefore,
  'internalForceAfter': value.internalForceAfter,
  'techniqueName': value.techniqueName,
  'oldLayerLabel': value.oldLayerLabel,
  'newLayerLabel': value.newLayerLabel,
  'layersRolledBack': value.layersRolledBack,
  'residueApplied': value.residueApplied,
  'injuryApplied': value.injuryApplied,
  'lightInjuryStacksAdded': value.lightInjuryStacksAdded,
  'heavyInjuryHoursAdded': value.heavyInjuryHoursAdded,
  'hasDefeatPenalty': value.hasDefeatPenalty,
};

Map<String, Object?> _dropFacts(DropResult value) => {
  'equipments': value.equipments.map(_equipmentFacts).toList(),
  'items': value.items
      .map((item) => {'defId': item.defId, 'quantity': item.quantity})
      .toList(),
};

Map<String, Object?> _advancementFacts(AdvancementEntry value) => {
  'characterId': value.characterId,
  'chName': value.chName,
  'result': {
    'layersGained': value.result.layersGained,
    'tierBefore': value.result.tierBefore.name,
    'layerBefore': value.result.layerBefore.name,
    'tierAfter': value.result.tierAfter.name,
    'layerAfter': value.result.layerAfter.name,
    'internalForceMaxBefore': value.result.internalForceMaxBefore,
    'internalForceMaxAfter': value.result.internalForceMaxAfter,
    'experienceGained': value.result.experienceGained,
    'progressChange': {
      'before': _realmProgressFacts(value.result.progressChange.before),
      'after': _realmProgressFacts(value.result.progressChange.after),
    },
  },
};

Map<String, Object?> _realmProgressFacts(RealmProgressDisplay value) => {
  'level': value.level,
  'experience': value.experience,
  'experienceToNext': value.experienceToNext,
  'progress': value.progress,
  'state': value.state.name,
};

Map<String, Object?> _resonanceFacts(ResonanceUpgradeNotice value) => {
  'equipmentName': value.equipmentName,
  'newStage': value.newStage.name,
};

Map<String, Object?> _skillDropFacts(SkillDropResult value) => {
  'manualGranted': value.manualGranted,
  'fragmentSkillId': value.fragmentSkillId,
  'fragmentCount': value.fragmentCount,
  'fragmentThreshold': value.fragmentThreshold,
  'fragmentJustUnlocked': value.fragmentJustUnlocked,
};

Map<String, Object?> _statsFacts(CombatStatsSummary value) => {
  'totalDamage': value.totalDamage,
  'critCount': value.critCount,
  'totalTicks': value.totalTicks,
};

Map<String, Object?>? _heroFacts(HeroCameraData? value) => value == null
    ? null
    : {
        'portraitPath': value.portraitPath,
        'heroName': value.heroName,
        'realmLabel': value.realmLabel,
        'bossName': value.bossName,
        'topDamage': value.topDamage,
      };

Map<String, Object?> _equipmentFacts(Equipment value) {
  final facts = <String, Object?>{
    'id': value.id,
    'defId': value.defId,
    'customName': value.customName,
    'tier': value.tier.name,
    'slot': value.slot.name,
    'school': value.school?.name,
    'baseAttack': value.baseAttack,
    'baseHealth': value.baseHealth,
    'baseSpeed': value.baseSpeed,
    'enhanceLevel': value.enhanceLevel,
    'ownerCharacterId': value.ownerCharacterId,
    'isLineageHeritage': value.isLineageHeritage,
    'isLocked': value.isLocked,
    'previousOwnerCharacterIds': value.previousOwnerCharacterIds,
    'battleCount': value.battleCount,
    'forgingSlots': value.forgingSlots
        .map(
          (slot) => {
            'slotIndex': slot.slotIndex,
            'type': slot.type?.name,
            'unlocked': slot.unlocked,
            'bonusValue': slot.bonusValue,
            'specialSkillId': slot.specialSkillId,
          },
        )
        .toList(),
    'lores': value.lores
        .map(
          (lore) => {
            'text': lore.text,
            'isPreset': lore.isPreset,
            'addedAt': lore.addedAt.toIso8601String(),
            'triggerEventDesc': lore.triggerEventDesc,
          },
        )
        .toList(),
    'obtainedAt': value.obtainedAt.toIso8601String(),
    'obtainedFrom': value.obtainedFrom,
  };
  expect(facts.keys.toSet(), {'id', ...EquipmentSchema.properties.keys});
  return facts;
}

Map<String, Object?> _characterFacts(Character value) {
  final facts = <String, Object?>{
    'id': value.id,
    'name': value.name,
    'realmTier': value.realmTier.name,
    'realmLayer': value.realmLayer.name,
    'internalForce': value.internalForce,
    'internalForceMax': value.internalForceMax,
    'innerBreathDisorderHoursRemaining':
        value.innerBreathDisorderHoursRemaining,
    'innerDemonResidueHoursRemaining': value.innerDemonResidueHoursRemaining,
    'lightInjuryStacks': value.lightInjuryStacks,
    'injuryHoursRemaining': value.injuryHoursRemaining,
    'experience': value.experience,
    'passiveExperienceRemainder': value.passiveExperienceRemainder,
    'experienceToNextLayer': value.experienceToNextLayer,
    'level': value.level,
    'levelExp': value.levelExp,
    'insightPoints': value.insightPoints,
    'attributes': {
      'constitution': value.attributes.constitution,
      'enlightenment': value.attributes.enlightenment,
      'agility': value.attributes.agility,
      'fortune': value.attributes.fortune,
    },
    'rarity': value.rarity.name,
    'school': value.school?.name,
    'mainTechniqueId': value.mainTechniqueId,
    'assistTechniqueIds': value.assistTechniqueIds,
    'equippedWeaponId': value.equippedWeaponId,
    'equippedArmorId': value.equippedArmorId,
    'equippedAccessoryId': value.equippedAccessoryId,
    'learnedSkillIds': value.learnedSkillIds,
    'mainSkillId1': value.mainSkillId1,
    'mainSkillId2': value.mainSkillId2,
    'assistSkillId': value.assistSkillId,
    'resonanceSkillId': value.resonanceSkillId,
    'ultimateSkillId': value.ultimateSkillId,
    'keySkillId': value.keySkillId,
    'equippedEncounterSkillId': value.equippedEncounterSkillId,
    'isActive': value.isActive,
    'isInRetreat': value.isInRetreat,
    'currentRetreatSessionId': value.currentRetreatSessionId,
    'masterId': value.masterId,
    'discipleIds': value.discipleIds,
    'lineageRole': value.lineageRole.name,
    'isFounder': value.isFounder,
    'isAlive': value.isAlive,
    'birthInGameYear': value.birthInGameYear,
    'attributeBonusFromAdventure': value.attributeBonusFromAdventure,
    'isInSect': value.isInSect,
    'sectId': value.sectId,
    'sectRank': value.sectRank?.name,
    'portraitPath': value.portraitPath,
    'founderCreationSchoolId': value.founderCreationSchoolId,
    'founderCreationOriginId': value.founderCreationOriginId,
    'founderCreationFateId': value.founderCreationFateId,
    'createdAt': value.createdAt.toIso8601String(),
  };
  expect(facts.keys.toSet(), {'id', ...CharacterSchema.properties.keys});
  return facts;
}

// 直接导出全部持久表，时间、随机衍生字段和空表均参与相等比较。
Future<Map<String, Object?>> _databaseFacts(Isar isar) async {
  final facts = <String, Object?>{
    'SaveData': await isar.saveDatas.where().exportJson(),
    'Character': await isar.characters.where().exportJson(),
    'Equipment': await isar.equipments.where().exportJson(),
    'Technique': await isar.techniques.where().exportJson(),
    'InventoryItem': await isar.inventoryItems.where().exportJson(),
    'GameEvent': await isar.gameEvents.where().exportJson(),
    'MainlineProgress': await isar.mainlineProgress.where().exportJson(),
    'MainlineSettlementJournal': await isar.mainlineSettlementJournals
        .where()
        .exportJson(),
    'TowerProgress': await isar.towerProgress.where().exportJson(),
    'TowerPersonalRecord': await isar.towerPersonalRecords.where().exportJson(),
    'RetreatSession': await isar.retreatSessions.where().exportJson(),
    'EncounterProgress': await isar.encounterProgress.where().exportJson(),
    'Reputation': await isar.reputations.where().exportJson(),
    'NpcRelation': await isar.npcRelations.where().exportJson(),
    'Sect': await isar.sects.where().exportJson(),
    'SectEvent': await isar.sectEvents.where().exportJson(),
    'PvpRecord': await isar.pvpRecords.where().exportJson(),
    'PvpSnapshot': await isar.pvpSnapshots.where().exportJson(),
    'BossMemory': await isar.bossMemorys.where().exportJson(),
    'EquipmentCatalogEntry': await isar.equipmentCatalogEntrys
        .where()
        .exportJson(),
    'ExpeditionRun': await isar.expeditionRuns.where().exportJson(),
    'ExpeditionMilestoneRecord': await isar.expeditionMilestoneRecords
        .where()
        .exportJson(),
    'BossGauntletRun': await isar.bossGauntletRuns.where().exportJson(),
    'DurableActivityCombatRun': await isar.durableActivityCombatRuns
        .where()
        .exportJson(),
    'RewardClaimReceipt': await isar.rewardClaimReceipts.where().exportJson(),
    'ProgressiveUnlockReceipt': await isar.progressiveUnlockReceipts
        .where()
        .exportJson(),
  };
  expect(
    facts.keys.toSet(),
    IsarSetup.schemasForTesting.map((schema) => schema.name).toSet(),
  );
  return facts;
}
