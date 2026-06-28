import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_service.dart';
import 'package:wuxia_idle/features/equipment/application/enhancement_service.dart';
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
      'wuxia_onboarding_first_30min_',
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

  test('production 单人空手开局首关不应右队胜', () async {
    final result = await _runStage('stage_01_01');

    expect(
      result.leftCount,
      1,
      reason: '必须覆盖 production soloStart=true 单人路径',
    );
    expect(
      result.result,
      isNot(BattleResult.rightWin),
      reason: 'stage_01_01 不应成为生产单人新档的首战失败点',
    );
    expect(
      result.tick,
      lessThan(1000),
      reason: 'stage_01_01 不应撞 maxTicks 兜底',
    );
  });

  test('production 单人开局按首胜成长和掉落整备后 stage_01_02 至 stage_01_04 不应右队胜',
      () async {
    const stageIds = [
      'stage_01_02',
      'stage_01_03',
      'stage_01_04',
    ];

    await _grantVictoryRewardsAndEquip('stage_01_01');

    for (final stageId in stageIds) {
      final result = await _runStage(stageId);
      expect(
        result.leftCount,
        1,
        reason: '$stageId 必须覆盖 production soloStart=true 单人路径',
      );
      expect(
        result.result,
        isNot(BattleResult.rightWin),
        reason: '$stageId 不应成为首胜成长后的前 30 分钟失败点；${result.summary}',
      );
      expect(
        result.tick,
        lessThan(1000),
        reason: '$stageId 不应撞 maxTicks 兜底',
      );
      if (result.result == BattleResult.leftWin) {
        await _grantVictoryRewardsAndEquip(stageId);
      }
    }
  });

  test('production 单人空手开局 stage_01_05 章末 Boss 至少有确定终态', () async {
    final result = await _runStage('stage_01_05');

    expect(result.leftCount, 1);
    expect(result.result, isNotNull);
    expect(
      result.tick,
      lessThan(1000),
      reason: '章末 Boss 可以作为拍板项，但不能卡死或无终态',
    );
  });
}

Future<void> _grantVictoryRewardsAndEquip(String stageId) async {
  final isar = IsarSetup.instance;
  final stage = GameRepository.instance.getStage(stageId);
  final save = await isar.saveDatas.get(0);
  final activeIds = save?.activeCharacterIds ?? const <int>[];

  await isar.writeTxn(() async {
    for (final characterId in activeIds) {
      final ch = await isar.characters.get(characterId);
      if (ch == null) continue;
      CharacterAdvancementService.applyExperience(
        ch,
        stage.baseExpReward,
        realmLookup: GameRepository.instance.getRealm,
      );
      await isar.characters.put(ch);
    }
  });

  final drops = DropService(
    equipmentDefLookup: GameRepository.instance.getEquipment,
  ).rollDrops(stage, DefaultRng(seed: _seedForStage(stageId)));
  if (drops.equipments.isNotEmpty) {
    await isar.writeTxn(() => isar.equipments.putAll(drops.equipments));
    final equipService = EquipmentService(isar: isar);
    for (final eq in drops.equipments) {
      await equipService.equip(characterId: activeIds.first, equipmentId: eq.id);
    }
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
  await _enhanceEquippedGear();
}

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
        rng: DefaultRng(seed: 7 + equipmentId + eq.enhanceLevel),
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
    leftCount: left.length,
    result: terminal.result,
    tick: terminal.tick,
    summary:
        'left=${left.map((c) => '${c.name}(hp=${c.maxHp},atk=${c.totalEquipmentAttack},if=${c.maxInternalForce},skills=${c.availableSkills.length})').join(', ')} '
        'right=${right.map((c) => '${c.name}(hp=${c.maxHp},atk=${c.totalEquipmentAttack})').join(', ')}',
  );
}

int _seedForStage(String stageId) {
  const seeds = {
    'stage_01_01': 10101,
    'stage_01_02': 10102,
    'stage_01_03': 10103,
    'stage_01_04': 10104,
    'stage_01_05': 10105,
  };
  return seeds[stageId] ?? 1;
}

class _StageRunResult {
  const _StageRunResult({
    required this.leftCount,
    required this.result,
    required this.tick,
    required this.summary,
  });

  final int leftCount;
  final BattleResult? result;
  final int tick;
  final String summary;
}
