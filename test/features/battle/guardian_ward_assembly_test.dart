import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';

import '../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

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

  test('_enemyToBattle 透传 vulnerability.outOfWindowDamageMult', () {
    final boss = EnemyDef.fromYaml({
      'id': 'enemy_boss_vuln',
      'name': 'BV',
      'realmTier': 'zongShi',
      'realmLayer': 'dengFeng',
      'school': 'yinRou',
      'baseHp': 42000,
      'baseAttack': 2800,
      'baseSpeed': 245,
      'skillIds': <String>[],
      'iconPath': 'x.png',
      'isBoss': true,
      'chargeSkillId': 'skill_charge',
      'vulnerability': {'outOfWindowDamageMult': 0.10},
    });
    final bc = StageBattleSetup.debugEnemyToBattle(enemy: boss, slotIndex: 0);
    expect(bc.vulnerabilityMult, 0.10);
  });

  test('无 vulnerability 的敌人 → vulnerabilityMult 空', () {
    final minion = EnemyDef.fromYaml({
      'id': 'enemy_minion_no_vuln',
      'name': 'M2',
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
    expect(bc.vulnerabilityMult, isNull);
  });
}
