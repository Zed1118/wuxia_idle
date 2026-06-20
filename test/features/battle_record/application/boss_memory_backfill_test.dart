import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle_record/application/boss_memory_service.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_source.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_boss_backfill_test_');
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

  group('BossMemoryService.backfillFromProgress', () {
    test('主线：仅 Boss 关入册，非 Boss 关跳过', () async {
      final isar = IsarSetup.instance;
      final saveDataId = IsarSetup.currentSlotId;

      // 种 MainlineProgress：stage_01_01（非 Boss）+ stage_01_05（Boss）
      final mp = MainlineProgress()
        ..saveDataId = saveDataId
        ..clearedStageIds = ['stage_01_01', 'stage_01_05']
        ..clearedAt = [DateTime(2026, 1, 1), DateTime(2026, 2, 1)];
      await isar.writeTxn(() => isar.mainlineProgress.put(mp));

      final svc = BossMemoryService(isar: isar);
      await svc.backfillFromProgress(saveDataId);

      final all = await svc.allMemories(saveDataId);
      expect(all, hasLength(1), reason: '只有 stage_01_05 是 Boss 关应入册');
      final m = all.first;
      expect(m.bossKey, 'stage_01_05');
      expect(m.source, BossMemorySource.mainline);
      expect(m.groupIndex, 1);
      expect(m.isPreRecord, isTrue);
      expect(m.totalDamage, isNull);
      expect(m.defeatCount, 1);
      expect(m.firstClearedAt, DateTime(2026, 2, 1));
    });

    test('幂等：已存在完整纪念（isPreRecord=false）不被骨架覆盖', () async {
      final isar = IsarSetup.instance;
      final saveDataId = IsarSetup.currentSlotId;

      // 先写完整纪念
      final svc = BossMemoryService(isar: isar);
      await svc.recordBossVictory(
        saveDataId: saveDataId,
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
        bossName: '撑伞高人',
        totalDamage: 18000,
        critCount: 5,
        totalTicks: 40,
        rosterNames: const [],
        rosterPortraits: const [],
        now: DateTime(2026, 3, 1),
      );

      // 种 MainlineProgress（含同一 Boss）
      final mp = MainlineProgress()
        ..saveDataId = saveDataId
        ..clearedStageIds = ['stage_01_05']
        ..clearedAt = [DateTime(2026, 1, 1)];
      await isar.writeTxn(() => isar.mainlineProgress.put(mp));

      // 回填
      await svc.backfillFromProgress(saveDataId);

      final all = await svc.allMemories(saveDataId);
      expect(all, hasLength(1));
      expect(all.first.isPreRecord, isFalse, reason: '已存在完整纪念，骨架不覆盖');
      expect(all.first.totalDamage, 18000, reason: '首胜快照冻结不变');
    });

    test('塔：highestClearedFloor=10 → 回填 tower_floor_5 + tower_floor_10', () async {
      final isar = IsarSetup.instance;
      final saveDataId = IsarSetup.currentSlotId;

      // 种 TowerProgress：最高层 10
      final tp = TowerProgress()
        ..saveDataId = saveDataId
        ..highestClearedFloor = 10
        ..createdAt = DateTime(2026, 1, 1);
      await isar.writeTxn(() => isar.towerProgress.put(tp));

      final svc = BossMemoryService(isar: isar);
      await svc.backfillFromProgress(saveDataId);

      final all = await svc.allMemories(saveDataId);
      final towerEntries = all.where((m) => m.source == BossMemorySource.tower).toList();
      expect(towerEntries, hasLength(2), reason: 'Boss 层 5、10 均 <= 10 应回填');

      final keys = towerEntries.map((m) => m.bossKey).toSet();
      expect(keys, containsAll(['tower_floor_5', 'tower_floor_10']));

      for (final m in towerEntries) {
        expect(m.isPreRecord, isTrue);
        expect(m.firstClearedAt, isNull, reason: '塔回填无精确时间');
        expect(m.defeatCount, 1);
        expect(m.totalDamage, isNull);
      }
    });

    test('幂等：回填多次不重复建行', () async {
      final isar = IsarSetup.instance;
      final saveDataId = IsarSetup.currentSlotId;

      final mp = MainlineProgress()
        ..saveDataId = saveDataId
        ..clearedStageIds = ['stage_01_05']
        ..clearedAt = [DateTime(2026, 1, 1)];
      await isar.writeTxn(() => isar.mainlineProgress.put(mp));

      final svc = BossMemoryService(isar: isar);
      await svc.backfillFromProgress(saveDataId);
      await svc.backfillFromProgress(saveDataId);

      final all = await svc.allMemories(saveDataId);
      expect(all, hasLength(1), reason: '幂等：多次回填不重复建行');
    });

    test('无进度：主线和塔均空，回填结果为空', () async {
      final isar = IsarSetup.instance;
      final saveDataId = IsarSetup.currentSlotId;

      final svc = BossMemoryService(isar: isar);
      await svc.backfillFromProgress(saveDataId);

      final all = await svc.allMemories(saveDataId);
      expect(all, isEmpty);
    });
  });
}
