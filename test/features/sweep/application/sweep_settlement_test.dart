import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_settlement.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';

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
