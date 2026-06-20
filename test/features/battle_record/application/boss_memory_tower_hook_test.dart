import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_stats.dart';
import 'package:wuxia_idle/features/battle_record/application/boss_memory_hook.dart';
import 'package:wuxia_idle/features/battle_record/application/boss_memory_service.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_key.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_source.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';

/// Task 7：爬塔 victory 留档 hook tower 形态参数验证。
///
/// 本测直接调用 [runBossMemoryHookAfterVictory]（source=tower），
/// 验证 tower 形态落账正确（bossKey / source / groupIndex）。
/// 接线守卫（bossKind != null 才调）在 tower_entry_flow.dart 生产代码中，
/// 本测通过不传普通层 bossKey 间接验证——普通层由接线守卫保证不调 hook。

const _testStats = BattleStatsSummary(
  totalDamage: 25000,
  critCount: 8,
  totalTicks: 50,
);

Future<void> _writeSaveData(Isar isar) async {
  await isar.writeTxn(() => isar.saveDatas.put(
        SaveData()
          ..id = 0
          ..slotId = IsarSetup.currentSlotId
          ..saveVersion = '0.0.1'
          ..createdAt = DateTime(2026, 6, 20)
          ..lastSavedAt = DateTime(2026, 6, 20)
          ..lastOnlineAt = DateTime(2026, 6, 20)
          ..activeCharacterIds = const [],
      ));
}

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
    tempDir = await Directory.systemTemp
        .createTemp('wuxia_boss_memory_tower_hook_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await _writeSaveData(IsarSetup.instance);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('runBossMemoryHookAfterVictory — tower 形态', () {
    test('爬塔 Boss 层胜利 → 留档(source=tower, bossKey=tower_floor_10)', () async {
      const floorIndex = 10;
      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.tower,
        bossKey: towerBossKey(floorIndex),
        groupIndex: floorIndex,
        bossName: '塔中剑客',
        stats: _testStats,
        drops: const DropResult(equipments: [], items: []),
        topContributorName: '祖师',
        topContributorDamage: 12000,
      );

      final all = await BossMemoryService(isar: IsarSetup.instance)
          .allMemories(IsarSetup.currentSlotId);
      expect(all, hasLength(1));
      final m = all.first;
      expect(m.source, BossMemorySource.tower);
      expect(m.bossKey, 'tower_floor_10');
      expect(m.groupIndex, floorIndex);
      expect(m.bossName, '塔中剑客');
      expect(m.totalDamage, 25000);
      expect(m.critCount, 8);
      expect(m.totalTicks, 50);
      expect(m.topContributorName, '祖师');
      expect(m.topContributorDamage, 12000);
      expect(m.defeatCount, 1);
      expect(m.isPreRecord, isFalse);
    });

    test('爬塔 Boss 层第 5 层 → bossKey = tower_floor_5', () async {
      const floorIndex = 5;
      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.tower,
        bossKey: towerBossKey(floorIndex),
        groupIndex: floorIndex,
        bossName: '守门人',
        stats: _testStats,
        drops: const DropResult(equipments: [], items: []),
      );

      final all = await BossMemoryService(isar: IsarSetup.instance)
          .allMemories(IsarSetup.currentSlotId);
      expect(all, hasLength(1));
      expect(all.first.bossKey, 'tower_floor_5');
      expect(all.first.source, BossMemorySource.tower);
    });

    test('爬塔 Boss 层重打 → defeatCount 累加，首胜快照冻结', () async {
      const floorIndex = 20;
      const drops = DropResult(equipments: [], items: []);
      for (var i = 0; i < 3; i++) {
        await runBossMemoryHookAfterVictory(
          source: BossMemorySource.tower,
          bossKey: towerBossKey(floorIndex),
          groupIndex: floorIndex,
          bossName: '绝顶强者',
          stats: _testStats,
          drops: drops,
        );
      }

      final all = await BossMemoryService(isar: IsarSetup.instance)
          .allMemories(IsarSetup.currentSlotId);
      expect(all, hasLength(1));
      expect(all.first.defeatCount, 3);
      // 首胜快照冻结，totalDamage 不累加
      expect(all.first.totalDamage, 25000);
    });

    test('主线 + 爬塔 bossKey 不冲突(各自独立条目)', () async {
      const drops = DropResult(equipments: [], items: []);
      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.mainline,
        bossKey: 'stage_01_05',
        groupIndex: 1,
        bossName: '主线 Boss',
        stats: _testStats,
        drops: drops,
      );
      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.tower,
        bossKey: towerBossKey(5),
        groupIndex: 5,
        bossName: '塔层 Boss',
        stats: _testStats,
        drops: drops,
      );

      final all = await BossMemoryService(isar: IsarSetup.instance)
          .allMemories(IsarSetup.currentSlotId);
      expect(all, hasLength(2));
      final sources = all.map((m) => m.source).toSet();
      expect(sources, containsAll([BossMemorySource.mainline, BossMemorySource.tower]));
    });
  });
}
