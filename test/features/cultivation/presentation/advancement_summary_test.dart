import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/presentation/advancement_summary.dart';

AdvancementResult _advanced({
  int layersGained = 1,
  RealmTier tierAfter = RealmTier.xueTu,
  RealmLayer layerAfter = RealmLayer.jingTong,
}) =>
    AdvancementResult(
      layersGained: layersGained,
      tierBefore: RealmTier.xueTu,
      layerBefore: RealmLayer.qiMeng,
      tierAfter: tierAfter,
      layerAfter: layerAfter,
      internalForceMaxBefore: 500,
      internalForceMaxAfter: 800,
    );

AdvancementResult _flat() => const AdvancementResult(
      layersGained: 0,
      tierBefore: RealmTier.xueTu,
      layerBefore: RealmLayer.qiMeng,
      tierAfter: RealmTier.xueTu,
      layerAfter: RealmLayer.qiMeng,
      internalForceMaxBefore: 500,
      internalForceMaxAfter: 500,
    );

Future<void> _pump(WidgetTester tester, List<AdvancementEntry> entries) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: AdvancementSummary(entries: entries)),
    ),
  );
}

void main() {
  group('AdvancementSummary', () {
    testWidgets('empty entries → SizedBox.shrink 不渲染 banner', (tester) async {
      await _pump(tester, const []);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('1 character didAdvance=false → 不渲染 banner', (tester) async {
      await _pump(tester, [
        AdvancementEntry(chName: '甲', result: _flat()),
      ]);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
      expect(find.textContaining('甲'), findsNothing);
    });

    testWidgets('1 character layers=1 → 显「突破至」', (tester) async {
      await _pump(tester, [
        AdvancementEntry(chName: '甲', result: _advanced(layersGained: 1)),
      ]);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.textContaining('甲 · 突破至'), findsOneWidget);
      expect(find.textContaining('连破'), findsNothing);
    });

    testWidgets('1 character layers=4 → 显「连破 4 层 →」', (tester) async {
      await _pump(tester, [
        AdvancementEntry(chName: '乙', result: _advanced(layersGained: 4)),
      ]);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.textContaining('乙 · 连破 4 层'), findsOneWidget);
    });

    // H2 C2:大境界突破(crossedTier)走醒目标记,区别于小层升级。
    testWidgets('crossedTier=true → 大境界突破标记(military_tech + badge)',
        (tester) async {
      await _pump(tester, [
        AdvancementEntry(
          chName: '甲',
          result: _advanced(
            layersGained: 1,
            tierAfter: RealmTier.sanLiu,
            layerAfter: RealmLayer.qiMeng,
          ),
        ),
      ]);
      expect(find.byIcon(Icons.military_tech), findsOneWidget);
      expect(find.textContaining('大境界突破'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsNothing,
          reason: '大境界突破不用普通小层升级图标');
    });

    testWidgets('crossedTier + 同 tier 升层 mixed → 各走各样式', (tester) async {
      await _pump(tester, [
        AdvancementEntry(
          chName: '甲',
          result: _advanced(
            layersGained: 1,
            tierAfter: RealmTier.sanLiu,
            layerAfter: RealmLayer.qiMeng,
          ),
        ),
        AdvancementEntry(chName: '乙', result: _advanced(layersGained: 2)),
      ]);
      expect(find.byIcon(Icons.military_tech), findsOneWidget,
          reason: '甲 跨 tier');
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget,
          reason: '乙 同 tier 小层升级');
      expect(find.textContaining('大境界突破'), findsOneWidget);
    });

    testWidgets('多 character mixed → 仅显 didAdvance=true', (tester) async {
      await _pump(tester, [
        AdvancementEntry(chName: '甲', result: _advanced(layersGained: 1)),
        AdvancementEntry(chName: '乙', result: _flat()),
        AdvancementEntry(chName: '丙', result: _advanced(layersGained: 2)),
      ]);
      expect(find.byIcon(Icons.auto_awesome), findsNWidgets(2));
      expect(find.textContaining('甲 · 突破至'), findsOneWidget);
      expect(find.textContaining('乙'), findsNothing);
      expect(find.textContaining('丙 · 连破 2 层'), findsOneWidget);
    });
  });
}
