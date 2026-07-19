import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/resource_overview/application/resource_overview_providers.dart';
import 'package:wuxia_idle/features/resource_overview/domain/resource_overview_item.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `resourceOverviewProvider` 行为测（2026-07-19 夜批 coverage 补强，
/// 基线 2/4 行）。
///
/// 真 Isar 库存 + 真 GameRepository + 真上游 `allInventoryItemsProvider`，
/// 钉「背包物料 → 分类视图」派生：银两入 currency 段且数量随行刷新。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_resource_overview_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('银两入 currency 段;invalidate 后数量随库存刷新', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    Future<int> silverQuantity() async {
      final sections = await container.read(resourceOverviewProvider.future);
      final currency = sections.firstWhere(
        (s) => s.category == ResourceOverviewCategory.currency,
        orElse: () => throw StateError('无 currency 段: $sections'),
      );
      final silver = currency.items.firstWhere((i) => i.defId == 'item_silver');
      return silver.quantity;
    }

    expect(await silverQuantity(), 0, reason: '初始无银两行 → 0');

    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = 'item_silver'
          ..itemType = ItemType.silver
          ..quantity = 233
          ..firstObtainedAt = DateTime(2026, 7, 19)
          ..lastObtainedAt = DateTime(2026, 7, 19),
      );
    });
    container.invalidate(resourceOverviewProvider);

    expect(await silverQuantity(), 233, reason: '库存写入后视图随行刷新');
  });
}
