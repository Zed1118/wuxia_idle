import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_providers.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_progress_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `innerDemonProgressProvider` 派生行为测（2026-07-19 夜批 coverage
/// 补强，基线 2/5 行）。
///
/// 真 Isar + 真 GameRepository + 真上游 `mainlineProgressProvider`，钉：
///   - 零通关 → clearedCount=0 / next=首关心魔关
///   - 记两关 → clearedCount=2 / next 推进到第三关(级联刷新)
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_inner_demon_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('零通关 → clearedCount=0 / next=首关;记两关 → 推进', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final demonTotal = GameRepository
        .instance
        .numbers
        .innerDemon
        .requiredRealmLayer
        .keys
        .where((k) => k.startsWith('stage_inner_demon_'))
        .length;

    var progress = await container.read(innerDemonProgressProvider.future);
    expect(progress.clearedCount, 0);
    expect(progress.totalCount, demonTotal, reason: '总数派生自 numbers 不硬编码');
    expect(progress.nextUnclearedStageId, 'stage_inner_demon_01');

    // 生产体例:getOrCreate 拿单行后原地改再 put(直接 put 新行会造出
    // 第二行,findFirst 命中哪行是竞态——本测曾在并发联跑时翻车)。
    final svc = MainlineProgressService(isar: IsarSetup.instance);
    final row = await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
    await IsarSetup.instance.writeTxn(() async {
      row.clearedStageIds = ['stage_inner_demon_01', 'stage_inner_demon_02'];
      await IsarSetup.instance.mainlineProgress.put(row);
    });
    container.invalidate(mainlineProgressProvider);

    progress = await container.read(innerDemonProgressProvider.future);
    expect(progress.clearedCount, 2);
    expect(progress.nextUnclearedStageId, 'stage_inner_demon_03');
    expect(
      progress.clearedStageIds,
      containsAll(['stage_inner_demon_01', 'stage_inner_demon_02']),
    );
  });
}
