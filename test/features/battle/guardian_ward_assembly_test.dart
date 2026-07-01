import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  test('_enemyToBattle 透传 enemyDefId + ward 字段', () {
    final boss = EnemyDef.fromYaml({
      'id': 'enemy_boss',
      'name': 'B',
      'realmTier': 'zongShi',
      'realmLayer': 'dengFeng',
      'school': 'yinRou',
      'baseHp': 42000,
      'baseAttack': 2800,
      'baseSpeed': 245,
      'skillIds': <String>[],
      'iconPath': 'x.png',
      'isBoss': true,
      'guardianWard': {
        'damageTakenMult': 0.15,
        'guardianIds': ['g_a'],
      },
    });
    final bc = StageBattleSetup.debugEnemyToBattle(enemy: boss, slotIndex: 0);
    expect(bc.enemyDefId, 'enemy_boss');
    expect(bc.guardianWardMult, 0.15);
    expect(bc.guardianDefIds, ['g_a']);
  });

  test('无 guardianWard 的敌人 → ward 字段空、enemyDefId 仍透传', () {
    final minion = EnemyDef.fromYaml({
      'id': 'enemy_minion',
      'name': 'M',
      'realmTier': 'zongShi',
      'realmLayer': 'jingTong',
      'school': 'gangMeng',
      'baseHp': 4000,
      'baseAttack': 700,
      'baseSpeed': 220,
      'skillIds': <String>[],
      'iconPath': 'x.png',
      'isBoss': false,
    });
    final bc = StageBattleSetup.debugEnemyToBattle(enemy: minion, slotIndex: 1);
    expect(bc.enemyDefId, 'enemy_minion');
    expect(bc.guardianWardMult, isNull);
    expect(bc.guardianDefIds, isEmpty);
  });
}
