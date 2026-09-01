import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';

import '../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'expedition_milestone_record_migration_',
    );
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('0.45 registers versioned ExpeditionMilestoneRecord collection', () {
    expect(
      IsarSetup.schemasForTesting.map((schema) => schema.name),
      contains('ExpeditionMilestoneRecord'),
    );
    expect(IsarSetup.currentSaveVersion, '0.45.0');
  });

  test(
    '0.44 depth cannot fabricate route+milestone manual clear facts',
    () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      await IsarSetup.instance.writeTxn(() async {
        final save = (await IsarSetup.instance.saveDatas.get(0))!
          ..saveVersion = '0.44.0'
          ..baicaoMaxDepth = 30;
        await IsarSetup.instance.saveDatas.put(save);
      });
      await IsarSetup.close();

      await IsarSetup.init(directory: tempDir, inspector: false);
      expect(
        (await IsarSetup.instance.saveDatas.get(0))!.saveVersion,
        '0.45.0',
      );
      expect(await IsarSetup.instance.expeditionMilestoneRecords.count(), 0);
    },
  );
}
