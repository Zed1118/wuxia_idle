import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_progress_service.dart';

/// P1 周目进化 Task A1：MainlineProgress.clearedStageCycleKeys 字段 + 派生方法。
///
/// 校验：
///   - recordVictory 默认 cycle=1 写入 stageId#1
///   - recordVictory cycle:2 写入 stageId#2（不覆盖 cycle 1）
///   - highestClearedCycle 正确返回已过最高周目
///   - 未通关 stage 返回 0
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_cycle_prog_');
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

  test('recordVictory(cycle:2) 写 stageId#2 cycleKey + highestClearedCycle 派生',
      () async {
    final svc = MainlineProgressService(isar: IsarSetup.instance);
    await svc.getOrCreate(saveDataId: 1);

    // 默认 cycle=1
    await svc.recordVictory(
      stageId: 'stage_01_01',
      now: DateTime(2026, 6, 13),
    );
    // 显式 cycle=2
    await svc.recordVictory(
      stageId: 'stage_01_01',
      now: DateTime(2026, 6, 14),
      cycle: 2,
    );

    final p = await svc.getOrCreate(saveDataId: 1);
    expect(
      p.clearedStageCycleKeys,
      containsAll(['stage_01_01#1', 'stage_01_01#2']),
    );
    expect(MainlineProgressService.highestClearedCycle(p, 'stage_01_01'), 2);
    expect(
      MainlineProgressService.highestClearedCycle(p, 'stage_01_02'),
      0,
      reason: '未通关 stage 返回 0',
    );
  });
}
