import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

import '../support/isar_test_support.dart';

void main() {
  late Directory tempDir;
  setUpAll(() => initializeTestIsarCore());

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_journey_migration_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });
  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('0.36 旧档迁到 0.37：新进度字段取默认、无 active 会话、旧数据不动', () async {
    // 伪造旧档：手写 0.36.0 版本号
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.currentSaveData())!..saveVersion = '0.36.0';
      await IsarSetup.instance.saveDatas.put(save);
    });
    await IsarSetup.close();

    // 重开触发迁移
    await IsarSetup.init(directory: tempDir, inspector: false);
    final migrated = (await IsarSetup.currentSaveData())!;

    expect(migrated.saveVersion, '0.37.0');
    expect(migrated.jianghuJourneyUnlocked, isFalse);
    expect(migrated.baicaoMaxDepth, 0);
    expect(migrated.grantedTicketMilestoneIds, isEmpty);
    expect(await IsarSetup.instance.expeditionRuns.count(), 0);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });
}
