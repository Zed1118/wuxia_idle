import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';

Map<String, dynamic> techniqueYaml({Map<String, dynamic>? qiProfile}) => {
  'id': 'tech_test',
  'name': '测试心法',
  'tier': 'ruMenGong',
  'school': 'gangMeng',
  'description': '测试',
  'skillIds': <String>[],
  'internalForceGrowthBonus': 1.0,
  'speedBonus': 0,
  'acquireSourceTags': <String>[],
  'qiProfile': ?qiProfile,
};

void main() {
  test('心法未配置真气倾向时全为中性', () {
    final def = TechniqueDef.fromYaml(techniqueYaml());

    expect(def.qiProfile.maxBonus, 0);
    expect(def.qiProfile.openingBonus, 0);
    expect(def.qiProfile.gainPct, 0);
    expect(def.qiProfile.costReductionPct, 0);
  });

  test('心法真气倾向完整解析', () {
    final def = TechniqueDef.fromYaml(
      techniqueYaml(
        qiProfile: {
          'maxBonus': 20,
          'openingBonus': 15,
          'gainPct': 0.25,
          'costReductionPct': 0.10,
        },
      ),
    );

    expect(def.qiProfile.maxBonus, 20);
    expect(def.qiProfile.openingBonus, 15);
    expect(def.qiProfile.gainPct, 0.25);
    expect(def.qiProfile.costReductionPct, 0.10);
  });
}
