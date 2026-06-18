import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('SkillDef.defenseBreakPct 默认 0、可从 yaml parse', () {
    const d = SkillDef(
      id: 'x', name: 'x', description: 'x', type: SkillType.powerSkill,
      powerMultiplier: 1000, internalForceCost: 50, cooldownTurns: 2,
      requiresManualTrigger: false, visualEffect: 'none',
    );
    expect(d.defenseBreakPct, 0.0);

    final parsed = SkillDef.fromYaml({
      'id': 'y', 'name': 'y', 'description': 'y', 'type': 'powerSkill',
      'powerMultiplier': 1000, 'internalForceCost': 50, 'cooldownTurns': 2,
      'requiresManualTrigger': false, 'visualEffect': 'none',
      'defenseBreakPct': 0.3,
    });
    expect(parsed.defenseBreakPct, 0.3);
  });

  test('SkillDef.fromYaml 缺 defenseBreakPct key 时 fallback 0.0', () {
    // 镜像 skill_def_p0_test.dart canInterrupt 缺省 key 模式
    final y = {
      'id': 'z', 'name': 'z', 'description': 'z', 'type': 'powerSkill',
      'powerMultiplier': 500, 'internalForceCost': 30, 'cooldownTurns': 1,
      'requiresManualTrigger': false, 'visualEffect': 'none',
      // 故意不含 defenseBreakPct
    };
    expect(SkillDef.fromYaml(y).defenseBreakPct, 0.0);
  });

  test('DefenseBreakConfig.fromYaml 解析 + fallback 默认', () {
    final c = DefenseBreakConfig.fromYaml({'window_ticks': 3, 'defense_down_pct': 0.3});
    expect(c.windowTicks, 3);
    expect(c.defenseDownPct, 0.3);
    final fb = DefenseBreakConfig.fromYaml({});
    expect(fb.windowTicks, 3);
    expect(fb.defenseDownPct, 0.3);
  });
}
