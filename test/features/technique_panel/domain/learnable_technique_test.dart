import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/features/technique_panel/domain/learnable_technique.dart';

TechniqueDef def(String id, TechniqueTier tier, TechniqueSchool school) =>
    TechniqueDef(
      id: id,
      name: id,
      tier: tier,
      school: school,
      description: '',
      skillIds: const [],
      internalForceGrowthBonus: 0,
      speedBonus: 0,
      acquireSourceTags: const [],
    );

void main() {
  final all = [
    def('a_rumen', TechniqueTier.ruMenGong, TechniqueSchool.gangMeng),
    def('b_rumen', TechniqueTier.ruMenGong, TechniqueSchool.lingQiao),
    def('c_changlian', TechniqueTier.changLianGong, TechniqueSchool.gangMeng),
    def('d_mingjia', TechniqueTier.mingJiaGong, TechniqueSchool.yinRou),
  ];

  test('排除已持有的 defId', () {
    final out = computeLearnableTechniques(
      allDefs: all,
      ownedDefIds: {'a_rumen'},
      realmTierCap: TechniqueTier.mingJiaGong,
    );
    expect(out.map((e) => e.def.id), isNot(contains('a_rumen')));
    expect(out, hasLength(3));
  });

  test('境界 cap 内 learnable=true，超阶 learnable=false 但仍列出', () {
    final out = computeLearnableTechniques(
      allDefs: all,
      ownedDefIds: const {},
      realmTierCap: TechniqueTier.ruMenGong,
    );
    // 全部列出（含超阶），只是 learnable 标记不同。
    expect(out, hasLength(4));
    final byId = {for (final e in out) e.def.id: e.learnable};
    expect(byId['a_rumen'], isTrue);
    expect(byId['b_rumen'], isTrue);
    expect(byId['c_changlian'], isFalse); // changLianGong > ruMenGong
    expect(byId['d_mingjia'], isFalse);
  });

  test('排序：tier 低→高，同 tier 按流派枚举序', () {
    final out = computeLearnableTechniques(
      allDefs: all,
      ownedDefIds: const {},
      realmTierCap: TechniqueTier.mingJiaGong,
    );
    expect(out.map((e) => e.def.id), [
      'a_rumen',
      'b_rumen',
      'c_changlian',
      'd_mingjia',
    ]);
  });

  test('空 def 集 → 空列表', () {
    expect(
      computeLearnableTechniques(
        allDefs: const [],
        ownedDefIds: const {},
        realmTierCap: TechniqueTier.ruMenGong,
      ),
      isEmpty,
    );
  });
}
