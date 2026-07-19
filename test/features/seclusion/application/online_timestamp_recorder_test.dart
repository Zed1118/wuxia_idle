import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

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
    tempDir = await Directory.systemTemp.createTemp('wuxia_online_ts_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async => await IsarSetup.close());

  test('touchOnlineNow 写入指定时间到 lastOnlineAt', () async {
    await IsarSetup.touchOnlineNow(now: DateTime(2026, 6, 15, 9));
    final save = (await IsarSetup.currentSaveData())!;
    expect(save.lastOnlineAt, DateTime(2026, 6, 15, 9));
  });

  test('touchOnlineNow 等待事务期间不覆盖其他 SaveData 写入', () async {
    final reachedBarrier = Completer<void>();
    final releaseBarrier = Completer<void>();
    final touch = IsarSetup.touchOnlineNow(
      now: DateTime(2026, 6, 15, 10),
      beforeWriteTxn: () async {
        reachedBarrier.complete();
        await releaseBarrier.future;
      },
    );

    await reachedBarrier.future;
    await IsarSetup.instance.writeTxn(() async {
      final current = (await IsarSetup.currentSaveData())!;
      current.slotName = '并发改名保留';
      await IsarSetup.instance.saveDatas.put(current);
    });
    releaseBarrier.complete();
    await touch;

    final saved = (await IsarSetup.currentSaveData())!;
    expect(saved.slotName, '并发改名保留');
    expect(saved.lastOnlineAt, DateTime(2026, 6, 15, 10));
  });
}
