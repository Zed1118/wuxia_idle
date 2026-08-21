import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/features/cultivation/application/technique_skill_growth_gate.dart';

void main() {
  Map<String, dynamic> yaml({Map<String, dynamic>? skillUnlockLayers}) => {
    'id': 'tech_test',
    'name': '测试心法',
    'tier': 'ruMenGong',
    'school': 'gangMeng',
    'description': '测试',
    'skillIds': ['skill_basic', 'skill_power', 'skill_ultimate'],
    'skillUnlockLayers': ?skillUnlockLayers,
    'internalForceGrowthBonus': 1.0,
    'speedBonus': 0,
    'acquireSourceTags': <String>[],
  };

  test('未配置覆盖时保留初窥/小成/大成默认门槛', () {
    final def = TechniqueDef.fromYaml(yaml());

    expect(
      requiredLayerForTechniqueSkill(techniqueDef: def, skillId: 'skill_basic'),
      CultivationLayer.chuKui,
    );
    expect(
      requiredLayerForTechniqueSkill(techniqueDef: def, skillId: 'skill_power'),
      CultivationLayer.xiaoCheng,
    );
    expect(
      requiredLayerForTechniqueSkill(
        techniqueDef: def,
        skillId: 'skill_ultimate',
      ),
      CultivationLayer.daCheng,
    );
  });

  test('显式覆盖只提前指定 powerSkill，不连带开放 ultimate', () {
    final def = TechniqueDef.fromYaml(
      yaml(skillUnlockLayers: {'skill_power': 'chuKui'}),
    );

    expect(
      requiredLayerForTechniqueSkill(techniqueDef: def, skillId: 'skill_power'),
      CultivationLayer.chuKui,
    );
    expect(
      requiredLayerForTechniqueSkill(
        techniqueDef: def,
        skillId: 'skill_ultimate',
      ),
      CultivationLayer.daCheng,
    );
  });

  test('覆盖引用非本心法招式时 fail-fast', () {
    expect(
      () => TechniqueDef.fromYaml(
        yaml(skillUnlockLayers: {'skill_missing': 'chuKui'}),
      ),
      throwsStateError,
    );
  });

  test('覆盖使用未知修炼层时 fail-fast', () {
    expect(
      () => TechniqueDef.fromYaml(
        yaml(skillUnlockLayers: {'skill_power': 'not_a_layer'}),
      ),
      throwsStateError,
    );
  });
}
