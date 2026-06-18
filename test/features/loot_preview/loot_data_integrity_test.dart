import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(loader: fileLoader);
  });

  tearDown(GameRepository.resetForTest);

  // 白名单：设计上允许无固定掉落的主线关（加注释说明原因）。
  // 目前留空——发现实际空表时由 controller 决策是否加入。
  const stagesNoDropWhitelist = <String>{};

  // 白名单：设计上允许无固定掉落的塔层（同上）。
  const towerFloorsNoDropWhitelist = <int>{};

  test('每主线关 dropTable 非空（或白名单）', () {
    final mainlineStages = repo.stageDefs.values
        .where((s) => s.stageType == StageType.mainline)
        .toList();

    expect(mainlineStages, isNotEmpty, reason: '主线关卡不应为空');

    final violations = <String>[];
    for (final stage in mainlineStages) {
      if (stage.dropTable.isEmpty && !stagesNoDropWhitelist.contains(stage.id)) {
        violations.add(stage.id);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          '以下主线关 dropTable 为空，需加白名单注释或补数据：\n${violations.join('\n')}',
    );
  });

  test('每塔层 dropTable 非空（或白名单）', () {
    final floors = repo.towerFloors;

    expect(floors, isNotEmpty, reason: '塔层列表不应为空');

    final violations = <int>[];
    for (final floor in floors) {
      if (floor.dropTable.isEmpty &&
          !towerFloorsNoDropWhitelist.contains(floor.floorIndex)) {
        violations.add(floor.floorIndex);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          '以下塔层 dropTable 为空，需加白名单注释或补数据：floors ${violations.join(', ')}',
    );
  });

  test(
    '不越阶守卫:dropTable 装备 tier ≤ 关卡 requiredRealm + 2 阶（允许章末 Boss 前瞻奖励，拦离谱越界如早关掉神物）',
    () {
      // 语义（非瞬时事实）：掉落允许前瞻——章末 Boss 给 +1~+2 阶好装作奖励，
      // 玩家可获得/携带，境界到了才可装备（GDD §5.3）。守卫只拦「离谱越界」
      // （如早章掉神物），上限 = 当前 requiredRealm + 2 阶。
      final violations = <String>[];

      // 主线关卡
      for (final stage in repo.stageDefs.values) {
        for (final drop in stage.dropTable.whereType<EquipmentDrop>()) {
          final equipment = repo.getEquipment(drop.equipmentDefId);
          if (equipment.tier.index > stage.requiredRealm.index + 2) {
            violations.add(
              'stage=${stage.id} requiredRealm=${stage.requiredRealm.name}(${stage.requiredRealm.index})'
              ' 掉落 ${drop.equipmentDefId} tier=${equipment.tier.name}(${equipment.tier.index})',
            );
          }
        }
      }

      // 塔层
      for (final floor in repo.towerFloors) {
        for (final drop in floor.dropTable.whereType<EquipmentDrop>()) {
          final equipment = repo.getEquipment(drop.equipmentDefId);
          if (equipment.tier.index > floor.requiredRealm.index + 2) {
            violations.add(
              'tower floor=${floor.floorIndex} requiredRealm=${floor.requiredRealm.name}(${floor.requiredRealm.index})'
              ' 掉落 ${drop.equipmentDefId} tier=${equipment.tier.name}(${equipment.tier.index})',
            );
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: '以下关卡/塔层存在越阶掉落（超出 requiredRealm + 2）：\n${violations.join('\n')}',
      );
    },
  );
}
