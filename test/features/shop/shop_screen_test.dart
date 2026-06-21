import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/shop_item_def.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/shop/application/shop_providers.dart';
import 'package:wuxia_idle/features/shop/presentation/shop_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 材料经济 P1 Task 8：ShopScreen widget 测试。
///
/// 覆盖：
/// 1. 货币顶栏显示银两余额。
/// 2. 货品卡显示名称 + 标价。
/// 3. 点购买按钮弹出确认对话框（PaperDialog）。
/// 4. 银两不足时购买按钮禁用（视觉半透，onTap=null）。
///
/// 注：ShopService.purchase 走真 Isar，widget 测不覆盖（见 shop_service_test.dart）。
/// 本测 override provider 跳过 Isar，只测 UI 渲染与弹窗逻辑。
void main() {
  // 两件测试商品（仿 shop.yaml）
  const defMojianshi = ShopItemDef(
    id: 'shop_mojianshi',
    itemDefId: 'item_mojianshi',
    itemType: ItemType.moJianShi,
    price: 30,
    category: 'material',
  );

  const defXinxue = ShopItemDef(
    id: 'shop_xinxue_jiejing',
    itemDefId: 'item_xinxuejiejing',
    itemType: ItemType.xinXueJieJing,
    price: 120,
    category: 'material',
  );

  /// 封装 pump，注入 silverBalance + shopItemList + founderEtl override。
  ///
  /// [founderEtl] 默认 null（模拟无 founder / 未加载状态）；
  /// 传具体值模拟有 founder 时的动态定价。
  Future<void> pumpShop(
    WidgetTester tester, {
    required int silver,
    List<ShopItemDef>? items,
    int? founderEtl,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          silverBalanceProvider.overrideWith((_) async => silver),
          shopItemListProvider.overrideWith((_) => items ?? [defMojianshi, defXinxue]),
          founderEtlProvider.overrideWith((_) async => founderEtl),
        ],
        child: const MaterialApp(home: ShopScreen()),
      ),
    );
    // 多轮 pump 等 AsyncValue 解析
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 1. 货币顶栏
  // ────────────────────────────────────────────────────────────────────────────
  testWidgets('货币顶栏显示银两余额', (tester) async {
    await pumpShop(tester, silver: 50);

    expect(find.text(UiStrings.silverBalanceLabel(50)), findsOneWidget);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 2. 货品卡：名称 + 标价
  // ────────────────────────────────────────────────────────────────────────────
  testWidgets('货品卡显示磨剑石名称与标价', (tester) async {
    await pumpShop(tester, silver: 100);

    final mojianshiName = EnumL10n.itemType(ItemType.moJianShi);
    expect(find.text(mojianshiName), findsOneWidget);
    expect(find.text(UiStrings.shopItemPrice(30)), findsOneWidget);
  });

  testWidgets('货品卡显示心血结晶名称与标价', (tester) async {
    await pumpShop(tester, silver: 100);

    final xinxueName = EnumL10n.itemType(ItemType.xinXueJieJing);
    expect(find.text(xinxueName), findsOneWidget);
    expect(find.text(UiStrings.shopItemPrice(120)), findsOneWidget);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 3. 点购买按钮弹确认对话框
  // ────────────────────────────────────────────────────────────────────────────
  testWidgets('点购买按钮弹出确认对话框', (tester) async {
    await pumpShop(tester, silver: 200, items: [defMojianshi]);

    // 找到购买按钮并点击（银两充足，enabled）
    final buyButtons = find.text(UiStrings.shopBuy);
    expect(buyButtons, findsWidgets);

    await tester.tap(buyButtons.first);
    await tester.pumpAndSettle();

    // PaperDialog 出现：确认弹窗包含商品名
    final mojianshiName = EnumL10n.itemType(ItemType.moJianShi);
    expect(find.text(mojianshiName), findsWidgets);
    // 弹窗有取消/确认动作
    expect(find.text(UiStrings.shopBuy), findsWidgets);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 4. 银两不足时购买按钮禁用
  // ────────────────────────────────────────────────────────────────────────────
  testWidgets('银两不足时购买按钮禁用（不弹确认）', (tester) async {
    // silver=0，磨剑石 price=30 → 不足
    await pumpShop(tester, silver: 0, items: [defMojianshi]);

    // 购买按钮存在（半透 UI，但 onTap=null）
    final buyButtons = find.text(UiStrings.shopBuy);
    expect(buyButtons, findsWidgets);

    // 尝试点击，不应弹出对话框
    await tester.tap(buyButtons.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // 没有 Dialog 出现
    expect(find.byType(Dialog), findsNothing);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 5. I-1：动态价商品 + 无 founder → 显示占位，不显「0 两」，按钮禁用
  // ────────────────────────────────────────────────────────────────────────────
  testWidgets('动态价商品无founder时显示占位文案而非0两且按钮禁用', (tester) async {
    const defExpPill = ShopItemDef(
      id: 'shop_jingyandan',
      itemDefId: 'item_jingyandan_sm',
      itemType: ItemType.jingYanDan,
      priceLayerFraction: 0.5, // isDynamicPrice = true
      category: 'material',
    );

    // founderEtl=null（默认），有足够银两也不影响结论
    await pumpShop(tester, silver: 9999, items: [defExpPill]);

    // 不应出现「0 两」
    expect(find.text(UiStrings.shopItemPrice(0)), findsNothing);

    // 应出现占位文案
    expect(find.text(UiStrings.shopPricingUnavailable), findsOneWidget);

    // 购买按钮禁用（onTap=null），点击不弹对话框
    final buyButtons = find.text(UiStrings.shopBuy);
    await tester.tap(buyButtons.first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('动态价商品有founder时显示计算价格而非占位', (tester) async {
    const defExpPill = ShopItemDef(
      id: 'shop_jingyandan',
      itemDefId: 'item_jingyandan_sm',
      itemType: ItemType.jingYanDan,
      priceLayerFraction: 0.5, // effectivePrice = (1000 * 0.5).round() = 500
      category: 'material',
    );

    // founderEtl=1000 → 动态价 500 两
    await pumpShop(tester, silver: 9999, items: [defExpPill], founderEtl: 1000);

    // 不应出现占位文案
    expect(find.text(UiStrings.shopPricingUnavailable), findsNothing);

    // 应显示正确计算价格
    expect(find.text(UiStrings.shopItemPrice(500)), findsOneWidget);
  });
}
