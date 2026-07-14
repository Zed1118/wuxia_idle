import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 材料经济 balance T5:秘籍(item_scroll_*)掉落校准红线测。
///
/// 当前发布方案(T5 首通必得):
///   - 主线前三章各 1 本当前阶秘籍:dropChance=1.0 + isFirstClear gate 于
///     stage_entry_flow.dart(非首通跳过写入,避免重复刷)
///   - 爬塔 2 本(5/10 层):dropChance=1.0 + tower_entry_flow isFirstClear 门控。
/// 高阶秘籍定义保留给未来副本，不从当前主线/塔提前投放。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  tearDown(GameRepository.resetForTest);

  group('秘籍掉落校准', () {
    test('主线前三章只投放当前阶秘籍', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      final expected = {
        'stage_01_05': 'item_scroll_kai_bei_shou',
        'stage_02_05': 'item_scroll_yan_zi_san_chao',
        'stage_03_05': 'item_scroll_kai_bei_shou',
      };

      for (final entry in expected.entries) {
        final stage = repo.getStage(entry.key);
        final itemIds = stage.dropTable
            .whereType<ItemDrop>()
            .map((e) => e.inventoryItemDefId)
            .toList();
        expect(
          itemIds,
          contains(entry.value),
          reason: '${entry.key} dropTable 应含 ${entry.value}',
        );
      }
    });

    test('主线当前阶秘籍 dropChance=1.0(首通必得)', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      const mainlineScrolls = {
        'stage_01_05': 'item_scroll_kai_bei_shou',
        'stage_02_05': 'item_scroll_yan_zi_san_chao',
        'stage_03_05': 'item_scroll_kai_bei_shou',
      };

      for (final entry in mainlineScrolls.entries) {
        final stage = repo.getStage(entry.key);
        final drops = stage.dropTable
            .whereType<ItemDrop>()
            .where((e) => e.inventoryItemDefId == entry.value)
            .toList();
        expect(
          drops,
          isNotEmpty,
          reason: '${entry.key} 应有 ${entry.value} 掉落条目',
        );
        for (final d in drops) {
          expect(
            d.dropChance,
            closeTo(1.0, 0.001),
            reason:
                '${entry.key} 秘籍 dropChance 应=1.0(T5:首通必得,stage_entry_flow isFirstClear gate 防重复)',
          );
        }
      }
    });

    test('爬塔只投放当前阶 2 本秘籍', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      const towerScrolls = <int, String>{
        5: 'item_scroll_kai_bei_shou',
        10: 'item_scroll_yan_zi_san_chao',
      };

      for (final entry in towerScrolls.entries) {
        final floor = repo.getTowerFloor(entry.key);
        final itemIds = floor.dropTable
            .whereType<ItemDrop>()
            .map((e) => e.inventoryItemDefId)
            .toList();
        expect(
          itemIds,
          contains(entry.value),
          reason: '爬塔第 ${entry.key} 层 dropTable 应含 ${entry.value}',
        );
      }
    });

    test('爬塔当前阶 2 本秘籍 dropChance=1.0(首通必得)', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      const towerScrolls = <int, String>{
        5: 'item_scroll_kai_bei_shou',
        10: 'item_scroll_yan_zi_san_chao',
      };

      for (final entry in towerScrolls.entries) {
        final floor = repo.getTowerFloor(entry.key);
        final drops = floor.dropTable
            .whereType<ItemDrop>()
            .where((e) => e.inventoryItemDefId == entry.value)
            .toList();
        expect(
          drops,
          isNotEmpty,
          reason: '爬塔第 ${entry.key} 层应有 ${entry.value} 掉落条目',
        );
        for (final d in drops) {
          expect(
            d.dropChance,
            closeTo(1.0, 0.001),
            reason:
                '爬塔第 ${entry.key} 层秘籍 dropChance 应=1.0(T5:首通必得,tower_entry_flow isFirstClear gate)',
          );
        }
      }
    });
  });
}
