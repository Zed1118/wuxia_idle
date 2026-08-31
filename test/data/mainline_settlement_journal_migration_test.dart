import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';

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

  test('0.39.0 → 当前纯可加迁移：不从空历史伪造 active journal/run/receipt', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.saveVersion = '0.39.0';
      await IsarSetup.instance.saveDatas.put(save);
    });
    await IsarSetup.close();

    await IsarSetup.init(directory: tempDir, inspector: false);
    expect((await IsarSetup.instance.saveDatas.get(0))!.saveVersion, '0.43.0');
    expect(await IsarSetup.instance.mainlineSettlementJournals.count(), 0);
    expect(await IsarSetup.instance.durableActivityCombatRuns.count(), 0);
    expect(await IsarSetup.instance.rewardClaimReceipts.count(), 0);

    await IsarSetup.close();
    await IsarSetup.init(directory: tempDir, inspector: false);
    expect(await IsarSetup.instance.mainlineSettlementJournals.count(), 0);
    expect(await IsarSetup.instance.durableActivityCombatRuns.count(), 0);
    expect(await IsarSetup.instance.rewardClaimReceipts.count(), 0);
  });
}
