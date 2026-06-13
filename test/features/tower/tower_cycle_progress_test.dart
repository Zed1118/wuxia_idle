import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';

/// P1 周目进化 Task A2：TowerProgress 周目字段 + advanceCycle 方法。
///
/// 验证「问鼎轮回」全塔周目规则：
///   - 30 层全通关 → maxClearedCycle = currentCycleIndex
///   - advanceCycle → currentCycleIndex++ + highestClearedFloor 归零(从头爬)
///   - 未全通 30 层时 advanceCycle 是 no-op(防提前推进)
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_tower_cycle_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TowerProgress 周目字段默认值', () {
    test('新建行 → currentCycleIndex=1 / maxClearedCycle=0', () async {
      final svc = TowerProgressService(isar: IsarSetup.instance);
      final p = await svc.getOrCreate(saveDataId: 1);
      expect(p.currentCycleIndex, 1, reason: '初始从第 1 周目开始爬');
      expect(p.maxClearedCycle, 0, reason: '0 = 从未 30 层全通');
    });
  });

  group('30 层全通 → maxClearedCycle 更新', () {
    test('通关 30 层 → maxClearedCycle=1；advanceCycle 后 currentCycleIndex=2 从头爬',
        () async {
      final svc = TowerProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final now = DateTime(2026, 6, 14);
      for (var f = 1; f <= 30; f++) {
        await svc.recordClear(floorIndex: f, now: now, elapsedMs: 1000);
      }
      var p = await svc.getOrCreate(saveDataId: 1);
      expect(p.maxClearedCycle, 1,
          reason: '30 层全通首次 → 当前周目(1)已完成');
      expect(p.currentCycleIndex, 1,
          reason: 'advanceCycle 前 currentCycleIndex 不变');

      await svc.advanceCycle(saveDataId: 1);
      p = await svc.getOrCreate(saveDataId: 1);
      expect(p.currentCycleIndex, 2, reason: '进入第 2 周目');
      expect(p.highestClearedFloor, 0, reason: '新周目从第 1 层重新爬');
    });

    test('通到 29 层（未满 30）→ maxClearedCycle 仍 0', () async {
      final svc = TowerProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final now = DateTime(2026, 6, 14);
      for (var f = 1; f <= 29; f++) {
        await svc.recordClear(floorIndex: f, now: now, elapsedMs: 1000);
      }
      final p = await svc.getOrCreate(saveDataId: 1);
      expect(p.maxClearedCycle, 0, reason: '未满 30 层，周目未完成');
    });
  });

  group('advanceCycle 守卫：未全通时 no-op', () {
    test('maxClearedCycle=0（未通整塔）→ advanceCycle no-op，currentCycleIndex 不变',
        () async {
      final svc = TowerProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      // 通 10 层但未满 30
      final now = DateTime(2026, 6, 14);
      for (var f = 1; f <= 10; f++) {
        await svc.recordClear(floorIndex: f, now: now, elapsedMs: 1000);
      }

      await svc.advanceCycle(saveDataId: 1);

      final p = await svc.getOrCreate(saveDataId: 1);
      expect(p.currentCycleIndex, 1, reason: '未全通不应推进周目');
      expect(p.highestClearedFloor, 10, reason: 'highestClearedFloor 不应被重置');
    });
  });

  group('累计统计在 advanceCycle 后保留', () {
    test('totalAttempts/totalDefeats 跨周目累计，不被 advanceCycle 重置', () async {
      final svc = TowerProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final now = DateTime(2026, 6, 14);
      for (var f = 1; f <= 30; f++) {
        await svc.recordClear(floorIndex: f, now: now, elapsedMs: 1000);
      }
      final beforeAdvance = await svc.getOrCreate(saveDataId: 1);
      final attemptsBeforeAdvance = beforeAdvance.totalAttempts;

      await svc.advanceCycle(saveDataId: 1);

      final p = await svc.getOrCreate(saveDataId: 1);
      expect(p.totalAttempts, attemptsBeforeAdvance,
          reason: 'advanceCycle 本身不改变 totalAttempts 累计值');
    });
  });
}
