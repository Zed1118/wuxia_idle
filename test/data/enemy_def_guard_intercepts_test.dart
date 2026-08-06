import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';

/// 第八阶段(spec 2026-08-05 敌方协同):EnemyDef.guardInterceptsInterrupt
/// fromYaml 联结校验(fail-fast,沿 vulnerability 开窗途径校验先例)。
///
/// 校验语义:
///   ① 配 guardInterceptsInterrupt 必须同时配 guardianWard(无护法=开关空转);
///   ② 且必须有蓄招途径(顶层 chargeSkillId 或 bossPhases 含 chargeCounter),
///     否则永不进入掩护相位=机制永不触发死配置。
void main() {
  Map<String, dynamic> baseEnemy() => {
    'id': 'enemy_p8_coop_boss',
    'name': '协同魔帅',
    'realmTier': 'zongShi',
    'realmLayer': 'huaJing',
    'school': 'gangMeng',
    'baseHp': 40000,
    'baseAttack': 800,
    'baseSpeed': 120,
    'skillIds': <String>['skill_test_charge'],
    'iconPath': 'assets/enemies/test.png',
    'isBoss': true,
  };

  Map<String, dynamic> ward() => {
    'damageTakenMult': 0.15,
    'guardianIds': <String>['enemy_p8_guard_a', 'enemy_p8_guard_b'],
  };

  test('全配(guardianWard + chargeSkillId)→ 解析成功且开关为 true', () {
    final def = EnemyDef.fromYaml({
      ...baseEnemy(),
      'chargeSkillId': 'skill_test_charge',
      'guardianWard': ward(),
      'guardInterceptsInterrupt': true,
    });
    expect(def.guardInterceptsInterrupt, isTrue);
    expect(def.guardianWard, isNotNull);
    expect(def.chargeSkillId, 'skill_test_charge');
  });

  test('不配 → 默认 false(既有配置零行为变化)', () {
    final def = EnemyDef.fromYaml({
      ...baseEnemy(),
      'chargeSkillId': 'skill_test_charge',
      'guardianWard': ward(),
    });
    expect(def.guardInterceptsInterrupt, isFalse);
  });

  test('缺 guardianWard → StateError(无护法可掩护=死配置)', () {
    expect(
      () => EnemyDef.fromYaml({
        ...baseEnemy(),
        'chargeSkillId': 'skill_test_charge',
        'guardInterceptsInterrupt': true,
      }),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('guardianWard'),
        ),
      ),
    );
  });

  test('缺蓄招途径(无 chargeSkillId 且无 chargeCounter 相位)→ StateError', () {
    expect(
      () => EnemyDef.fromYaml({
        ...baseEnemy(),
        'guardianWard': ward(),
        'guardInterceptsInterrupt': true,
      }),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', contains('蓄招途径')),
      ),
    );
  });

  test('bossPhases 含 chargeCounter 相位可替代顶层 chargeSkillId 作蓄招途径', () {
    final def = EnemyDef.fromYaml({
      ...baseEnemy(),
      'guardianWard': ward(),
      'guardInterceptsInterrupt': true,
      'bossPhases': [
        {'hpThresholdPct': 1.0, 'titleKey': null},
        {
          'hpThresholdPct': 0.5,
          'onEnterMechanic': 'chargeCounter',
          'unlockSkillIds': ['skill_test_charge'],
        },
      ],
    });
    expect(def.guardInterceptsInterrupt, isTrue);
    expect(def.chargeSkillId, isNull);
  });
}
