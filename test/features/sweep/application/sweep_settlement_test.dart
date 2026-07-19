import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/battle_providers.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_settlement.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_sweep_settle_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('主线战备不足时返回忽略项且不透支战备', (tester) async {
    await tester.runAsync(() async {
      final save = await IsarSetup.currentSaveData();
      await IsarSetup.instance.writeTxn(() async {
        save!
          ..sweepReadinessPoints = 0
          ..sweepReadinessLastRecoveredAt = DateTime.now();
        await IsarSetup.instance.saveDatas.put(save);
      });
    });

    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(child: _RefHarness(onReady: (value) => ref = value)),
    );
    final outcome = await tester.runAsync(
      () => settleMainlineSweepVictory(ref: ref, stage: _stage, cycle: 1),
    );

    final after = await tester.runAsync(IsarSetup.currentSaveData);
    expect(outcome, isNotNull);
    expect(outcome!.ignoredDrops, 1);
    expect(outcome.equipmentDrops, 0);
    expect(outcome.itemsByDefId, isEmpty);
    expect(outcome.expGained, 0);
    expect(after!.sweepReadinessPoints, 0);
  });

  testWidgets('爬塔重打记录层数但不发装备、物品或经验', (tester) async {
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(child: _RefHarness(onReady: (value) => ref = value)),
    );
    final outcome = await tester.runAsync(
      () => settleTowerSweepVictory(ref: ref, floor: _floor),
    );

    final progress = await tester.runAsync(
      () => TowerProgressService(
        isar: IsarSetup.instance,
      ).getOrCreate(saveDataId: IsarSetup.currentSlotId),
    );
    expect(progress!.highestClearedFloor, 1);
    expect(outcome, isNotNull);
    expect(outcome!.equipmentDrops, 0);
    expect(outcome.itemsByDefId, isEmpty);
    expect(outcome.expGained, 0);
    expect(outcome.skillFragments, 0);
  });

  /// 主线战备充足的成功路径(2026-07-19 夜批 coverage 补强,文件基线 16/50)。
  ///
  /// 真 finished BattleState 注 battleProvider(体例沿
  /// apply_victory_resolution_test 的 _StaticBattleNotifier + runWithRef),
  /// 钉 `settleMainlineSweepVictory` 成功段行为:
  ///   - 战备 3 → 2(扣 1 点)
  ///   - 掉落 recap:装备计 1、银两聚合、秘籍(item_scroll_*)滤入 ignoredDrops
  ///   - expGained = stage.baseExpReward
  ///   - MainlineProgress.recordVictory 落 clearedStageIds
  testWidgets('主线战备充足:扣战备 + 掉落 recap + 进度落库', (tester) async {
    final charId = (await tester.runAsync(() async {
      final c = Character.create(
        name: '祖师',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 7, 19),
        internalForce: 3000,
      );
      final cid = await IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.characters.put(c),
      );
      final save = await IsarSetup.currentSaveData();
      await IsarSetup.instance.writeTxn(() async {
        save!
          ..activeCharacterIds = [cid]
          ..sweepReadinessPoints = 3
          ..sweepReadinessLastRecoveredAt = DateTime.now();
        await IsarSetup.instance.saveDatas.put(save);
      });
      return cid;
    }))!;

    const stage = StageDef(
      id: 'stage_sweep_test',
      name: 'test stage',
      stageType: StageType.mainline,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: [],
      isBossStage: false,
      baseExpReward: 100,
      difficultyMultiplier: 1,
      dropTable: [
        EquipmentDrop(
          equipmentDefId: 'weapon_xunchang_tie_jian',
          dropChance: 1.0,
        ),
        ItemDrop(
          inventoryItemDefId: 'item_silver',
          quantityMin: 5,
          quantityMax: 5,
          dropChance: 1.0,
        ),
        ItemDrop(
          inventoryItemDefId: 'item_scroll_kai_bei_shou',
          quantityMin: 1,
          quantityMax: 1,
          dropChance: 1.0,
        ),
      ],
    );

    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          battleProvider.overrideWith(
            () => _StaticBattleNotifier(_finishedBattle([charId])),
          ),
        ],
        child: _RefHarness(onReady: (value) => ref = value),
      ),
    );
    final outcome = await tester.runAsync(
      () => settleMainlineSweepVictory(ref: ref, stage: stage, cycle: 1),
    );

    expect(outcome, isNotNull);
    expect(outcome!.equipmentDrops, 1, reason: 'dropChance=1.0 必掉铁剑');
    expect(outcome.itemsByDefId, {
      'item_silver': 5,
    }, reason: '银两聚合入 recap;秘籍不计');
    expect(
      outcome.ignoredDrops,
      1,
      reason: '扫荡恒重打:item_scroll_* 滤入 ignoredDrops(§5.1 防刷)',
    );
    expect(outcome.expGained, 100, reason: 'expGained = stage.baseExpReward');

    await tester.runAsync(() async {
      final after = await IsarSetup.currentSaveData();
      expect(after!.sweepReadinessPoints, 2, reason: '成功结算扣 1 点战备');

      final progress = await IsarSetup.instance.mainlineProgress
          .filter()
          .saveDataIdEqualTo(IsarSetup.currentSlotId)
          .findFirst();
      expect(
        progress!.clearedStageIds,
        contains('stage_sweep_test'),
        reason: 'recordVictory 幂等落进度',
      );
    });
  });
}

/// 造 finished BattleState:左队含全部参战 id(resolve 的
/// _assertAllParticipated 要求),右队一个木桩,result=leftWin。
BattleState _finishedBattle(List<int> participantIds) {
  BattleCharacter battleChar({
    required int id,
    required String name,
    required int teamSide,
    int slotIndex = 0,
  }) => BattleCharacter(
    characterId: id,
    name: name,
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    maxHp: 8000,
    currentHp: 8000,
    maxInternalForce: 3000,
    currentInternalForce: 3000,
    speed: 200,
    criticalRate: 0.1,
    evasionRate: 0.05,
    defenseRate: 0.10,
    totalEquipmentAttack: 500,
    mainCultivationLayer: CultivationLayer.chuKui,
    availableSkills: const [],
    skillCooldowns: const {},
    activeBuffs: const [],
    actionPoint: 300,
    isAlive: true,
    teamSide: teamSide,
    slotIndex: slotIndex,
  );

  final left = [
    for (var i = 0; i < participantIds.length; i++)
      battleChar(
        id: participantIds[i],
        name: '参战${participantIds[i]}',
        teamSide: 0,
        slotIndex: i,
      ),
  ];
  final right = [battleChar(id: 9001, name: '木桩', teamSide: 1)];
  return BattleState.initial(
    leftTeam: left,
    rightTeam: right,
  ).copyWith(result: BattleResult.leftWin);
}

/// 静态 finished BattleState 的 BattleNotifier(沿
/// apply_victory_resolution_test 的 _StaticBattleNotifier 模式)。
class _StaticBattleNotifier extends BattleNotifier {
  _StaticBattleNotifier(this._initial);
  final BattleState _initial;

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  @override
  void advanceOneAction({int maxConsecutiveSteps = 300}) {}

  @override
  void step() {}
}

const _stage = StageDef(
  id: 'stage_sweep_test',
  name: 'test stage',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [],
  isBossStage: false,
  baseExpReward: 100,
  difficultyMultiplier: 1,
);

const _floor = TowerFloorDef(
  floorIndex: 1,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [],
);

class _RefHarness extends ConsumerWidget {
  const _RefHarness({required this.onReady});

  final ValueChanged<WidgetRef> onReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onReady(ref);
    return const SizedBox.shrink();
  }
}
