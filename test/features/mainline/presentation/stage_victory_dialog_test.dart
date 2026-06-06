import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/presentation/advancement_summary.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_factory.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_victory_dialog.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

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

DropResult _emptyDrops() => const DropResult(equipments: [], items: []);

DropResult _itemDrops() => const DropResult(
  equipments: [],
  items: [ItemDropResult(defId: 'item_mojianshi', quantity: 2)],
);

/// H1 批3:真装备掉落(需 GameRepository 已加载,defId→名+品阶)。
DropResult _equipDrops(List<String> defIds) => DropResult(
  equipments: [
    for (final id in defIds)
      EquipmentFactory.fromDef(
        GameRepository.instance.getEquipment(id),
        rng: DefaultRng(seed: 1),
        obtainedAt: DateTime(2026, 5, 30),
        obtainedFrom: '掉落',
      ),
  ],
  items: const [],
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
  List<AdvancementEntry> advancements, {
  List<ResonanceUpgradeNotice> resonanceUpgrades = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StageVictoryContent(
          drops: drops,
          advancements: advancements,
          resonanceUpgrades: resonanceUpgrades,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  group('StageVictoryContent', () {
    testWidgets('empty drops + 无升层 → 显「本战无固定掉落」 + 不显 banner', (tester) async {
      await _pumpContent(tester, _emptyDrops(), const []);
      expect(find.text(UiStrings.stageVictoryDropLabel), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryNoDrop), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('firstClearTitle 非空 → 顶部显示首胜封签', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageVictoryContent(
              firstClearTitle: UiStrings.stageVictoryBossFirstClear('风雨渡口'),
              drops: _emptyDrops(),
              advancements: const [],
            ),
          ),
        ),
      );
      expect(find.text(UiStrings.firstClearCeremonySubtitle), findsOneWidget);
      expect(find.text('首胜 · 风雨渡口'), findsOneWidget);
      expect(find.byIcon(Icons.military_tech), findsOneWidget);
    });

    testWidgets('item drop + 无升层 → 显 drop 条目', (tester) async {
      await _pumpContent(tester, _itemDrops(), const []);
      expect(find.text(UiStrings.stageVictoryDropLabel), findsOneWidget);
      expect(find.textContaining('磨剑石 ×2'), findsOneWidget);
      expect(find.textContaining('item_mojianshi'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('empty drops + 1 角色升层 → noDrop + banner 1 行', (tester) async {
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

    // P1.1 候选 3-a:共鸣度晋阶 banner
    testWidgets('empty drops + 1 共鸣晋阶 → 显「共鸣晋阶」label + 1 行 notice', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        _emptyDrops(),
        const [],
        resonanceUpgrades: const [
          ResonanceUpgradeNotice(
            equipmentName: '青锋剑',
            newStage: ResonanceStage.moQi,
          ),
        ],
      );
      expect(find.text(UiStrings.stageVictoryResonanceLabel), findsOneWidget);
      expect(find.textContaining('「青锋剑」共鸣度晋至 默契'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('多件共鸣晋阶 → 显多行 + 升层 + drop 三段共存', (tester) async {
      await _pumpContent(
        tester,
        _itemDrops(),
        [AdvancementEntry(chName: '甲', result: _advanced())],
        resonanceUpgrades: const [
          ResonanceUpgradeNotice(
            equipmentName: '青锋剑',
            newStage: ResonanceStage.moQi,
          ),
          ResonanceUpgradeNotice(
            equipmentName: '玄铁刀',
            newStage: ResonanceStage.xinJianTongLing,
          ),
        ],
      );
      expect(find.textContaining('磨剑石 ×2'), findsOneWidget);
      expect(find.textContaining('甲 · 突破至'), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryResonanceLabel), findsOneWidget);
      expect(find.textContaining('青锋剑'), findsOneWidget);
      expect(find.textContaining('玄铁刀'), findsOneWidget);
      expect(find.textContaining('默契'), findsOneWidget);
      expect(find.textContaining('心剑通灵'), findsOneWidget);
      // 升层 1 icon + 共鸣晋阶 2 icon = 3 icon
      expect(find.byIcon(Icons.auto_awesome), findsNWidgets(3));
    });

    testWidgets('empty 三段全空 → 只显「本战无固定掉落」', (tester) async {
      await _pumpContent(tester, _emptyDrops(), const []);
      expect(find.text(UiStrings.stageVictoryNoDrop), findsOneWidget);
      expect(find.text(UiStrings.stageVictoryResonanceLabel), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    // H1 批3:装备掉落仪式感 —— 显中文名 + 品阶标签 + 勋章图标,非 raw defId。
    testWidgets('装备掉落 → 显中文名+品阶标签+勋章图标,不显 raw defId', (tester) async {
      await _pumpContent(
        tester,
        _equipDrops([
          'weapon_shenwu_tian_wen_jian', // 神物 · 天问剑
          'weapon_xunchang_tie_jian', // 寻常货 · 铁剑
        ]),
        const [],
      );
      // 中文名渲染(此前若显 raw defId 即真 bug 类)。
      expect(find.text('天问剑'), findsOneWidget);
      expect(find.text('铁剑'), findsOneWidget);
      expect(find.textContaining('weapon_shenwu'), findsNothing);
      // 品阶标签(神物高亮 / 寻常货暗灰,色差由 tierColorForEquipment 给)。
      expect(find.text('神物'), findsOneWidget);
      expect(find.text('寻常货'), findsOneWidget);
      // 每件装备一枚品阶勋章图标。
      expect(find.byIcon(Icons.workspace_premium), findsNWidgets(2));
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
