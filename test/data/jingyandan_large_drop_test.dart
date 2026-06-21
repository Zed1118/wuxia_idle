import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 材料经济 balance T4:大还丹(item_jingyandan_large)掉落扩展红线测。
///
/// 验证 Ch4-6 章末 Boss 关与爬塔 10/20/30 层 dropTable 含大还丹,
/// 以及 Ch1-3 章末 Boss dropChance 校准统一。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  tearDown(GameRepository.resetForTest);

  group('大还丹掉落扩展', () {
    test('Ch4-6 章末 Boss 含 item_jingyandan_large 掉落', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      for (final stageId in ['stage_04_05', 'stage_05_05', 'stage_06_05']) {
        final stage = repo.getStage(stageId);
        final itemIds = stage.dropTable
            .whereType<ItemDrop>()
            .map((e) => e.inventoryItemDefId)
            .toList();
        expect(
          itemIds,
          contains('item_jingyandan_large'),
          reason: '$stageId dropTable 应含大还丹',
        );
      }
    });

    test('爬塔 10/20/30 层含 item_jingyandan_large 掉落', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      for (final floor in [10, 20, 30]) {
        final floorDef = repo.getTowerFloor(floor);
        final itemIds = floorDef.dropTable
            .whereType<ItemDrop>()
            .map((e) => e.inventoryItemDefId)
            .toList();
        expect(
          itemIds,
          contains('item_jingyandan_large'),
          reason: '爬塔第 $floor 层 dropTable 应含大还丹',
        );
      }
    });

    test('大还丹 dropChance 区间合法(0 < p ≤ 1.0)', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      // 章末 Boss:Ch1-6 六关
      for (final stageId in [
        'stage_01_05',
        'stage_02_05',
        'stage_03_05',
        'stage_04_05',
        'stage_05_05',
        'stage_06_05',
      ]) {
        final stage = repo.getStage(stageId);
        final drops = stage.dropTable
            .whereType<ItemDrop>()
            .where((e) => e.inventoryItemDefId == 'item_jingyandan_large')
            .toList();
        expect(drops, isNotEmpty, reason: '$stageId 应有大还丹条目');
        for (final d in drops) {
          expect(d.dropChance, greaterThan(0.0),
              reason: '$stageId 大还丹 dropChance 须 > 0');
          expect(d.dropChance, lessThanOrEqualTo(1.0),
              reason: '$stageId 大还丹 dropChance 须 ≤ 1.0');
        }
      }

      // 爬塔大 Boss 层
      for (final floor in [10, 20, 30]) {
        final floorDef = repo.getTowerFloor(floor);
        final drops = floorDef.dropTable
            .whereType<ItemDrop>()
            .where((e) => e.inventoryItemDefId == 'item_jingyandan_large')
            .toList();
        expect(drops, isNotEmpty, reason: '爬塔 $floor 层应有大还丹条目');
        for (final d in drops) {
          expect(d.dropChance, greaterThan(0.0),
              reason: '爬塔 $floor 层大还丹 dropChance 须 > 0');
          expect(d.dropChance, lessThanOrEqualTo(1.0),
              reason: '爬塔 $floor 层大还丹 dropChance 须 ≤ 1.0');
        }
      }
    });
  });
}
