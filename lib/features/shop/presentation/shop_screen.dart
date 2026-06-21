import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/inventory_providers.dart';
import '../../../data/defs/shop_item_def.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/asset_fallback.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/shop_providers.dart';
import '../application/shop_service.dart';

/// 江湖商店主屏（材料经济 P1 Task 8，GDD §5.1）。
///
/// 布局：
/// - 顶部货币栏：银两余额（[silverBalanceProvider]）。
/// - 货架：[shopItemListProvider] 按 category 分组，[PaperPanel] 包裹。
/// - 每件商品卡：名（[EnumL10n.itemType]）+ 标价 + 「购买」木牌按钮。
/// - 点购买 → [PaperDialog] 确认弹窗 → [ShopService.purchase] → 刷新 provider。
/// - 银两不足：按钮禁用（[PlaqueButton.disabled=true]），图标无变化不弹窗。
///
/// **balance T3 动态标价**：经验丹标价 = `founderEtl × priceLayerFraction`，
/// 通过 [founderEtlProvider] 获取，显示价与扣费价保持一致。
///
/// 约束（§5.1）：固定货架，无随机/限购/每日/抽卡元素。
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final silverAsync = ref.watch(silverBalanceProvider);
    final items = ref.watch(shopItemListProvider);
    final founderEtlAsync = ref.watch(founderEtlProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.shopTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: silverAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              'load error: $e',
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (silver) {
            // founderEtl 加载中时先用 null（动态价商品禁用，固定价正常）
            final founderEtl = founderEtlAsync.asData?.value;
            return _buildBody(context, silver, items, founderEtl);
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    int silver,
    List<ShopItemDef> items,
    int? founderEtl,
  ) {
    // 按 category 分组
    final byCategory = <String, List<ShopItemDef>>{};
    for (final def in items) {
      byCategory.putIfAbsent(def.category, () => []).add(def);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ── 货币顶栏 ───────────────────────────────────────────────────────
        _SilverBalanceBar(silver: silver),
        const SizedBox(height: 16),
        // ── 分类货架面板 ───────────────────────────────────────────────────
        for (final entry in byCategory.entries) ...[
          _CategoryPanel(
            category: entry.key,
            defs: entry.value,
            silver: silver,
            founderEtl: founderEtl,
            onBuy: (def) => _handleBuy(context, def, silver, founderEtl),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  /// 点购买：弹确认 → 余额充足则 purchase → 刷新；不足则不弹（按钮已禁用）。
  Future<void> _handleBuy(
    BuildContext context,
    ShopItemDef def,
    int silver,
    int? founderEtl,
  ) async {
    final price = ShopService.effectivePrice(def, founderEtl ?? 0);

    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.shopBuy,
      body: Text(
        '${EnumL10n.itemType(def.itemType)}  ×1\n'
        '${UiStrings.shopItemPrice(price)}',
        style: const TextStyle(
          color: WuxiaUi.ink,
          fontSize: 14,
          height: 1.8,
          letterSpacing: 1,
        ),
      ),
      actions: [
        PlaqueButton(
          label: UiStrings.commonCancel,
          onTap: () => Navigator.of(context).pop(false),
        ),
        PlaqueButton(
          label: UiStrings.shopBuy,
          primary: true,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final result = await ShopService.purchase(
      IsarSetup.instance,
      def: def,
      founderEtl: founderEtl,
    );

    if (!context.mounted) return;

    if (result.success) {
      ref.invalidate(silverBalanceProvider);
      ref.invalidate(allInventoryItemsProvider);
    } else {
      final msg = result.reason == PurchaseFailReason.pricingUnavailable
          ? UiStrings.shopPricingUnavailable
          : UiStrings.shopInsufficientSilver;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }
}

// ── 货币顶栏 ──────────────────────────────────────────────────────────────────

class _SilverBalanceBar extends StatelessWidget {
  const _SilverBalanceBar({required this.silver});

  final int silver;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.monetization_on_outlined, color: WuxiaUi.ink, size: 20),
          const SizedBox(width: 8),
          Text(
            UiStrings.silverBalanceLabel(silver),
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 分类货架面板 ──────────────────────────────────────────────────────────────

class _CategoryPanel extends StatelessWidget {
  const _CategoryPanel({
    required this.category,
    required this.defs,
    required this.silver,
    required this.founderEtl,
    required this.onBuy,
  });

  final String category;
  final List<ShopItemDef> defs;
  final int silver;
  /// 祖师单层所需经验（动态标价用）。null = founder 未加载或不存在。
  final int? founderEtl;
  final void Function(ShopItemDef def) onBuy;

  String _categoryLabel(String cat) {
    return switch (cat) {
      'material' => UiStrings.shopCategoryMaterial,
      _ => cat,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 分类标题
          Text(
            _categoryLabel(category),
            style: const TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          // 商品列表（Column，每 tile 包 IntrinsicHeight 守滚动体例）
          for (final def in defs)
            Builder(
              builder: (context) {
                // I-1 + M-1：ep=null 表示动态价商品且 founder 未就绪（无法定价）。
                // 避免重复调用 effectivePrice，并防止显示「0 两」误导。
                final ep = (def.isDynamicPrice && founderEtl == null)
                    ? null
                    : ShopService.effectivePrice(def, founderEtl ?? 0);
                return IntrinsicHeight(
                  child: _ShopItemTile(
                    def: def,
                    effectivePrice: ep,
                    canAfford: ep != null && silver >= ep,
                    onBuy: () => onBuy(def),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── 商品卡 ────────────────────────────────────────────────────────────────────

class _ShopItemTile extends StatelessWidget {
  const _ShopItemTile({
    required this.def,
    required this.effectivePrice,
    required this.canAfford,
    required this.onBuy,
  });

  final ShopItemDef def;
  /// 有效标价（已由调用方计算，显示与扣费保持一致）。
  /// null = 动态价商品且 founder 未就绪，显示占位「当前无法定价」。
  final int? effectivePrice;
  final bool canAfford;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final name = EnumL10n.itemType(def.itemType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 商品图标（材料多无专图，走 fallback glyph）
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/images/items/${def.itemDefId}.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: wuxiaAssetErrorBuilder(
                () => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: WuxiaColors.panel,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: WuxiaUi.ink.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.white38,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 名称 + 标价
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  effectivePrice == null
                      ? UiStrings.shopPricingUnavailable
                      : UiStrings.shopItemPrice(effectivePrice!),
                  style: TextStyle(
                    color: canAfford
                        ? WuxiaColors.resultHighlight
                        : WuxiaColors.hpLow,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // 购买按钮（余额不足→disabled）
          PlaqueButton(
            label: UiStrings.shopBuy,
            primary: true,
            disabled: !canAfford,
            onTap: canAfford ? onBuy : null,
          ),
        ],
      ),
    );
  }
}
