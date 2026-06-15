import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
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
}
