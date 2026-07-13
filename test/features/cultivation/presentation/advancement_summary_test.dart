import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/domain/advancement_entry.dart';
import 'package:wuxia_idle/features/cultivation/domain/realm_progress_display.dart';
import 'package:wuxia_idle/features/cultivation/presentation/advancement_summary.dart';
import 'package:wuxia_idle/shared/strings.dart';

RealmProgressDisplay _display(int level) => RealmProgressDisplay(
  level: level,
  experience: 50,
  experienceToNext: 100,
  progress: 0.5,
  state: RealmProgressDisplayState.progressing,
);

AdvancementResult _advanced({
  int layersGained = 1,
  RealmTier tierAfter = RealmTier.xueTu,
  RealmLayer layerAfter = RealmLayer.jingTong,
}) => AdvancementResult(
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

AdvancementResult _levelOnly() => AdvancementResult(
  layersGained: 0,
  tierBefore: RealmTier.erLiu,
  layerBefore: RealmLayer.yuanShu,
  tierAfter: RealmTier.erLiu,
  layerAfter: RealmLayer.yuanShu,
  internalForceMaxBefore: 3500,
  internalForceMaxAfter: 3500,
  experienceGained: 50,
  progressChange: RealmProgressChange(
    before: _display(186),
    after: _display(187),
  ),
);

AdvancementResult _experienceOnly() => AdvancementResult(
  layersGained: 0,
  tierBefore: RealmTier.erLiu,
  layerBefore: RealmLayer.yuanShu,
  tierAfter: RealmTier.erLiu,
  layerAfter: RealmLayer.yuanShu,
  internalForceMaxBefore: 3500,
  internalForceMaxAfter: 3500,
  experienceGained: 50,
  progressChange: RealmProgressChange(
    before: _display(186),
    after: _display(186),
  ),
);

AdvancementResult _realmAndLevel() => AdvancementResult(
  layersGained: 1,
  tierBefore: RealmTier.xueTu,
  layerBefore: RealmLayer.qiMeng,
  tierAfter: RealmTier.xueTu,
  layerAfter: RealmLayer.ruMen,
  internalForceMaxBefore: 500,
  internalForceMaxAfter: 650,
  experienceGained: 100,
  progressChange: RealmProgressChange(
    before: _display(10),
    after: _display(11),
  ),
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
        AdvancementEntry(characterId: 1, chName: '甲', result: _flat()),
      ]);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
      expect(find.textContaining('甲'), findsNothing);
    });

    testWidgets('derived level change renders inside cultivation summary', (
      tester,
    ) async {
      await _pump(tester, [
        AdvancementEntry(characterId: 1, chName: '甲', result: _levelOnly()),
      ]);

      expect(
        find.text(UiStrings.cultivationLevelChanged('甲', 186, 187)),
        findsOneWidget,
      );
      expect(find.textContaining('晋 ·'), findsNothing);
    });

    testWidgets('experience without a display level change shows gain only', (
      tester,
    ) async {
      await _pump(tester, [
        AdvancementEntry(
          characterId: 1,
          chName: '甲',
          result: _experienceOnly(),
        ),
      ]);

      expect(
        find.text(UiStrings.cultivationExperienceGained('甲', 50)),
        findsOneWidget,
      );
      expect(find.textContaining('→ Lv'), findsNothing);
    });

    testWidgets('realm breakthrough keeps ceremony and includes level change', (
      tester,
    ) async {
      await _pump(tester, [
        AdvancementEntry(characterId: 1, chName: '甲', result: _realmAndLevel()),
      ]);

      expect(find.textContaining('甲 · 突破至'), findsOneWidget);
      expect(find.textContaining('Lv10 → Lv11'), findsOneWidget);
    });

    testWidgets('1 character layers=1 → 显「突破至」', (tester) async {
      await _pump(tester, [
        AdvancementEntry(
          characterId: 1,
          chName: '甲',
          result: _advanced(layersGained: 1),
        ),
      ]);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.textContaining('甲 · 突破至'), findsOneWidget);
      expect(find.textContaining('连破'), findsNothing);
    });

    testWidgets('1 character layers=4 → 显「连破 4 层 →」', (tester) async {
      await _pump(tester, [
        AdvancementEntry(
          characterId: 1,
          chName: '乙',
          result: _advanced(layersGained: 4),
        ),
      ]);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.textContaining('乙 · 连破 4 层'), findsOneWidget);
    });

    // H2 C2:大境界突破(crossedTier)走醒目标记,区别于小层升级。
    testWidgets('crossedTier=true → 大境界突破标记(military_tech + badge)', (
      tester,
    ) async {
      await _pump(tester, [
        AdvancementEntry(
          characterId: 1,
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
      expect(
        find.byIcon(Icons.auto_awesome),
        findsNothing,
        reason: '大境界突破不用普通小层升级图标',
      );
    });

    testWidgets('crossedTier + 同 tier 升层 mixed → 各走各样式', (tester) async {
      await _pump(tester, [
        AdvancementEntry(
          characterId: 1,
          chName: '甲',
          result: _advanced(
            layersGained: 1,
            tierAfter: RealmTier.sanLiu,
            layerAfter: RealmLayer.qiMeng,
          ),
        ),
        AdvancementEntry(
          characterId: 1,
          chName: '乙',
          result: _advanced(layersGained: 2),
        ),
      ]);
      expect(
        find.byIcon(Icons.military_tech),
        findsOneWidget,
        reason: '甲 跨 tier',
      );
      expect(
        find.byIcon(Icons.auto_awesome),
        findsOneWidget,
        reason: '乙 同 tier 小层升级',
      );
      expect(find.textContaining('大境界突破'), findsOneWidget);
    });

    testWidgets('多 character mixed → 仅显 didAdvance=true', (tester) async {
      await _pump(tester, [
        AdvancementEntry(
          characterId: 1,
          chName: '甲',
          result: _advanced(layersGained: 1),
        ),
        AdvancementEntry(characterId: 1, chName: '乙', result: _flat()),
        AdvancementEntry(
          characterId: 1,
          chName: '丙',
          result: _advanced(layersGained: 2),
        ),
      ]);
      expect(find.byIcon(Icons.auto_awesome), findsNWidgets(2));
      expect(find.textContaining('甲 · 突破至'), findsOneWidget);
      expect(find.textContaining('乙'), findsNothing);
      expect(find.textContaining('丙 · 连破 2 层'), findsOneWidget);
    });
  });
}
