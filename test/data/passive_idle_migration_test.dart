import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_passive_mig_');
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

  test('新档累计字段默认 0', () async {
    final save = (await IsarSetup.currentSaveData())!;
    expect(save.totalPassiveMojianshi, 0);
    expect(save.totalPassiveExperience, 0);
  });

  test('saveVersion 标记为 0.30.0', () async {
    final save = (await IsarSetup.currentSaveData())!;
    expect(save.saveVersion, '0.30.0');
  });
}
