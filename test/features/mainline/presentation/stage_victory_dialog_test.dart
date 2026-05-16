import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/presentation/advancement_summary.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_victory_dialog.dart';
import 'package:wuxia_idle/ui/strings.dart';

StageDef _stage() => const StageDef(
      id: 'stage_test_01',
      name: '测试关卡',
      stageType: StageType.mainline,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: [],
      isBossStage: false,
      dropEquipmentDefIds: [],
      dropItemDefIds: [],
      baseExpReward: 100,
      difficultyMultiplier: 1.0,
    );

DropResult _emptyDrops() =>
    const DropResult(equipments: [], items: []);

DropResult _itemDrops() => const DropResult(
      equipments: [],
      items: [ItemDropResult(defId: 'item_mojianshi', quantity: 2)],
    );

AdvancementResult _advanced() => const AdvancementResult(
      layersGained: 1,
      tierBefore: RealmTier.xueTu,
      layerBefore: RealmLayer.qiMeng,
      tierAfter: RealmTier.xueTu,
      layerAfter: RealmLayer.ruMen,
      internalForceMaxBefore: 500,
      internalForceMaxAfter: 600,
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

Future<void> _pumpContent(
  WidgetTester tester,
  DropResult drops,
  List<AdvancementEntry> advancements,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StageVictoryContent(drops: drops, advancements: advancements),
      ),
    ),
  );
}

void main() {
  group('StageVictoryContent', () {
    testWidgets('empty drops + 无升层 → 显「本战无固定掉落」 + 不显 banner',
        (tester) async {
      await _pumpContent(tester, _emptyDrops(), const []);
      expect(find.text(UiStrings.stageVictoryDropLabel), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryNoDrop), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('item drop + 无升层 → 显 drop 条目', (tester) async {
      await _pumpContent(tester, _itemDrops(), const []);
      expect(find.text(UiStrings.stageVictoryDropLabel), findsOneWidget);
      expect(find.textContaining('磨剑石 ×2'), findsOneWidget);
      expect(find.textContaining('item_mojianshi'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('empty drops + 1 角色升层 → noDrop + banner 1 行',
        (tester) async {
      await _pumpContent(tester, _emptyDrops(), [
        AdvancementEntry(chName: '甲', result: _advanced()),
      ]);
      expect(find.text(UiStrings.stageVictoryNoDrop), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.textContaining('甲 · 突破至'), findsOneWidget);
    });

    testWidgets('drops + 升层 mixed → 两段都显', (tester) async {
      await _pumpContent(tester, _itemDrops(), [
        AdvancementEntry(chName: '甲', result: _advanced()),
        AdvancementEntry(chName: '乙', result: _flat()),
      ]);
      expect(find.textContaining('磨剑石 ×2'), findsOneWidget);
      expect(find.textContaining('item_mojianshi'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.textContaining('甲 · 突破至'), findsOneWidget);
      expect(find.textContaining('乙'), findsNothing);
    });

    testWidgets('drops + 全员未升层 → drop 显,banner 不显', (tester) async {
      await _pumpContent(tester, _itemDrops(), [
        AdvancementEntry(chName: '甲', result: _flat()),
      ]);
      expect(find.textContaining('磨剑石 ×2'), findsOneWidget);
      expect(find.textContaining('item_mojianshi'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });
  });

  group('showStageVictoryDialog', () {
    testWidgets('点确认按钮关闭 dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showStageVictoryDialog(
                  context: ctx,
                  stage: _stage(),
                  drops: _emptyDrops(),
                  advancements: const [],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(UiStrings.stageVictoryConfirm), findsOneWidget);
      expect(find.textContaining(UiStrings.stageVictoryTitle), findsOneWidget);

      await tester.tap(find.text(UiStrings.stageVictoryConfirm));
      await tester.pumpAndSettle();
      expect(find.text(UiStrings.stageVictoryConfirm), findsNothing);
    });
  });
}
