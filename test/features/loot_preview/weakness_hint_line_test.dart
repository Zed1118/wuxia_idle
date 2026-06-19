// test/features/loot_preview/weakness_hint_line_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/loot_preview/presentation/weakness_hint_line.dart';
import 'package:wuxia_idle/shared/strings.dart';

Widget _host(Widget body) => MaterialApp(home: Scaffold(body: body));

EnemyDef _boss(Map<TechniqueSchool, double>? mult) => EnemyDef(
      id: 'boss',
      name: 'n',
      realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      baseHp: 100,
      baseAttack: 10,
      baseSpeed: 100,
      skillIds: const [],
      iconPath: 'x',
      isBoss: true,
      schoolDamageTakenMult: mult,
    );

void main() {
  testWidgets('未通关 → shrink（不渲染任何提示行）', (tester) async {
    await tester.pumpWidget(_host(WeaknessHintLine(
      enemyTeam: [_boss({TechniqueSchool.lingQiao: 1.5})],
      cleared: false,
    )));
    expect(
      find.textContaining(
        UiStrings.weaknessHintWeak(EnumL10n.school(TechniqueSchool.lingQiao)),
      ),
      findsNothing,
    );
  });

  testWidgets('通关 + 弱点 → 渲染「似惧 X 路数」', (tester) async {
    await tester.pumpWidget(_host(WeaknessHintLine(
      enemyTeam: [_boss({TechniqueSchool.lingQiao: 1.5})],
      cleared: true,
    )));
    expect(
      find.text(
        UiStrings.weaknessHintWeak(EnumL10n.school(TechniqueSchool.lingQiao)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('通关 + 无配置 → shrink', (tester) async {
    await tester.pumpWidget(_host(WeaknessHintLine(
      enemyTeam: [_boss(null)],
      cleared: true,
    )));
    expect(find.byType(Text), findsNothing);
  });
}
