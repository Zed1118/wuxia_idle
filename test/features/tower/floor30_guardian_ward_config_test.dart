import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// Task 4 · floor30 护法结界真数据接线
///
/// 覆盖：
///   - floor30 主 Boss（enemy_tower_boss_30）配了 guardianWard
///   - guardianWard.guardianIds 覆盖两个护法（enemy_tower_30_cultist_a/b）
///   - guardianWard.damageTakenMult ∈ (0, 1]
///   - 两个护法确实存在于 floor30 enemyTeam 中
///   - 其他所有楼层的敌人均不配 guardianWard（scope = floor30 专属）
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  tearDown(GameRepository.resetForTest);

  test('floor30 主 Boss 配置护法结界，引用护法双人组', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    final floor30 = repo.towerFloors.firstWhere((f) => f.floorIndex == 30);
    final boss = floor30.enemyTeam.firstWhere((e) => e.isBoss);

    expect(boss.guardianWard, isNotNull);
    expect(
      boss.guardianWard!.guardianIds,
      containsAll(['enemy_tower_30_cultist_a', 'enemy_tower_30_cultist_b']),
    );
    expect(boss.guardianWard!.damageTakenMult, inInclusiveRange(0.0, 1.0));

    final ids = floor30.enemyTeam.map((e) => e.id).toSet();
    expect(
      ids,
      containsAll(['enemy_tower_30_cultist_a', 'enemy_tower_30_cultist_b']),
    );
  });

  test('仅 floor30 配置护法结界，其余楼层无此配置', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    for (final f in repo.towerFloors.where((f) => f.floorIndex != 30)) {
      for (final e in f.enemyTeam) {
        expect(
          e.guardianWard,
          isNull,
          reason: 'floor ${f.floorIndex} 敌人 ${e.id} 不应配 guardianWard',
        );
      }
    }
  });
}
