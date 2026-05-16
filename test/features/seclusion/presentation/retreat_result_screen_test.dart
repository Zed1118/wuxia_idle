import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/seclusion_map_def.dart';
import 'package:wuxia_idle/features/seclusion/presentation/retreat_result_screen.dart';
import 'package:wuxia_idle/ui/strings.dart';

SeclusionMapDef _mkMapDef() => SeclusionMapDef(
      mapType: RetreatMapType.shanLin,
      mapName: '山林',
      requiredRealm: RealmTier.xueTu,
      mojianshiPerHour: 1.0,
      experiencePerHour: 100,
      equipmentDropRate: 1.0,
      techniqueLearnRate: 1.0,
      internalForceGrowth: 1.0,
      biome: null,
      weather: null,
    );

RetreatOutputs _mkOutputs({
  double actualHours = 4.0,
  int mojianshi = 0,
  List<Equipment> drops = const [],
  int experience = 0,
  int techniqueLearn = 0,
  int internalForce = 0,
}) =>
    (
      actualHours: actualHours,
      mojianshi: mojianshi,
      equipmentDrops: drops,
      experiencePoints: experience,
      techniqueLearnPoints: techniqueLearn,
      internalForcePoints: internalForce,
    );

Future<void> _pump(WidgetTester tester, RetreatOutputs outputs) async {
  await tester.pumpWidget(
    MaterialApp(
      home: RetreatResultScreen(mapDef: _mkMapDef(), outputs: outputs),
    ),
  );
}

void main() {
  group('RetreatResultScreen W15 #30 4 维度展示', () {
    testWidgets('4 维度全有 → 4 行 + 实际时长', (tester) async {
      await _pump(
        tester,
        _mkOutputs(
          actualHours: 4.0,
          mojianshi: 12,
          techniqueLearn: 5,
          internalForce: 30,
        ),
      );

      expect(find.text('山林'), findsOneWidget);
      expect(find.text(UiStrings.seclusionActualHours(4.0)), findsOneWidget);
      expect(find.text(UiStrings.seclusionMojianshi(12)), findsOneWidget);
      expect(find.text(UiStrings.seclusionInternalForce(30)), findsOneWidget);
      expect(find.text(UiStrings.seclusionInsightPoints(5)), findsOneWidget);
      expect(find.text(UiStrings.seclusionResultEmpty), findsNothing);
    });

    testWidgets('只有 internalForce → 仅显内力行', (tester) async {
      await _pump(tester, _mkOutputs(internalForce: 24));

      expect(find.text(UiStrings.seclusionInternalForce(24)), findsOneWidget);
      expect(find.text(UiStrings.seclusionMojianshi(0)), findsNothing);
      expect(find.text(UiStrings.seclusionInsightPoints(0)), findsNothing);
      expect(find.text(UiStrings.seclusionResultEmpty), findsNothing);
    });

    testWidgets('只有 techniqueLearn → 仅显领悟点行', (tester) async {
      await _pump(tester, _mkOutputs(techniqueLearn: 3));

      expect(find.text(UiStrings.seclusionInsightPoints(3)), findsOneWidget);
      expect(find.text(UiStrings.seclusionMojianshi(0)), findsNothing);
      expect(find.text(UiStrings.seclusionInternalForce(0)), findsNothing);
      expect(find.text(UiStrings.seclusionResultEmpty), findsNothing);
    });

    testWidgets('4 维度全 0 → 显空收获文案', (tester) async {
      await _pump(tester, _mkOutputs());

      expect(find.text(UiStrings.seclusionResultEmpty), findsOneWidget);
      expect(find.textContaining('磨剑石'), findsNothing);
      expect(find.textContaining('内力'), findsNothing);
      expect(find.textContaining('心法领悟点'), findsNothing);
    });

    testWidgets('mojianshi + internalForce + insight 混合 → 3 行,不显空文案',
        (tester) async {
      await _pump(
        tester,
        _mkOutputs(mojianshi: 8, internalForce: 50, techniqueLearn: 2),
      );

      expect(find.text(UiStrings.seclusionMojianshi(8)), findsOneWidget);
      expect(find.text(UiStrings.seclusionInternalForce(50)), findsOneWidget);
      expect(find.text(UiStrings.seclusionInsightPoints(2)), findsOneWidget);
      expect(find.text(UiStrings.seclusionResultEmpty), findsNothing);
    });
  });
}
