import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/tower/application/leaderboard_sync_service.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `tower_providers` 三 provider 行为测（2026-07-19 夜批 coverage 补强，
/// 基线 5/9 行）。
///
/// 真 Isar + 真 GameRepository，钉：
///   - towerProgress:getOrCreate 默认 highestClearedFloor=0
///   - towerFloorList:与 yaml 楼层对齐,recordClear 后层态级联推进
///   - leaderboardSync:Demo 阶段恒 NoopLeaderboardSync(0 backend 断言点)
///
/// 层数从 [_maxFloor] 派生不写死（A0 解层数硬编码）。
int get _maxFloor => GameRepository.instance.towerMaxFloor;

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_tower_prov_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('towerProgress 默认零层;recordClear 后 floorList 层态推进', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final allFloors = GameRepository.instance.towerFloors;

    var progress = await container.read(towerProgressProvider.future);
    expect(progress.highestClearedFloor, 0);

    var floors = await container.read(towerFloorListProvider.future);
    expect(floors.length, allFloors.length, reason: '与 yaml 楼层对齐');
    expect(floors.first.status, TowerFloorStatus.available);
    expect(
      floors.skip(1).every((f) => f.status == TowerFloorStatus.locked),
      isTrue,
      reason: '未通关时仅首层可挑战',
    );

    final svc = TowerProgressService(isar: IsarSetup.instance);
    await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
    await svc.recordClear(
      floorIndex: 1,
      now: DateTime(2026, 7, 19),
      elapsedMs: 0,
      maxFloor: _maxFloor,
    );
    container.invalidate(towerProgressProvider);

    progress = await container.read(towerProgressProvider.future);
    expect(progress.highestClearedFloor, 1);
    floors = await container.read(towerFloorListProvider.future);
    expect(floors.first.status, TowerFloorStatus.cleared);
    expect(floors[1].status, TowerFloorStatus.available, reason: '级联解锁次层');
  });

  test('leaderboardSync:Demo 阶段恒 Noop 实现', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(leaderboardSyncProvider), isA<NoopLeaderboardSync>());
  });
}
