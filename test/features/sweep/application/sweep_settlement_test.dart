import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_settlement.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/shared/utils/rng_provider.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';

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

  testWidgets('显式 0A 快照透传结算：只更新祖师，替补零污染且战备恰扣一', (tester) async {
    final founderId = (await tester.runAsync(_seedFounderWithReadiness))!;
    final reserveId = (await tester.runAsync(() async {
      final reserve = Character.create(
        name: '替补',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026, 8, 22),
        internalForce: 3000,
      );
      final id = await IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.characters.put(reserve),
      );
      final save = await IsarSetup.currentSaveData();
      await IsarSetup.instance.writeTxn(() async {
        save!.activeCharacterIds = [founderId, id];
        await IsarSetup.instance.saveDatas.put(save);
      });
      return id;
    }))!;
    final settlement = CombatSettlementSnapshot(
      result: BattleResult.leftWin,
      totalTicks: 12,
      hadActions: true,
      participants: [
        CombatParticipantSnapshot(
          characterId: founderId,
          currentHp: 7000,
          maxHp: 8000,
        ),
      ],
      skillCasts: const [],
      totalDamage: 321,
      criticalCount: 2,
      damageByCharacterId: {founderId: 321},
    );
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rngProvider.overrideWithValue(_NoRareBonusRng())],
        child: _RefHarness(onReady: (value) => ref = value),
      ),
    );

    final outcome = await tester.runAsync(
      () => settleMainlineSweepVictory(
        ref: ref,
        stage: _dropStage,
        cycle: 1,
        settlementSnapshot: settlement,
        expectedParticipantId: founderId,
      ),
    );

    expect(outcome, isNotNull);
    final headlessReplayOutcome = await tester.runAsync(
      () => settleMainlineHeadlessReplayVictory(
        ref: ref,
        stage: _dropStage,
        cycle: 1,
        settlementSnapshot: settlement,
        expectedParticipantId: founderId,
      ),
    );
    expect(headlessReplayOutcome, isNotNull);
    await tester.runAsync(() async {
      final founder = await IsarSetup.instance.characters.get(founderId);
      final reserve = await IsarSetup.instance.characters.get(reserveId);
      final save = await IsarSetup.currentSaveData();
      expect(founder!.experience, greaterThan(0));
      expect(reserve!.experience, 0);
      expect(save!.sweepReadinessPoints, 2);
    });
  });

  testWidgets('错人 settlement 在扣战备前 fail closed，快速重演不扣战备', (tester) async {
    final founderId = (await tester.runAsync(_seedFounderWithReadiness))!;
    final settlement = CombatSettlementSnapshot(
      result: BattleResult.leftWin,
      totalTicks: 12,
      hadActions: true,
      participants: const [
        CombatParticipantSnapshot(characterId: 999999, currentHp: 1, maxHp: 1),
      ],
      skillCasts: const [],
      totalDamage: 1,
      criticalCount: 0,
      damageByCharacterId: const {999999: 1},
    );
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(child: _RefHarness(onReady: (value) => ref = value)),
    );

    await expectLater(
      settleMainlineSweepVictory(
        ref: ref,
        stage: _stage,
        cycle: 1,
        settlementSnapshot: settlement,
        expectedParticipantId: founderId,
      ),
      throwsStateError,
    );
    var save = await tester.runAsync(IsarSetup.currentSaveData);
    expect(save!.sweepReadinessPoints, 3);

    await expectLater(
      settleMainlineHeadlessReplayVictory(
        ref: ref,
        stage: _stage,
        cycle: 1,
        settlementSnapshot: settlement,
        expectedParticipantId: founderId,
      ),
      throwsStateError,
    );
    save = await tester.runAsync(IsarSetup.currentSaveData);
    expect(save!.sweepReadinessPoints, 3);
  });
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

/// 同 [_stage] 但带固定掉落表:铁剑(必掉)+ 银两 + 秘籍(扫荡滤入 ignoredDrops)。
const _dropStage = StageDef(
  id: 'stage_sweep_test',
  name: 'test stage',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [],
  isBossStage: false,
  baseExpReward: 100,
  difficultyMultiplier: 1,
  dropTable: [
    EquipmentDrop(equipmentDefId: 'weapon_xunchang_tie_jian', dropChance: 1.0),
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

/// 建祖师 + 战备 3 点,返回 characterId(两条成功路径共用)。
Future<int> _seedFounderWithReadiness() async {
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
}

/// 稀有彩头必不中:`nextDouble` 恒 0.999 → 各档 `< chance` 全不成立。
/// 固定掉落判定是 `nextDouble() >= dropChance` 才跳过,dropChance=1.0 仍照掉。
class _NoRareBonusRng implements Rng {
  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => 0.999;

  @override
  T pick<T>(List<T> list) => list.first;
}

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
