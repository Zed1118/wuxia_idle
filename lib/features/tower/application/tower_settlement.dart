import 'dart:math' as math;

import 'package:isar_community/isar.dart';

import '../../../core/application/system_clock_provider.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/tower_floor_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/derived_stats.dart';
import '../../../shared/battle_shared/reward_claim_key.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/rng.dart';
import '../../activity/application/durable_activity_automation_service.dart';
import '../../activity/domain/durable_activity_combat_run.dart';
import '../../combat_shared/application/combat_progression_settlement_service.dart';
import '../../combat_shared/application/combat_resolution_service.dart'
    show CombatResolutionService;
import '../../combat_shared/domain/combat_stats_summary.dart';
import '../../combat_shared/domain/hero_camera_data.dart';
import '../../cultivation/application/stage_skill_drop_hook.dart';
import '../../cultivation/domain/advancement_entry.dart';
import '../../cultivation/domain/skill_drop_result.dart';
import '../../cultivation/domain/skill_unlock_service.dart';
import '../../equipment/application/drop_service.dart';
import '../../equipment/domain/resonance_upgrade_notice.dart';
import '../../event/application/game_event_service.dart';
import '../../expedition/application/expedition_timeline.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../reward/application/durable_reward_claim_service.dart';
import '../../reward/application/reward_claim_plan.dart';
import '../../seclusion/application/offline_passive_service.dart';
import '../../weapon_codex/application/equipment_catalog_service.dart';
import 'tower_personal_record_service.dart';
import 'tower_progress_service.dart';

typedef TowerCombatResolution = ({
  List<AdvancementEntry> advancements,
  List<ResonanceUpgradeNotice> resonanceUpgrades,
  CombatStatsSummary stats,
  HeroCameraData? heroCamera,
  String? participantName,
  int lightInjuryStacksAdded,
  double heavyInjuryHoursAdded,
});

typedef TowerVictorySettlement = ({
  TowerClearResult clearResult,
  TowerCombatResolution resolution,
  SkillDropResult skillDrop,
  DropResult drops,
});

/// 九霄塔结算所需依赖，按原读取位置惰性解析以保留短路与读取时序。
class TowerSettlementDependencies {
  const TowerSettlementDependencies({
    required Isar? Function() readIsar,
    required NumbersConfig Function() readNumbers,
    required DropService Function() readDropService,
    required Rng Function() readRng,
    required math.Random Function() readMathRandom,
    SystemClock Function()? readClock,
    math.Random? Function()? readEventRandom,
  }) : _readIsar = readIsar,
       _readNumbers = readNumbers,
       _readDropService = readDropService,
       _readRng = readRng,
       _readClock = readClock,
       _readEventRandom = readEventRandom,
       _readMathRandom = readMathRandom;

  final Isar? Function() _readIsar;
  final NumbersConfig Function() _readNumbers;
  final DropService Function() _readDropService;
  final Rng Function() _readRng;
  final math.Random Function() _readMathRandom;
  final SystemClock Function()? _readClock;
  final math.Random? Function()? _readEventRandom;

  Isar? get isar => _readIsar();
  NumbersConfig get numbers => _readNumbers();
  DropService get dropService => _readDropService();
  Rng get rng => _readRng();
  math.Random get mathRandom => _readMathRandom();
  SystemClock get clock => _readClock?.call() ?? const SystemClock();

  /// 事件文案单独注入，默认保持旧随机源，不消耗技能残页的随机序列。
  math.Random? get eventRandom => _readEventRandom?.call();
}

/// U09 九霄塔胜利的单一原子结算边界。
///
/// 塔进度、首通掉落、重打残页、战斗成长与 receipt 共享
/// 同一 write transaction；任一写入失败都整体回滚。
Future<TowerVictorySettlement> applyTowerVictorySettlement({
  required TowerSettlementDependencies dependencies,
  required TowerFloorDef floor,
  required int participantId,
  required int elapsedMs,
  CombatSettlementSnapshot? settlementSnapshot,
  String? rewardOccurrenceId,
  DateTime? settlementAt,
  DurableActivitySettlementContext? durableActivitySettlement,
  Future<void> Function()? afterProgressInTxn,
}) async {
  final isar = dependencies.isar;
  if (isar == null) {
    throw StateError('Tower reward settlement storage is unavailable');
  }
  if (settlementSnapshot == null ||
      !settlementSnapshot.isFinished ||
      settlementSnapshot.playerCharacterId != participantId) {
    throw StateError('Tower victory participant cannot be proven');
  }
  final now = settlementAt ?? dependencies.clock.now();
  return ExpeditionTimeline.runAfterCatchUp(
    isar: isar,
    now: now,
    action: () async {
      final progressService = TowerProgressService(isar: isar);
      final personalRecordService = TowerPersonalRecordService(isar: isar);
      final progress = await progressService.getOrCreate(
        saveDataId: IsarSetup.currentSlotId,
        clock: SystemClock.fixed(now),
      );
      final maxFloor = GameRepository.instance.towerMaxFloor;
      final isFirstClear =
          floor.floorIndex == progress.highestClearedFloor + 1 &&
          floor.floorIndex >= 1 &&
          floor.floorIndex <= maxFloor;
      final cycle = progress.currentCycleIndex;
      final occurrenceId = rewardOccurrenceId?.trim().isNotEmpty == true
          ? rewardOccurrenceId!.trim()
          : 'tower:$cycle:${floor.floorIndex}:$participantId:'
                '${now.microsecondsSinceEpoch}';

      var drops = const DropResult(equipments: <Equipment>[], items: []);
      if (isFirstClear && GameRepository.isLoaded) {
        final dropService = DropService(
          equipmentDefLookup: GameRepository.instance.getEquipment,
          defaultObtainedFrom: UiStrings.towerDropSource,
          now: SystemClock.fixed(now).now,
        );
        final rng = dependencies.rng;
        drops = dropService.rollTowerRewards(floor, rng);
        final bonus = dropService.rollRareBonus(
          baseTier: RealmUtils.equipmentTierCapOf(floor.requiredRealm),
          config: GameRepository.instance.numbers.rareBonusDrop,
          rng: rng,
          poolForTier: (tier) => GameRepository.instance.equipmentDefs.values
              .where((equipment) => equipment.tier == tier)
              .toList(growable: false),
          obtainedFrom: UiStrings.dropSourceRareBonus,
        );
        if (bonus != null) {
          drops = DropResult(
            equipments: [...drops.equipments, bonus],
            items: drops.items,
          );
        }
      }

      final claimPlan = RewardClaimPlan.forSettlement(
        contentKind: RewardContentKind.tower,
        contentId: 'tower_floor_${floor.floorIndex}_cycle_$cycle',
        saveDataId: IsarSetup.currentSlotId,
        participantId: participantId,
        occurrenceId: occurrenceId,
        includesFirstClear: isFirstClear,
      );
      late TowerClearResult clearResult;
      late TowerCombatResolution resolution;
      var skillDrop = SkillDropResult.none;
      final rewardClaims = DurableRewardClaimService(isar);
      Future<void> applyInTxn(bool grantsFirstClear) async {
        clearResult = await progressService.recordClearInTxn(
          floorIndex: floor.floorIndex,
          now: now,
          elapsedMs: elapsedMs,
          maxFloor: maxFloor,
        );
        if (clearResult.isFirstClear != isFirstClear) {
          throw StateError(
            'Tower first-clear snapshot changed during settlement',
          );
        }
        await personalRecordService.recordVictoryInTxn(
          saveDataId: IsarSetup.currentSlotId,
          participantId: participantId,
          floorIndex: floor.floorIndex,
          elapsedMs: elapsedMs,
          now: now,
        );
        await afterProgressInTxn?.call();
        // 已存在首通收据时，进度仍是权威来源。
        // 收据只抑制专属授予及对应掉落展示。
        if (!grantsFirstClear) {
          drops = const DropResult(equipments: <Equipment>[], items: []);
        }
        resolution = await applyTowerCombatResolution(
          dependencies: dependencies,
          floor: floor,
          grantsFirstClearExperience: grantsFirstClear,
          expectedParticipantId: participantId,
          settlementSnapshot: settlementSnapshot,
          transactionOwned: true,
          settlementAt: now,
        );
        if (floor.dropSkillFragmentId != null && GameRepository.isLoaded) {
          skillDrop = await runTowerSkillDropHookAfterVictoryInTxn(
            floor: floor,
            svc: SkillUnlockService(
              isar,
              fragmentThreshold:
                  GameRepository.instance.numbers.skillUnlock.fragmentThreshold,
            ),
            towerFragmentDropProb: GameRepository
                .instance
                .numbers
                .skillUnlock
                .towerFragmentDropProb,
            rng: dependencies.mathRandom,
          );
        }
        await persistTowerDropsInTxn(
          isar: isar,
          clock: SystemClock.fixed(now),
          random: dependencies.eventRandom,
          drops: drops,
          floor: floor,
          now: now,
        );
        await EquipmentCatalogService(isar: isar).recordAcquisitionsInTxn(
          saveDataId: IsarSetup.currentSlotId,
          defIds: [for (final equipment in drops.equipments) equipment.defId],
          from: UiStrings.weaponCodexSourceTowerFloor(floor.floorIndex),
          now: now,
        );
      }

      if (durableActivitySettlement == null) {
        final disposition = await rewardClaims.claimSettlement(
          plan: claimPlan,
          sourceSettlementId: occurrenceId,
          at: now,
          applyInTxn: applyInTxn,
        );
        if (disposition != RewardClaimDisposition.applied) {
          throw StateError('Tower reward settlement was already applied');
        }
      } else {
        final disposition = await durableActivitySettlement.service
            .commitSettlement(
              runId: durableActivitySettlement.runId,
              outcome: DurableActivityOutcome.victory,
              now: now,
              applyInTxn: () async {
                final rewardDisposition = await rewardClaims
                    .claimSettlementInTxn(
                      plan: claimPlan,
                      sourceSettlementId: occurrenceId,
                      at: now,
                      applyInTxn: applyInTxn,
                    );
                if (rewardDisposition != RewardClaimDisposition.applied) {
                  throw StateError(
                    'Tower reward settlement was already applied',
                  );
                }
              },
            );
        if (disposition != DurableActivitySettlementDisposition.applied) {
          throw StateError('Tower durable settlement was already applied');
        }
      }
      return (
        clearResult: clearResult,
        resolution: resolution,
        skillDrop: skillDrop,
        drops: drops,
      );
    },
  );
}

/// 九霄塔单人战斗结算（in-place 副作用 + 写回 Isar）。
///
/// 与主线 `_applyVictoryResolution` 体例对齐，但传 `stageDef: null` 让
/// [BattleResolutionService.resolve] 不内部 roll drops（爬塔走 rollTowerRewards
/// + 首通发奖控制，落地在 _persistDrops；此函数只消费真实参战者的
/// battleCount / skillUsage / cultivationEvents 副作用）。
///
/// [grantsFirstClearExperience] 只在首通胜利为 true；重打与败北均不发经验。
///
/// **错误兜底**：Isar 未 ready / 角色为空 / finalState 异常 → 返回空 list，
/// caller dialog 仅显 drop 部分不显升层 banner（不阻塞 victory dialog / narrative）。
///
/// W15 #30 P3 后续 A:返回升层结果 list 供 caller push `_showVictoryDialog`
/// 时显多角色升层 banner。
/// P1.1 候选 3-a:record 加 `resonanceUpgrades` 供 dialog 显共鸣度晋阶 sub-row。
Future<TowerCombatResolution> applyTowerCombatResolution({
  required TowerSettlementDependencies dependencies,
  required TowerFloorDef floor,
  required bool grantsFirstClearExperience,
  int? expectedParticipantId,
  CombatSettlementSnapshot? settlementSnapshot,
  bool transactionOwned = false,
  DateTime? settlementAt,
}) async {
  const empty = (
    advancements: <AdvancementEntry>[],
    resonanceUpgrades: <ResonanceUpgradeNotice>[],
    stats: CombatStatsSummary(totalDamage: 0, critCount: 0, totalTicks: 0),
    heroCamera: null as HeroCameraData?,
    participantName: null as String?,
    lightInjuryStacksAdded: 0,
    heavyInjuryHoursAdded: 0.0,
  );
  final isar = dependencies.isar;
  if (isar == null) return empty;
  if (settlementSnapshot == null) return empty;
  final combatSettlement = settlementSnapshot;
  if (!combatSettlement.isFinished) return empty;
  final stats = CombatStatsSummary.fromSettlement(combatSettlement);

  final resolvedParticipantId =
      expectedParticipantId ?? combatSettlement.playerCharacterId;
  if (combatSettlement.playerCharacterId != resolvedParticipantId) {
    return empty;
  }
  final now = settlementAt ?? dependencies.clock.now();
  if (!transactionOwned) {
    return ExpeditionTimeline.runAfterCatchUp(
      isar: isar,
      now: now,
      action: () => isar.writeTxn(
        () => applyTowerCombatResolution(
          dependencies: dependencies,
          floor: floor,
          grantsFirstClearExperience: grantsFirstClearExperience,
          expectedParticipantId: resolvedParticipantId,
          settlementSnapshot: combatSettlement,
          transactionOwned: true,
          settlementAt: now,
        ),
      ),
    );
  }
  await OfflinePassiveService.settleWithinTxn(
    settleIslandBeforeGrowth: true,
    isar: isar,
    now: now,
    updatePresence: true,
  );
  final ids = [resolvedParticipantId];
  final save = await isar.saveDatas.get(0);

  final characters = <Character>[];
  final equipsByCh = <int, List<Equipment>>{};
  final techsByCh = <int, List<Technique>>{};
  for (final cid in ids) {
    final c = await isar.characters.get(cid);
    if (c == null) continue;
    characters.add(c);

    final eqs = <Equipment>[];
    for (final eqId in [
      c.equippedWeaponId,
      c.equippedArmorId,
      c.equippedAccessoryId,
    ]) {
      if (eqId == null) continue;
      final e = await isar.equipments.get(eqId);
      if (e != null) eqs.add(e);
    }
    equipsByCh[c.id] = eqs;

    final ts = await isar.techniques
        .where()
        .filter()
        .ownerCharacterIdEqualTo(c.id)
        .findAll();
    // W13 fix: Isar @embedded list 反序列化为 fixed-length,
    // skillUsageCount.increment 走 add 分支会抛 UnsupportedError。
    // 转 growable copy 让后续 _accumulateSkillUsage 可写。
    for (final t in ts) {
      t.skillUsageCount = List.of(t.skillUsageCount);
    }
    techsByCh[c.id] = ts;
  }
  if (characters.isEmpty) return empty;

  final participant = characters.single;
  final lightInjuryStacksBefore = participant.lightInjuryStacks;
  final heavyInjuryHoursBefore = participant.injuryHoursRemaining;

  final numbers = dependencies.numbers;
  final dropSvc = dependencies.dropService;

  final battleResult = CombatResolutionService.resolveSnapshot(
    settlement: combatSettlement,
    participatingCharacters: characters,
    equipmentsByCharacter: equipsByCh,
    techniquesByCharacter: techsByCh,
    // 同主线结算:随机源走 rngProvider,保持可注入。
    rng: dependencies.rng,
    progressToNextMap: numbers.cultivationProgressToNext,
    techniqueDefLookup: GameRepository.instance.getTechnique,
    dropService: dropSvc,
    numbersConfig: numbers,
    // stageDef: null —— 爬塔不走 service 内部 roll drops；drops 在外层
    // rollTowerRewards + _persistDrops 单独控制（首通才发奖）
    // 双层伤势：Boss/小 Boss 楼层(bossKind != null,即 5/10/15/20/25/30)算硬仗,
    // 用语义 floor.isBoss 而非 magic %5 防 drift。resolve 内部据此判定伤势 mutate
    // character；经下方 writeTxn putAll(characters) 落库。
    isHardFight: floor.isBoss,
  );

  final progress = await IsarSetup.instance.mainlineProgress
      .filter()
      .saveDataIdEqualTo(IsarSetup.currentSlotId)
      .findFirst();
  final settlement = CombatProgressionSettlementService(
    GameRepository.instance,
  );
  // 爬塔经验只在首通发放，重打保持零经验。
  final advancements = settlement.applyExperience(
    characters: characters,
    experienceReward: grantsFirstClearExperience ? floor.baseExpReward : 0,
    clearedStageIds: progress?.clearedStageIds.toSet() ?? <String>{},
  );

  final founderId = save?.founderCharacterId;
  // P1.1 候选 3-a:writeTxn 内 push notice,函数末 return 给 caller 传 dialog。
  var resonanceUpgrades = const <ResonanceUpgradeNotice>[];
  Future<void> persistInTxn() async {
    await isar.characters.putAll(characters);
    for (final list in techsByCh.values) {
      if (list.isNotEmpty) await isar.techniques.putAll(list);
    }
    for (final list in equipsByCh.values) {
      if (list.isNotEmpty) await isar.equipments.putAll(list);
    }

    resonanceUpgrades = await settlement.recordCommonEvents(
      isar: isar,
      clock: SystemClock.fixed(now),
      random: dependencies.eventRandom,
      characters: characters,
      equipmentsByCharacter: equipsByCh,
      resonanceUpgradedEquipmentIds: battleResult.resonanceUpgradedEquipmentIds,
      advancements: advancements,
      founderId: founderId,
      bossVictory: floor.isBoss && grantsFirstClearExperience
          ? BossVictoryEventContext(
              stageId: 'tower_floor_${floor.floorIndex}',
              stageName: UiStrings.towerFloorLabel(floor.floorIndex),
              bossName: floor.enemyTeam.isNotEmpty
                  ? floor.enemyTeam.last.name
                  : UiStrings.towerFloorLabel(floor.floorIndex),
              warbornEquipment: founderId == null
                  ? const []
                  : equipsByCh[founderId] ?? const [],
            )
          : null,
    );
  }

  await persistInTxn();

  // 第七阶段 批一:派生英雄镜头数据（本场最高输出玩家）。纯展示，不改数值。
  final bossName = floor.enemyTeam.isNotEmpty
      ? floor.enemyTeam.last.name
      : UiStrings.towerFloorLabel(floor.floorIndex);
  final heroCamera = deriveHeroCameraDataFromDamageTotals(
    damageByCharacterId: combatSettlement.damageByCharacterId,
    characters: characters,
    bossName: bossName,
  );

  return (
    advancements: advancements,
    resonanceUpgrades: resonanceUpgrades,
    stats: stats,
    heroCamera: heroCamera,
    participantName: characters.single.name,
    lightInjuryStacksAdded: math.max(
      0,
      participant.lightInjuryStacks - lightInjuryStacksBefore,
    ),
    heavyInjuryHoursAdded: math.max(
      0.0,
      participant.injuryHoursRemaining - heavyInjuryHoursBefore,
    ),
  );
}

Future<void> persistTowerDropsInTxn({
  required Isar isar,
  SystemClock clock = const SystemClock(),
  math.Random? random,
  required DropResult drops,
  required TowerFloorDef? floor,
  required DateTime now,
}) async {
  final save = await isar.saveDatas.get(0);
  final founderId = save?.founderCharacterId;
  if (drops.equipments.isNotEmpty) {
    await isar.equipments.putAll(drops.equipments);
  }
  for (final item in drops.items) {
    final existing = await isar.inventoryItems.getByDefId(item.defId);
    if (existing != null) {
      existing.quantity += item.quantity;
      existing.lastObtainedAt = now;
      await isar.inventoryItems.put(existing);
    } else {
      await isar.inventoryItems.put(
        InventoryItem()
          ..defId = item.defId
          ..itemType = ItemType.fromDefId(item.defId)
          ..quantity = item.quantity
          ..firstObtainedAt = now
          ..lastObtainedAt = now,
      );
    }
  }

  if (drops.equipments.isNotEmpty && floor != null) {
    final events = GameEventService(isar, clock: clock, random: random);
    final source = UiStrings.towerFloorLabel(floor.floorIndex);
    for (final drop in drops.equipments) {
      final def = GameRepository.instance.getEquipment(drop.defId);
      await events.recordEquipmentObtained(
        characterId: founderId,
        equipmentId: drop.id,
        equipmentDefId: drop.defId,
        equipmentName: def.name,
        source: source,
        equipment: drop,
      );
    }
  }
}
