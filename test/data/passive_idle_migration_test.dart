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

  test('saveVersion 标记为当前版本', () async {
    final save = (await IsarSetup.currentSaveData())!;
    // 钉死字面版本号(非 currentSaveVersion 自比较):兼作全仓唯一「版本号意外回退/
    // 误 bump」tripwire——bump saveVer 时须同步改此处,强制有意识升版。
    expect(save.saveVersion, '0.33.0');
    expect(save.saveVersion, IsarSetup.currentSaveVersion);
  });
}
