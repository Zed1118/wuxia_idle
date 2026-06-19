// test/features/loot_preview/weakness_hint_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/loot_preview/domain/weakness_hint.dart';
import 'package:wuxia_idle/shared/strings.dart';

EnemyDef _enemy({
  String id = 'e',
  bool isBoss = false,
  Map<TechniqueSchool, double>? mult,
}) =>
    EnemyDef(
      id: id,
      name: 'n',
      realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      baseHp: 100,
      baseAttack: 10,
      baseSpeed: 100,
      skillIds: const [],
      iconPath: 'x',
      isBoss: isBoss,
      schoolDamageTakenMult: mult,
    );

void main() {
  group('weaknessHintLines(批二② 事后可查)', () {
    test('未通关 → 空（§5.7 先感受问题再给答案）', () {
      final team = [
        _enemy(
          isBoss: true,
          mult: {TechniqueSchool.lingQiao: 1.5},
        ),
      ];
      expect(weaknessHintLines(team, cleared: false), isEmpty);
    });

    test('通关 + Boss 有弱点 → 「似惧 X 路数」', () {
      final team = [
        _enemy(isBoss: true, mult: {TechniqueSchool.lingQiao: 1.5}),
      ];
      final lines = weaknessHintLines(team, cleared: true);
      expect(lines, isNotEmpty);
      expect(
        lines.first,
        UiStrings.weaknessHintWeak(EnumL10n.school(TechniqueSchool.lingQiao)),
      );
    });

    test('通关 + Boss 有抗性 → 「X 路难伤」', () {
      final team = [
        _enemy(isBoss: true, mult: {TechniqueSchool.yinRou: 0.5}),
      ];
      final lines = weaknessHintLines(team, cleared: true);
      expect(
        lines,
        contains(
          UiStrings.weaknessHintResist(EnumL10n.school(TechniqueSchool.yinRou)),
        ),
      );
    });

    test('通关 + Boss 弱点+抗性混合 → 两行都出', () {
      final team = [
        _enemy(isBoss: true, mult: {
          TechniqueSchool.lingQiao: 1.5,
          TechniqueSchool.yinRou: 0.5,
        }),
      ];
      final lines = weaknessHintLines(team, cleared: true);
      expect(lines.length, 2);
      expect(
        lines,
        contains(
          UiStrings.weaknessHintWeak(EnumL10n.school(TechniqueSchool.lingQiao)),
        ),
      );
      expect(
        lines,
        contains(
          UiStrings.weaknessHintResist(EnumL10n.school(TechniqueSchool.yinRou)),
        ),
      );
    });

    test('通关 + Boss 无 schoolDamageTakenMult → 空（常见情况）', () {
      final team = [_enemy(isBoss: true, mult: null)];
      expect(weaknessHintLines(team, cleared: true), isEmpty);
    });

    test('mult==1.0 中性条目不出行', () {
      final team = [
        _enemy(isBoss: true, mult: {TechniqueSchool.gangMeng: 1.0}),
      ];
      expect(weaknessHintLines(team, cleared: true), isEmpty);
    });

    test('无 isBoss 标记时回退到队伍中的敌人(单敌)', () {
      final team = [
        _enemy(isBoss: false, mult: {TechniqueSchool.lingQiao: 1.5}),
      ];
      final lines = weaknessHintLines(team, cleared: true);
      expect(
        lines.first,
        UiStrings.weaknessHintWeak(EnumL10n.school(TechniqueSchool.lingQiao)),
      );
    });

    test('多敌只取 isBoss==true 的那个', () {
      final team = [
        _enemy(id: 'minion', mult: {TechniqueSchool.gangMeng: 1.5}),
        _enemy(id: 'boss', isBoss: true, mult: {TechniqueSchool.yinRou: 0.5}),
      ];
      final lines = weaknessHintLines(team, cleared: true);
      expect(
        lines,
        contains(
          UiStrings.weaknessHintResist(EnumL10n.school(TechniqueSchool.yinRou)),
        ),
      );
      // minion 的弱点不应进结果（只取 boss）。
      expect(
        lines,
        isNot(contains(
          UiStrings.weaknessHintWeak(EnumL10n.school(TechniqueSchool.gangMeng)),
        )),
      );
    });

    test('空队伍 → 空', () {
      expect(weaknessHintLines(const [], cleared: true), isEmpty);
    });
  });
}
