import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/equipment/application/enhancement_service.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_service.dart';
import 'package:wuxia_idle/features/inventory/application/item_use_service.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_solo_mainline_ch1_ch6_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'production 单人主线 Ch1-6 连续整备路径没有 1v3 硬卡死',
    () async {
      final rows = <_StageRunResult>[];

      for (final stageId in _mainlineStageIds) {
        final stage = GameRepository.instance.getStage(stageId);
        await _advanceFounderToRequiredRealm(stage.requiredRealm);
        await _equipRealmCapMainTechnique();
        await _equipBestAvailableForActiveFounder();
        final result = await _runStage(stageId);
        rows.add(result);
        expect(
          result.leftCount,
          1,
          reason: '弟子 stage_06_05 后才拜入，本测试必须保持祖师单人路径',
        );
        expect(
          result.tick,
          lessThan(1000),
          reason: '$stageId 不应撞 maxTicks 兜底；${result.summary}',
        );
        expect(
          result.result,
          isNot(BattleResult.rightWin),
          reason:
              '$stageId 不应成为生产单人 Ch1-6 连续整备硬卡；\n'
              '${rows.map((r) => r.toLogLine()).join('\n')}',
        );

        if (result.result == BattleResult.leftWin) {
          await _grantVictoryRewardsAndOptimize(stageId);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

const _mainlineStageIds = [
  'stage_01_01',
  'stage_01_02',
  'stage_01_03',
  'stage_01_04',
  'stage_01_05',
  'stage_02_01',
  'stage_02_02',
  'stage_02_03',
  'stage_02_04',
  'stage_02_05',
  'stage_03_01',
  'stage_03_02',
  'stage_03_03',
  'stage_03_04',
  'stage_03_05',
  'stage_04_01',
  'stage_04_02',
  'stage_04_03',
  'stage_04_04',
  'stage_04_05',
  'stage_05_01',
  'stage_05_02',
  'stage_05_03',
  'stage_05_04',
  'stage_05_05',
  'stage_06_01',
  'stage_06_02',
  'stage_06_03',
  'stage_06_04',
  'stage_06_05',
];

Future<void> _grantVictoryRewardsAndOptimize(String stageId) async {
  final isar = IsarSetup.instance;
  final repo = GameRepository.instance;
  final stage = repo.getStage(stageId);
  final save = await isar.saveDatas.get(0);
  final activeIds = save?.activeCharacterIds ?? const <int>[];
  if (activeIds.isEmpty) return;

  await isar.writeTxn(() async {
    for (final characterId in activeIds) {
      final ch = await isar.characters.get(characterId);
      if (ch == null) continue;
      CharacterAdvancementService.applyExperience(
        ch,
        stage.baseExpReward,
        realmLookup: repo.getRealm,
      );
      await isar.characters.put(ch);
    }
  });

  final drops = DropService(
    equipmentDefLookup: repo.getEquipment,
  ).rollDrops(stage, DefaultRng(seed: _seedForStage(stageId)));
  if (drops.equipments.isNotEmpty) {
    await isar.writeTxn(() => isar.equipments.putAll(drops.equipments));
  }
  for (final item in drops.items) {
    await isar.writeTxn(() async {
      final existing = await isar.inventoryItems.getByDefId(item.defId);
      if (existing != null) {
        existing.quantity += item.quantity;
        existing.lastObtainedAt = DateTime.now();
        await isar.inventoryItems.put(existing);
      } else {
        await isar.inventoryItems.put(
          InventoryItem()
            ..defId = item.defId
            ..itemType = ItemType.fromDefId(item.defId)
            ..quantity = item.quantity
            ..firstObtainedAt = DateTime.now()
            ..lastObtainedAt = DateTime.now(),
        );
      }
    });
  }

  await _useAllExperiencePills();
  await _equipBestAvailable(activeIds.first);
  await _enhanceEquippedGear();
}

Future<void> _advanceFounderToRequiredRealm(RealmTier requiredRealm) async {
  final isar = IsarSetup.instance;
  final repo = GameRepository.instance;
  while (true) {
    final founder = await isar.characters
        .filter()
        .isFounderEqualTo(true)
        .findFirst();
    if (founder == null) return;
    if (founder.realmTier.index >= requiredRealm.index) return;
    await isar.writeTxn(() async {
      CharacterAdvancementService.applyExperience(
        founder,
        founder.experienceToNextLayer,
        realmLookup: repo.getRealm,
      );
      founder.internalForce = founder.internalForceMax;
      await isar.characters.put(founder);
    });
  }
}

Future<void> _equipBestAvailableForActiveFounder() async {
  final isar = IsarSetup.instance;
  final save = await isar.saveDatas.get(0);
  final characterId = save?.activeCharacterIds.firstOrNull;
  if (characterId == null) return;
  await _equipBestAvailable(characterId);
}

Future<void> _equipRealmCapMainTechnique() async {
  final isar = IsarSetup.instance;
  final repo = GameRepository.instance;
  final founder = await isar.characters
      .filter()
      .isFounderEqualTo(true)
      .findFirst();
  if (founder == null) return;
  final tierCap = RealmUtils.techniqueTierCapOf(founder.realmTier);
  final current = founder.mainTechniqueId == null
      ? null
      : await isar.techniques.get(founder.mainTechniqueId!);
  if (current?.tier == tierCap && current?.school == TechniqueSchool.gangMeng) {
    return;
  }
  final def = repo.techniqueDefs.values.firstWhere(
    (d) => d.tier == tierCap && d.school == TechniqueSchool.gangMeng,
  );
  await isar.writeTxn(() async {
    final tech = Technique.create(
      defId: def.id,
      ownerCharacterId: founder.id,
      tier: def.tier,
      school: def.school,
      role: TechniqueRole.main,
      learnedAt: DateTime.now(),
      cultivationProgressToNext:
          repo.numbers.cultivationProgressToNext[CultivationLayer.daCheng]!,
      cultivationLayer: CultivationLayer.daCheng,
    );
    await isar.techniques.put(tech);
    founder.mainTechniqueId = tech.id;
    founder.school = def.school;
    await isar.characters.put(founder);
  });
}

Future<void> _useAllExperiencePills() async {
  final isar = IsarSetup.instance;
  final repo = GameRepository.instance;
  for (final defId in const [
    'item_jingyandan_large',
    'item_jingyandan_mid',
    'item_jingyandan_small',
  ]) {
    final def = repo.itemDefs[defId];
    if (def == null) continue;
    while (true) {
      final row = await isar.inventoryItems.getByDefId(defId);
      if (row == null || row.quantity <= 0) break;
      final result = await ItemUseService.use(
        isar,
        def: def,
        realmLookup: repo.getRealm,
      );
      if (result.kind != ItemUseKind.experienceApplied) break;
    }
  }
}

Future<void> _equipBestAvailable(int characterId) async {
  final isar = IsarSetup.instance;
  final character = await isar.characters.get(characterId);
  if (character == null) return;
  final all = await isar.equipments.where().findAll();
  final service = EquipmentService(isar: isar);

  for (final slot in EquipmentSlot.values) {
    final candidates =
        all
            .where(
              (e) =>
                  e.slot == slot && e.isEquippableAtRealm(character.realmTier),
            )
            .toList()
          ..sort((a, b) => _equipmentScore(b).compareTo(_equipmentScore(a)));
    for (final eq in candidates) {
      final outcome = await service.equip(
        characterId: characterId,
        equipmentId: eq.id,
      );
      if (outcome == EquipOutcome.success) break;
      if (outcome == EquipOutcome.protectedCurrentEquipment) {
        await service.unequip(characterId: characterId, slot: slot);
        final retry = await service.equip(
          characterId: characterId,
          equipmentId: eq.id,
        );
        if (retry == EquipOutcome.success) break;
      }
    }
  }
}

int _equipmentScore(Equipment eq) =>
    eq.tier.index * 100000 +
    eq.baseAttack * 100 +
    eq.baseHealth +
    eq.baseSpeed * 10 +
    eq.enhanceLevel * 1000;

Future<void> _enhanceEquippedGear() async {
  final isar = IsarSetup.instance;
  final save = await isar.saveDatas.get(0);
  final characterId = save?.activeCharacterIds.firstOrNull;
  if (characterId == null) return;
  final ch = await isar.characters.get(characterId);
  if (ch == null) return;

  final absoluteLevel = RealmUtils.absoluteLevelOf(ch.realmTier, ch.realmLayer);
  final config = GameRepository.instance.numbers.enhancement;
  final service = EnhancementService(isar: isar);
  final equipmentIds = [
    ch.equippedWeaponId,
    ch.equippedArmorId,
    ch.equippedAccessoryId,
  ].whereType<int>();

  for (final equipmentId in equipmentIds) {
    while (true) {
      final eq = await isar.equipments.get(equipmentId);
      final mojianshi = await isar.inventoryItems
          .filter()
          .itemTypeEqualTo(ItemType.moJianShi)
          .findFirst();
      if (eq == null || mojianshi == null) break;
      final result = EnhancementService.tryEnhance(
        eq: eq,
        characterAbsoluteLevel: absoluteLevel,
        rng: DefaultRng(seed: 29 + equipmentId + eq.enhanceLevel.toInt()),
        currentMojianshi: mojianshi.quantity,
        config: config,
      );
      if (result.outcome == EnhanceOutcome.capped ||
          result.outcome == EnhanceOutcome.insufficientMojianshi) {
        break;
      }
      await service.persistResult(eq: eq, result: result);
      if (!result.didLevelUp && result.mojianshiSpent == 0) break;
    }
  }
}

Future<_StageRunResult> _runStage(String stageId) async {
  final stage = GameRepository.instance.getStage(stageId);
  final (left, right) = await StageBattleSetup(
    isar: IsarSetup.instance,
  ).buildTeams(stage);
  final terminal = BattleEngine.runToEnd(
    BattleState.initial(leftTeam: left, rightTeam: right),
    GameRepository.instance.numbers,
    rng: Random(_seedForStage(stageId)),
  );
  return _StageRunResult(
    stageId: stageId,
    leftCount: left.length,
    enemyCount: right.length,
    result: terminal.result,
    tick: terminal.tick,
    summary:
        'left=${left.map((c) => '${c.name}(realm=${c.realmTier.name}.${c.realmLayer.name},hp=${c.maxHp},atk=${c.totalEquipmentAttack},if=${c.maxInternalForce},skills=${c.availableSkills.length})').join(', ')} '
        'right=${right.map((c) => '${c.name}(realm=${c.realmTier.name}.${c.realmLayer.name},hp=${c.maxHp},atk=${c.totalEquipmentAttack})').join(', ')}',
  );
}

int _seedForStage(String stageId) {
  final digits = stageId.replaceAll(RegExp('[^0-9]'), '');
  return int.parse(digits);
}

class _StageRunResult {
  const _StageRunResult({
    required this.stageId,
    required this.leftCount,
    required this.enemyCount,
    required this.result,
    required this.tick,
    required this.summary,
  });

  final String stageId;
  final int leftCount;
  final int enemyCount;
  final BattleResult? result;
  final int tick;
  final String summary;

  String toLogLine() =>
      '$stageId enemies=$enemyCount result=${result?.name} tick=$tick $summary';
}
