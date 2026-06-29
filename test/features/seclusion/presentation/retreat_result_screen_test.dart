import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/image_test_helpers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_factory.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/seclusion_map_def.dart';
import 'package:wuxia_idle/features/seclusion/presentation/retreat_result_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

SeclusionMapDef _mkMapDef() => const SeclusionMapDef(
  mapType: RetreatMapType.shanLin,
  mapName: '山林',
  requiredRealm: RealmTier.xueTu,
  mojianshiPerHour: 1.0,
  silverPerHour: 5.0,
  experiencePerHour: 100,
  equipmentDropRate: 1.0,
  techniqueLearnRate: 1.0,
  internalForceGrowth: 1.0,
  biome: null,
  weather: null,
  routeSteps: ['沿旧樵径入山', '在溪石旁结庐调息'],
  eventNotes: [
    RetreatMapEventDef(
      triggerAfterHours: 1,
      kind: RetreatMapEventKind.harvest,
      text: '溪畔药香渐浓',
    ),
  ],
);

RetreatResult _mkResult({
  double actualHours = 4.0,
  int mojianshi = 0,
  int silver = 0,
  Map<String, int> itemRewards = const {},
  List<Equipment> drops = const [],
  int experience = 0,
  int techniqueLearn = 0,
  int internalForce = 0,
  List<String>? routeSteps,
  List<RetreatMapEventRecord>? mapEvents,
  AdvancementResult? advancement,
}) => (
  actualHours: actualHours,
  mojianshi: mojianshi,
  silver: silver,
  itemRewards: itemRewards,
  equipmentDrops: drops,
  experiencePoints: experience,
  techniqueLearnPoints: techniqueLearn,
  internalForcePoints: internalForce,
  routeSteps: routeSteps ?? const [],
  mapEvents: mapEvents ?? const [],
  advancement: advancement,
);

Future<void> _pump(WidgetTester tester, RetreatResult result) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: RetreatResultScreen(mapDef: _mkMapDef(), result: result),
      ),
    ),
  );
}

Finder _assetImage(String path) => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      assetNameOf(w.image) == path,
);

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // H1 批3:闭关结果装备显中文名而非 raw defId(真 bug 回归守护)。
  group('RetreatResultScreen 装备掉落显中文名', () {
    testWidgets('装备掉落 → 显中文名,不显 raw defId', (tester) async {
      final tieJian = EquipmentFactory.fromDef(
        GameRepository.instance.getEquipment('weapon_xunchang_tie_jian'),
        rng: DefaultRng(seed: 1),
        obtainedAt: DateTime(2026, 5, 30),
        obtainedFrom: '闭关',
      );
      await _pump(tester, _mkResult(drops: [tieJian]));

      expect(find.text('铁剑'), findsOneWidget);
      expect(find.textContaining('weapon_xunchang'), findsNothing);
    });
  });

  testWidgets('通用物品奖励显示 items.yaml 名称与数量', (tester) async {
    await _pump(tester, _mkResult(itemRewards: {'item_yaocao': 3}));

    expect(find.textContaining('药草 × 3'), findsOneWidget);
    expect(find.textContaining('item_yaocao'), findsNothing);
  });

  group('RetreatResultScreen W15 #30 维度展示', () {
    testWidgets('资源维度全有 → 展示各收益 + 实际时长', (tester) async {
      await _pump(
        tester,
        _mkResult(
          actualHours: 4.0,
          mojianshi: 12,
          silver: 20,
          experience: 400,
          techniqueLearn: 5,
          internalForce: 30,
        ),
      );

      expect(find.text('山林'), findsOneWidget);
      expect(_assetImage(WuxiaUi.ceremonyRetreatResult), findsOneWidget);
      expect(find.text(UiStrings.seclusionActualHours(4.0)), findsOneWidget);
      expect(find.text(UiStrings.seclusionMojianshi(12)), findsOneWidget);
      expect(find.text(UiStrings.seclusionSilver(20)), findsOneWidget);
      expect(find.text(UiStrings.seclusionExperience(400)), findsOneWidget);
      expect(find.text(UiStrings.seclusionInternalForce(30)), findsOneWidget);
      expect(find.text(UiStrings.seclusionInsightPoints(5)), findsOneWidget);
      expect(find.text(UiStrings.seclusionResultEmpty), findsNothing);
    });

    testWidgets('地图路径与事件记录从结果数据展示', (tester) async {
      await _pump(
        tester,
        _mkResult(
          routeSteps: const ['沿旧樵径入山', '在溪石旁结庐调息'],
          mapEvents: const [
            RetreatMapEventRecord(
              hourMark: 1,
              kind: RetreatMapEventKind.harvest,
              text: '溪畔药香渐浓',
            ),
          ],
        ),
      );

      expect(find.text(UiStrings.seclusionResultRouteTitle), findsOneWidget);
      expect(find.text('沿旧樵径入山'), findsOneWidget);
      expect(find.text('在溪石旁结庐调息'), findsOneWidget);
      expect(find.textContaining('溪畔药香渐浓'), findsOneWidget);
      expect(
        find.textContaining(UiStrings.seclusionMapEventHarvest),
        findsOneWidget,
      );
    });

    testWidgets('只有 internalForce → 仅显内力行', (tester) async {
      await _pump(tester, _mkResult(internalForce: 24));

      expect(find.text(UiStrings.seclusionInternalForce(24)), findsOneWidget);
      expect(find.text(UiStrings.seclusionMojianshi(0)), findsNothing);
      expect(find.text(UiStrings.seclusionInsightPoints(0)), findsNothing);
      expect(find.text(UiStrings.seclusionExperience(0)), findsNothing);
      expect(find.text(UiStrings.seclusionResultEmpty), findsNothing);
    });

    testWidgets('只有 techniqueLearn → 仅显领悟点行', (tester) async {
      await _pump(tester, _mkResult(techniqueLearn: 3));

      expect(find.text(UiStrings.seclusionInsightPoints(3)), findsOneWidget);
      expect(find.text(UiStrings.seclusionMojianshi(0)), findsNothing);
      expect(find.text(UiStrings.seclusionInternalForce(0)), findsNothing);
      expect(find.text(UiStrings.seclusionResultEmpty), findsNothing);
    });

    testWidgets('只有 experience → 仅显经验行', (tester) async {
      await _pump(tester, _mkResult(experience: 250));

      expect(find.text(UiStrings.seclusionExperience(250)), findsOneWidget);
      expect(find.text(UiStrings.seclusionMojianshi(0)), findsNothing);
      expect(find.text(UiStrings.seclusionResultEmpty), findsNothing);
    });

    testWidgets('5 维度全 0 → 显空收获文案', (tester) async {
      await _pump(tester, _mkResult());

      expect(find.text(UiStrings.seclusionResultEmpty), findsOneWidget);
      expect(find.textContaining('磨剑石'), findsNothing);
      expect(find.textContaining('内力'), findsNothing);
      expect(find.textContaining('心法领悟点'), findsNothing);
      expect(find.textContaining('经验'), findsNothing);
    });

    testWidgets('mojianshi + internalForce + insight 混合 → 3 行,不显空文案', (
      tester,
    ) async {
      await _pump(
        tester,
        _mkResult(mojianshi: 8, internalForce: 50, techniqueLearn: 2),
      );

      expect(find.text(UiStrings.seclusionMojianshi(8)), findsOneWidget);
      expect(find.text(UiStrings.seclusionInternalForce(50)), findsOneWidget);
      expect(find.text(UiStrings.seclusionInsightPoints(2)), findsOneWidget);
      expect(find.text(UiStrings.seclusionResultEmpty), findsNothing);
    });
  });

  group('RetreatResultScreen W15 #30 P3 升层 banner', () {
    AdvancementResult mkAdv({
      required int layers,
      required RealmTier tierAfter,
      required RealmLayer layerAfter,
    }) => AdvancementResult(
      layersGained: layers,
      tierBefore: RealmTier.xueTu,
      layerBefore: RealmLayer.qiMeng,
      tierAfter: tierAfter,
      layerAfter: layerAfter,
      internalForceMaxBefore: 500,
      internalForceMaxAfter: 800,
    );

    testWidgets('升 1 层 → 显「突破至 学徒精通」', (tester) async {
      await _pump(
        tester,
        _mkResult(
          experience: 400,
          advancement: mkAdv(
            layers: 1,
            tierAfter: RealmTier.xueTu,
            layerAfter: RealmLayer.jingTong,
          ),
        ),
      );

      expect(find.text('突破至 学徒精通'), findsOneWidget);
    });

    testWidgets('跨 tier 升 4 层 → 显「连破 4 层 → 三流入门」', (tester) async {
      await _pump(
        tester,
        _mkResult(
          experience: 2000,
          advancement: mkAdv(
            layers: 4,
            tierAfter: RealmTier.sanLiu,
            layerAfter: RealmLayer.ruMen,
          ),
        ),
      );

      expect(find.text('连破 4 层 → 三流入门'), findsOneWidget);
    });

    testWidgets('advancement 为 null → 无升层 banner', (tester) async {
      await _pump(tester, _mkResult(experience: 50, advancement: null));

      expect(find.textContaining('突破'), findsNothing);
      expect(find.textContaining('连破'), findsNothing);
    });

    testWidgets('advancement layersGained=0 → didAdvance=false → 无 banner', (
      tester,
    ) async {
      await _pump(
        tester,
        _mkResult(
          experience: 30,
          advancement: mkAdv(
            layers: 0,
            tierAfter: RealmTier.xueTu,
            layerAfter: RealmLayer.qiMeng,
          ),
        ),
      );

      expect(find.textContaining('突破'), findsNothing);
      expect(find.textContaining('连破'), findsNothing);
    });
  });

  group('RetreatResultScreen 根因A B3 sink 引导气泡', () {
    testWidgets('insightPoints > 0 → 显「去心法面板凝练」提示', (tester) async {
      await _pump(tester, _mkResult(techniqueLearn: 5));

      expect(find.text(UiStrings.seclusionInsightHint), findsOneWidget);
    });

    testWidgets('insightPoints == 0 → 不显凝练提示', (tester) async {
      await _pump(tester, _mkResult(internalForce: 24));

      expect(find.text(UiStrings.seclusionInsightHint), findsNothing);
    });

    testWidgets('空收获(全 0)→ 不显凝练提示', (tester) async {
      await _pump(tester, _mkResult());

      expect(find.text(UiStrings.seclusionInsightHint), findsNothing);
    });
  });
}
