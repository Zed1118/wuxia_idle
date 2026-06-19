import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle_record/application/boss_memory_providers.dart';
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_boss_memory_providers_test_');
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

  // ── bossCatalog 测试 ────────────────────────────────────────────────────

  group('bossCatalog', () {
    test('含全 Boss：主线 isBossStage(21 条) + 塔 6 层，共 27 条', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final catalog = container.read(bossCatalogProvider);

      // 总数
      expect(catalog, hasLength(27), reason: '主线 21 + 塔 6 = 27');

      // 塔条目恰好 6 个
      final towerEntries =
          catalog.where((e) => e.source == BossMemorySource.tower).toList();
      expect(towerEntries, hasLength(6), reason: '爬塔 Boss 层 [5,10,15,20,25,30]');

      // 主线条目恰好 21 个
      final mainlineEntries =
          catalog.where((e) => e.source == BossMemorySource.mainline).toList();
      expect(mainlineEntries, hasLength(21), reason: '主线 isBossStage=true 共 21 关');

      // 特定主线 Boss
      final keys = catalog.map((e) => e.bossKey).toSet();
      expect(keys.contains('stage_01_05'), isTrue, reason: '主线 Boss stage_01_05 须在 catalog');

      // 特定塔层
      for (final floor in [5, 10, 15, 20, 25, 30]) {
        expect(keys.contains('tower_floor_$floor'), isTrue,
            reason: 'tower_floor_$floor 须在 catalog');
      }
    });

    test('塔条目 groupIndex = 层号', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final catalog = container.read(bossCatalogProvider);
      final towerEntries =
          catalog.where((e) => e.source == BossMemorySource.tower).toList();

      final floors = towerEntries.map((e) => e.groupIndex).toSet();
      expect(floors, containsAll([5, 10, 15, 20, 25, 30]));
    });

    test('catalog 内 bossKey 不重复', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final catalog = container.read(bossCatalogProvider);
      final keys = catalog.map((e) => e.bossKey).toList();
      expect(keys.toSet().length, keys.length, reason: 'bossKey 不应重复');
    });
  });

  // ── bossMemoryList / bossMemoryCount 测试 ──────────────────────────────

  group('bossMemoryList', () {
    test('空存档返回空列表', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final list = await container.read(bossMemoryListProvider.future);
      expect(list, isEmpty);
    });

    test('种 1 完整 + 1 骨架 → list 长度 2', () async {
      final isar = IsarSetup.instance;
      final saveDataId = IsarSetup.currentSlotId;
      final svc = BossMemoryService(isar: isar);

      // 完整纪念
      await svc.recordBossVictory(
        saveDataId: saveDataId,
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
        bossName: '撑伞高人',
        totalDamage: 15000,
        critCount: 3,
        totalTicks: 30,
        rosterNames: const ['张无忌'],
        rosterPortraits: const ['portrait_a'],
        now: DateTime(2026, 3, 1),
      );
      // 骨架（isPreRecord=true）
      await svc.recordBossVictory(
        saveDataId: saveDataId,
        bossKey: 'tower_floor_5',
        source: BossMemorySource.tower,
        groupIndex: 5,
        bossName: '塔层精英',
        totalDamage: 8000,
        critCount: 1,
        totalTicks: 20,
        rosterNames: const [],
        rosterPortraits: const [],
        now: DateTime(2026, 3, 2),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final list = await container.read(bossMemoryListProvider.future);
      expect(list, hasLength(2));
    });
  });

  group('bossMemoryCount', () {
    test('空存档 count = 0', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final count = await container.read(bossMemoryCountProvider.future);
      expect(count, 0);
    });

    test('种 1 完整 + 1 骨架 → count == 2（入口门控：>0 解锁）', () async {
      final isar = IsarSetup.instance;
      final saveDataId = IsarSetup.currentSlotId;
      final svc = BossMemoryService(isar: isar);

      await svc.recordBossVictory(
        saveDataId: saveDataId,
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 1,
        bossName: '撑伞高人',
        totalDamage: 15000,
        critCount: 3,
        totalTicks: 30,
        rosterNames: const [],
        rosterPortraits: const [],
        now: DateTime(2026, 3, 1),
      );
      await svc.recordBossVictory(
        saveDataId: saveDataId,
        bossKey: 'tower_floor_5',
        source: BossMemorySource.tower,
        groupIndex: 5,
        bossName: '塔层精英',
        totalDamage: 8000,
        critCount: 1,
        totalTicks: 20,
        rosterNames: const [],
        rosterPortraits: const [],
        now: DateTime(2026, 3, 2),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final count = await container.read(bossMemoryCountProvider.future);
      expect(count, 2, reason: '骨架也算，>0 即解锁主菜单入口');
    });
  });
}
