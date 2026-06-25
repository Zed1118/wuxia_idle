import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_settle_service.dart';
import 'package:wuxia_idle/features/taohua_island/presentation/island_recap_card.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// IslandRecapCard widget 测试。
///
/// - 非空收获：标题 + 物品名 + count-up 最终数字均出现。
/// - 空收获：显示空态文案，不显示条目。
/// ListView 条目多时可滚动，按 feedback_listview_widget_test_viewport
/// 扩展 viewport 保证 find 能定位到元素。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Widget wrap(IslandHarvest harvest) => MaterialApp(
        home: Scaffold(
          body: IslandRecapCard(harvest: harvest),
        ),
      );



  group('非空收获', () {
    // 使用 items.yaml 中实际存在的 defId；若查不到则兜底显示 defId 本身。
    // 测试重点在「name 或 defId」文本出现 + count-up 最终数字。
    const harvest = IslandHarvest({
      'item_mojianshi': 30,
      'item_xinjie_crystal': 5,
      'item_jingyan_dan_small': 2,
    });

    testWidgets('标题出现', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(harvest));
      await tester.pumpAndSettle();

      expect(find.text(UiStrings.taohuaIslandRecapTitle), findsOneWidget);
    });

    testWidgets('各物品名（或 defId 兜底）可见', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(harvest));
      await tester.pumpAndSettle();

      final repo = GameRepository.instance;
      for (final defId in harvest.gained.keys) {
        final name = repo.itemDefs[defId]?.name ?? defId;
        expect(
          find.text(name),
          findsOneWidget,
          reason: '物品 $defId 名称「$name」应显示',
        );
      }
    });

    testWidgets('count-up 动画结束后数量文本正确', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(harvest));
      // pumpAndSettle 等 TweenAnimationBuilder 动画完成
      await tester.pumpAndSettle();

      // 动画终值应能找到 ×qty 文本
      expect(find.text('×30'), findsOneWidget);
      expect(find.text('×5'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
    });

    testWidgets('不显示空态文案', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(harvest));
      await tester.pumpAndSettle();

      expect(find.text(UiStrings.taohuaIslandRecapEmpty), findsNothing);
    });
  });

  group('空收获', () {
    const emptyHarvest = IslandHarvest({});

    testWidgets('标题仍出现', (tester) async {
      await tester.pumpWidget(wrap(emptyHarvest));
      await tester.pumpAndSettle();

      expect(find.text(UiStrings.taohuaIslandRecapTitle), findsOneWidget);
    });

    testWidgets('显示空态文案', (tester) async {
      await tester.pumpWidget(wrap(emptyHarvest));
      await tester.pumpAndSettle();

      expect(find.text(UiStrings.taohuaIslandRecapEmpty), findsOneWidget);
    });

    testWidgets('不显示物品图标（无 Icon inventory_2_outlined）', (tester) async {
      await tester.pumpWidget(wrap(emptyHarvest));
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.inventory_2_outlined),
        findsNothing,
      );
    });
  });
}
