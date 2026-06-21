import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 材料经济 balance T5:秘籍(item_scroll_*)掉落校准红线测。
///
/// 核实结论(T5):主线掉落引擎无首通门控,rollDrops 每次胜利都触发;
/// 爬塔有 isFirstClear 门控(tower_entry_flow:208)。
/// 校准方案:
///   - 主线 3 本(stage_01_05/02_05/03_05):dropChance=0.5(较高概率,重复掉幂等)
///   - 爬塔 6 本(5/10/15/20/25/30 层):dropChance=0.15(残本概率磨砺感)
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  tearDown(GameRepository.resetForTest);

  group('秘籍掉落校准', () {
    test('主线 3 本秘籍挂在对应章末 Boss 关', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      final expected = {
        'stage_01_05': 'item_scroll_guan_shan_ba_ji',
        'stage_02_05': 'item_scroll_ma_ta_fei_yan',
        'stage_03_05': 'item_scroll_ye_yu_shi_nian_deng',
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

    test('主线 3 本秘籍 dropChance=0.5(较高概率)', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      const mainlineScrolls = {
        'stage_01_05': 'item_scroll_guan_shan_ba_ji',
        'stage_02_05': 'item_scroll_ma_ta_fei_yan',
        'stage_03_05': 'item_scroll_ye_yu_shi_nian_deng',
      };

      for (final entry in mainlineScrolls.entries) {
        final stage = repo.getStage(entry.key);
        final drops = stage.dropTable
            .whereType<ItemDrop>()
            .where((e) => e.inventoryItemDefId == entry.value)
            .toList();
        expect(drops, isNotEmpty,
            reason: '${entry.key} 应有 ${entry.value} 掉落条目');
        for (final d in drops) {
          expect(
            d.dropChance,
            closeTo(0.5, 0.001),
            reason:
                '${entry.key} 秘籍 dropChance 应=0.5(T5 balance:主线较高概率)',
          );
        }
      }
    });

    test('爬塔 6 本秘籍挂在对应层', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      const towerScrolls = {
        5: 'item_scroll_kai_bei_shou',
        10: 'item_scroll_yan_zi_san_chao',
        15: 'item_scroll_zhu_ying_yao_hong',
        20: 'item_scroll_jin_gang_fu_mo',
        25: 'item_scroll_jing_hong_zhao_ying',
        30: 'item_scroll_yue_luo_wu_sheng',
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

    test('爬塔 6 本秘籍 dropChance=0.15(残本概率)', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);

      const towerScrolls = {
        5: 'item_scroll_kai_bei_shou',
        10: 'item_scroll_yan_zi_san_chao',
        15: 'item_scroll_zhu_ying_yao_hong',
        20: 'item_scroll_jin_gang_fu_mo',
        25: 'item_scroll_jing_hong_zhao_ying',
        30: 'item_scroll_yue_luo_wu_sheng',
      };

      for (final entry in towerScrolls.entries) {
        final floor = repo.getTowerFloor(entry.key);
        final drops = floor.dropTable
            .whereType<ItemDrop>()
            .where((e) => e.inventoryItemDefId == entry.value)
            .toList();
        expect(drops, isNotEmpty,
            reason: '爬塔第 ${entry.key} 层应有 ${entry.value} 掉落条目');
        for (final d in drops) {
          expect(
            d.dropChance,
            closeTo(0.15, 0.001),
            reason:
                '爬塔第 ${entry.key} 层秘籍 dropChance 应=0.15(T5 balance:残本概率)',
          );
        }
      }
    });
  });
}
