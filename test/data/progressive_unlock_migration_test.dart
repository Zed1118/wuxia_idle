import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock_receipt.dart';

import '../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'progressive_unlock_migration_',
    );
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test(
    '0.42 save upgrades additively without fabricating unlock seals',
    () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      await IsarSetup.instance.writeTxn(() async {
        final save = (await IsarSetup.instance.saveDatas.get(0))!;
        save.saveVersion = '0.42.0';
        await IsarSetup.instance.saveDatas.put(save);
      });
      await IsarSetup.close();

      await IsarSetup.init(directory: tempDir, inspector: false);
      expect(
        (await IsarSetup.instance.saveDatas.get(0))!.saveVersion,
        '0.44.0',
      );
      expect(await IsarSetup.instance.progressiveUnlockReceipts.count(), 0);
    },
  );
}
