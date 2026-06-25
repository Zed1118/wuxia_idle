import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_state.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_island_persist_');
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

  test('P1: islandBuildings 写入 → 读回字段完整', () async {
    // 构造 3 个建筑
    final source = IslandBuildingState()
      ..type = BuildingType.tieJiangChang
      ..level = 2
      ..stored = 35.5;
    final processor = IslandBuildingState()
      ..type = BuildingType.daZaoTai
      ..level = 1
      ..stored = 7.25
      ..activeRecipeId = 'forge_mojianshi';
    final source2 = IslandBuildingState()
      ..type = BuildingType.caoYaoYuan
      ..level = 3
      ..stored = 0.0;

    final now = DateTime(2026, 6, 25, 12, 0);

    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.islandBuildings = [source, processor, source2];
      save.islandLastSettledAt = now;
      await IsarSetup.instance.saveDatas.put(save);
    });

    final read = (await IsarSetup.instance.saveDatas.get(0))!;
    expect(read.islandBuildings.length, 3);

    final readSource = read.islandBuildings[0];
    expect(readSource.type, BuildingType.tieJiangChang);
    expect(readSource.level, 2);
    expect(readSource.stored, closeTo(35.5, 1e-9));
    expect(readSource.activeRecipeId, isNull);

    final readProcessor = read.islandBuildings[1];
    expect(readProcessor.type, BuildingType.daZaoTai);
    expect(readProcessor.level, 1);
    expect(readProcessor.stored, closeTo(7.25, 1e-9));
    expect(readProcessor.activeRecipeId, 'forge_mojianshi');

    final readSource2 = read.islandBuildings[2];
    expect(readSource2.type, BuildingType.caoYaoYuan);
    expect(readSource2.level, 3);
    expect(readSource2.stored, closeTo(0.0, 1e-9));

    expect(read.islandLastSettledAt, now);
  });

  test('P2: 旧档（未设 islandBuildings/islandLastSettledAt）读回默认空/null', () async {
    // 新 init 创建的档不设 island 字段 → 读取应为空列表 + null，不崩。
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    expect(save.islandBuildings, isEmpty,
        reason: 'islandBuildings 新档默认空列表');
    expect(save.islandLastSettledAt, isNull,
        reason: 'islandLastSettledAt 新档默认 null');
  });

  test('P3: saveVersion 已升 0.31.0', () async {
    final save = (await IsarSetup.currentSaveData())!;
    expect(save.saveVersion, '0.31.0');
  });
}
