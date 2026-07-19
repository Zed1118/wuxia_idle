import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/inventory/presentation/post_battle_healing_panel.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

/// `PostBattleHealingPanel` 行为测（2026-07-19 夜批 coverage 补强，
/// 基线 12/70 行）。
///
/// 真 Isar + 真 GameRepository + widget 层真交互。**全部 build/tap/Isar
/// 交互收进单个 `tester.runAsync`**：fake-async 区里真 Isar future 永不
/// 完成（体例沿 apply_victory_resolution_test 头注 + sect_recruit_handler
/// runAsync 内 pump），钉：
///   - 有伤有药 → 显标题/数量/伤势行
///   - 有药无伤 / 有伤无药 → 隐藏(SizedBox.shrink)
///   - 点「服用疗伤丹」→ ItemUseService 真消费:伤势 -4h、库存 -1、结果行
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_post_battle_healing_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<void> seedInjuredFounder({double injuryHours = 6}) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.characters.put(
        Character.create(
          name: '伤者',
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes(),
          rarity: RarityTier.biaoZhun,
          lineageRole: LineageRole.founder,
          createdAt: DateTime(2026, 7, 19),
          isFounder: true,
          isActive: true,
          injuryHoursRemaining: injuryHours,
        ),
      );
    });
  }

  Future<void> seedPill(int qty) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = 'item_liaoshangdan'
          ..itemType = ItemType.miscMaterial
          ..quantity = qty
          ..firstObtainedAt = DateTime(2026, 7, 19)
          ..lastObtainedAt = DateTime(2026, 7, 19),
      );
    });
  }

  const host = ProviderScope(
    child: MaterialApp(home: Scaffold(body: PostBattleHealingPanel())),
  );

  /// 泵 host 并给真 Isar `_load` 留真时钟窗口,随后泵出结果帧。
  Future<void> pumpAndSettleReal(WidgetTester tester, {int rounds = 4}) async {
    for (var i = 0; i < rounds; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump();
    }
  }

  testWidgets('有伤有药 → 显标题/数量/伤势行', (tester) async {
    await tester.runAsync(() async {
      await seedInjuredFounder();
      await seedPill(2);
      await tester.pumpWidget(host);
      await pumpAndSettleReal(tester);

      expect(find.text('战后疗伤'), findsOneWidget);
      expect(find.text('疗伤丹 ×2'), findsOneWidget);
      expect(find.text('服用疗伤丹'), findsOneWidget);
      expect(find.textContaining('伤者'), findsWidgets, reason: '伤势行列出受伤角色');
    });
  });

  testWidgets('有药无伤 → 隐藏', (tester) async {
    await tester.runAsync(() async {
      await seedInjuredFounder(injuryHours: 0);
      await seedPill(2);
      await tester.pumpWidget(host);
      await pumpAndSettleReal(tester);

      expect(find.text('战后疗伤'), findsNothing);
    });
  });

  testWidgets('有伤无药 → 隐藏', (tester) async {
    await tester.runAsync(() async {
      await seedInjuredFounder();
      await tester.pumpWidget(host);
      await pumpAndSettleReal(tester);

      expect(find.text('战后疗伤'), findsNothing);
    });
  });

  testWidgets('点服用疗伤丹 → 伤势 -4h + 库存 -1 + 结果行', (tester) async {
    await tester.runAsync(() async {
      await seedInjuredFounder();
      await seedPill(2);
      await tester.pumpWidget(host);
      await pumpAndSettleReal(tester);

      await tester.tap(find.text('服用疗伤丹'));
      await pumpAndSettleReal(tester);

      expect(find.text('伤者伤势稍平。'), findsOneWidget);
      final item = await IsarSetup.instance.inventoryItems.getByDefId(
        'item_liaoshangdan',
      );
      expect(item!.quantity, 1, reason: '真消费 1 颗');
      final chars = await IsarSetup.instance.characters
          .filter()
          .isFounderEqualTo(true)
          .findAll();
      expect(
        chars.single.injuryHoursRemaining,
        2.0,
        reason: '疗伤丹 injury_heal_hours=4:6h → 2h',
      );
    });
  });
}
