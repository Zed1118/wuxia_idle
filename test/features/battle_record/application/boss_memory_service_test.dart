import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle_record/application/boss_memory_service.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_source.dart';

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
    tempDir = await Directory.systemTemp.createTemp('wuxia_boss_memory_test_');
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

  group('BossMemoryService.recordBossVictory', () {
    test('首胜建完整纪念', () async {
      final svc = BossMemoryService(isar: IsarSetup.instance);
      await svc.recordBossVictory(
        saveDataId: IsarSetup.currentSlotId,
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
        bossName: '撑伞高人',
        totalDamage: 18000,
        critCount: 5,
        totalTicks: 40,
        topContributorName: '祖师',
        topContributorDamage: 9000,
        treasureName: '天问剑',
        treasureTier: EquipmentTier.shenWu,
        rosterNames: ['祖师', '大弟子'],
        rosterPortraits: ['a.png', 'b.png'],
        now: DateTime(2026, 6, 19),
      );
      final all = await svc.allMemories(IsarSetup.currentSlotId);
      expect(all, hasLength(1));
      expect(all.first.bossName, '撑伞高人');
      expect(all.first.isPreRecord, isFalse);
      expect(all.first.defeatCount, 1);
    });

    test('首胜快照字段写入正确', () async {
      final svc = BossMemoryService(isar: IsarSetup.instance);
      final now = DateTime(2026, 6, 19);
      await svc.recordBossVictory(
        saveDataId: IsarSetup.currentSlotId,
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
        bossName: '撑伞高人',
        totalDamage: 18000,
        critCount: 5,
        totalTicks: 40,
        topContributorName: '祖师',
        topContributorDamage: 9000,
        treasureName: '天问剑',
        treasureTier: EquipmentTier.shenWu,
        rosterNames: ['祖师', '大弟子'],
        rosterPortraits: ['a.png', 'b.png'],
        now: now,
      );
      final m = (await svc.allMemories(IsarSetup.currentSlotId)).single;
      expect(m.totalDamage, 18000);
      expect(m.critCount, 5);
      expect(m.totalTicks, 40);
      expect(m.topContributorName, '祖师');
      expect(m.topContributorDamage, 9000);
      expect(m.treasureName, '天问剑');
      expect(m.treasureTier, EquipmentTier.shenWu);
      expect(m.rosterNames, ['祖师', '大弟子']);
      expect(m.rosterPortraits, ['a.png', 'b.png']);
      expect(m.firstClearedAt, now);
      expect(m.source, BossMemorySource.mainline);
      expect(m.groupIndex, 1);
    });

    test('重打仅累加 defeatCount 不覆盖快照', () async {
      final svc = BossMemoryService(isar: IsarSetup.instance);
      await svc.recordBossVictory(
        saveDataId: IsarSetup.currentSlotId,
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
        bossName: '撑伞高人',
        totalDamage: 18000,
        critCount: 5,
        totalTicks: 40,
        rosterNames: const [],
        rosterPortraits: const [],
        now: DateTime(2026, 6, 19),
      );
      await svc.recordBossVictory(
        saveDataId: IsarSetup.currentSlotId,
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
        bossName: '撑伞高人',
        totalDamage: 99999,
        critCount: 9,
        totalTicks: 80,
        rosterNames: const [],
        rosterPortraits: const [],
        now: DateTime(2026, 6, 20),
      );
      final m = (await svc.allMemories(IsarSetup.currentSlotId)).single;
      expect(m.defeatCount, 2);
      expect(m.totalDamage, 18000, reason: '首胜快照冻结，重打不覆盖');
    });

    test('不同 bossKey 各自独立建行', () async {
      final svc = BossMemoryService(isar: IsarSetup.instance);
      await svc.recordBossVictory(
        saveDataId: IsarSetup.currentSlotId,
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
        bossName: '撑伞高人',
        totalDamage: 18000,
        critCount: 5,
        totalTicks: 40,
        rosterNames: const [],
        rosterPortraits: const [],
        now: DateTime(2026, 6, 19),
      );
      await svc.recordBossVictory(
        saveDataId: IsarSetup.currentSlotId,
        bossKey: 'tower_floor_10',
        source: BossMemorySource.tower,
        groupIndex: 10,
        bossName: '碧眼老僧',
        totalDamage: 25000,
        critCount: 8,
        totalTicks: 60,
        rosterNames: const [],
        rosterPortraits: const [],
        now: DateTime(2026, 6, 19),
      );
      final all = await svc.allMemories(IsarSetup.currentSlotId);
      expect(all, hasLength(2));
    });
  });
}
