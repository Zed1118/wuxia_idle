import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';

void main() {
  test('无 proficiency 字段 → null(向后兼容)', () {
    final s = SkillDef.fromYaml({
      'id': 's1', 'name': 'x', 'description': 'd', 'type': 'normalAttack',
      'powerMultiplier': 500, 'internalForceCost': 0, 'cooldownTurns': 0,
      'requiresManualTrigger': false, 'visualEffect': 'v',
    });
    expect(s.proficiency, isNull);
  });

  test('proficiency.effects 按阶段解析 damage_pct / cooldown_delta', () {
    final s = SkillDef.fromYaml({
      'id': 's2', 'name': 'x', 'description': 'd', 'type': 'powerSkill',
      'powerMultiplier': 1200, 'internalForceCost': 180, 'cooldownTurns': 6,
      'requiresManualTrigger': false, 'visualEffect': 'v',
      'proficiency': {
        'effects': {
          'shunShou': {'cooldown_delta': -1},
          'shuLian': {'damage_pct': 0.08},
          'jingTong': {'interrupt_power_pct': 0.12},
          'huaJing': {'interrupt_window_bonus_ticks': 1},
        }
      },
    });
    expect(s.proficiency, isNotNull);
    expect(s.proficiency!.damagePctAt('shuLian'), 0.08);
    expect(s.proficiency!.damagePctAt('chuShi'), 0.0);
    expect(s.proficiency!.cooldownDeltaAt('shunShou'), -1);
    expect(s.proficiency!.interruptPowerPctAt('jingTong'), 0.12);
    expect(s.proficiency!.interruptWindowBonusAt('huaJing'), 1);
  });
}
