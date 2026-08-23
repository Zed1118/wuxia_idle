import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/mainline_wave_def.dart';

Map<String, dynamic> validYaml() => {
  'ordinary': {
    'waves': [
      {'count': 2},
      {'count': 3},
    ],
    'boss_final_enemy_count': 0,
    'hp_multiplier': 0.1,
    'attack_multiplier': 0.25,
    'output_multiplier': 0.25,
    'speed_multiplier': 0.85,
  },
  'boss': {
    'waves': [
      {'count': 2},
    ],
    'boss_final_enemy_count': 1,
    'hp_multiplier': 0.1,
    'attack_multiplier': 0.25,
    'output_multiplier': 0.25,
    'speed_multiplier': 0.85,
  },
  'wave_intermission': {
    'reset_action_point': true,
    'preserve_hp': true,
    'preserve_cooldowns': false,
    'alive_if_recovery_pct': 0.25,
  },
};

void main() {
  test('普通 profile 必须显式为零终波主敌人', () {
    final yaml = validYaml();
    (yaml['ordinary'] as Map)['boss_final_enemy_count'] = 1;
    expect(() => MainlineWaveDef.fromYaml(yaml), throwsStateError);
  });

  test('波间 HP 必须显式 preserve_hp，避免半回血假配置', () {
    final yaml = validYaml();
    (yaml['wave_intermission'] as Map).remove('preserve_hp');
    expect(() => MainlineWaveDef.fromYaml(yaml), throwsStateError);
  });

  test('波次 count 与派生比例必须在 schema 范围内', () {
    final yaml = validYaml();
    ((yaml['ordinary'] as Map)['waves'] as List).first['count'] = 0;
    expect(() => MainlineWaveDef.fromYaml(yaml), throwsStateError);

    final invalidRatio = validYaml();
    (invalidRatio['boss'] as Map)['output_multiplier'] = 1.1;
    expect(() => MainlineWaveDef.fromYaml(invalidRatio), throwsStateError);
  });
}
