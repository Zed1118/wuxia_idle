import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';

import '../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_mainline_journal_migration_',
    );
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('0.39.0 → 0.40.0 纯可加迁移：不从历史进度伪造 active journal', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.saveVersion = '0.39.0';
      await IsarSetup.instance.saveDatas.put(save);
    });
    await IsarSetup.close();

    await IsarSetup.init(directory: tempDir, inspector: false);
    expect(
      (await IsarSetup.instance.saveDatas.get(0))!.saveVersion,
      '0.40.0',
    );
    expect(await IsarSetup.instance.mainlineSettlementJournals.count(), 0);

    await IsarSetup.close();
    await IsarSetup.init(directory: tempDir, inspector: false);
    expect(await IsarSetup.instance.mainlineSettlementJournals.count(), 0);
  });
}
