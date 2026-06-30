import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/item_usage.dart';
import '../../../data/defs/shop_item_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/asset_fallback.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/error_fallback.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/shop_need_hint_service.dart';
import '../application/shop_providers.dart';
import '../application/shop_service.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

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
  _ShopShelfFilter _filter = _ShopShelfFilter.all;

  @override
  Widget build(BuildContext context) {
    final silverAsync = ref.watch(silverBalanceProvider);
    final items = ref.watch(shopItemListProvider);
    final founderEtlAsync = ref.watch(founderEtlProvider);
    final inventoryAsync = ref.watch(allInventoryItemsProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.shopTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: silverAsync.when(
          loading: () => const Center(child: InkLoadingIndicator()),
          error: (e, _) => ErrorFallback(
            error: e,
            onRetry: () => ref.invalidate(silverBalanceProvider),
          ),
          data: (silver) {
            // founderEtl 加载中时先用 null（动态价商品禁用，固定价正常）
            final founderEtl = founderEtlAsync.asData?.value;
            return _buildBody(
              context,
              silver,
              items,
              founderEtl,
              _readActiveCharacters(),
              {
                for (final item in inventoryAsync.asData?.value ?? const [])
                  item.defId: item.quantity,
              },
            );
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
    List<Character> activeCharacters,
    Map<String, int> inventoryQuantities,
  ) {
    final repo = GameRepository.instanceOrNull;
    final hintService = repo == null ? null : ShopNeedHintService(repo);
    final allEntries = items
        .map(
          (def) => _ShopShelfEntry.fromDef(
            def,
            silver,
            founderEtl,
            hintService: hintService,
            activeCharacters: activeCharacters,
            inventoryQuantities: inventoryQuantities,
          ),
        )
        .toList();
    final visibleEntries = allEntries
        .where((entry) => _filter.includes(entry))
        .toList();

    // 按购买意图分组，只改变阅读层，不改变真实货架内容。
    final byGroup = <_ShopShelfGroupKind, List<_ShopShelfEntry>>{};
    for (final entry in visibleEntries) {
      byGroup.putIfAbsent(entry.group, () => []).add(entry);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth > 1420
            ? (constraints.maxWidth - 1360) / 2
            : 16.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            32,
          ),
          children: [
            // ── 货币顶栏 ───────────────────────────────────────────────────────
            _SilverBalanceBar(silver: silver),
            const SizedBox(height: 16),
            _ShelfFilterBar(
              selected: _filter,
              entries: allEntries,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 16),
            // ── 用途货架面板 ───────────────────────────────────────────────────
            for (final group in _ShopShelfGroupKind.values)
              if (byGroup[group]?.isNotEmpty == true) ...[
                _ShelfGroupPanel(
                  group: group,
                  entries: byGroup[group]!,
                  silver: silver,
                  onBuy: (def) => _handleBuy(context, def, silver, founderEtl),
                ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
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
        SizedBox(
          width: 104,
          child: PlaqueButton(
            label: UiStrings.commonCancel,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ),
        SizedBox(
          width: 104,
          child: PlaqueButton(
            label: UiStrings.shopBuy,
            primary: true,
            onTap: () => Navigator.of(context).pop(true),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  List<Character> _readActiveCharacters() {
    final ids = ref.watch(activeCharacterIdsProvider).asData?.value;
    if (ids == null || ids.isEmpty) return const [];

    final characters = <Character>[];
    for (final id in ids) {
      final character = ref.watch(characterByIdProvider(id)).asData?.value;
      if (character != null) characters.add(character);
    }
    return characters;
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
          const Icon(
            Icons.monetization_on_outlined,
            color: WuxiaUi.ink,
            size: 20,
          ),
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

// ── 货架筛选 ────────────────────────────────────────────────────────────────

enum _ShopShelfFilter { all, affordable, needSaving, watch }

extension _ShopShelfFilterText on _ShopShelfFilter {
  String get label => switch (this) {
    _ShopShelfFilter.all => UiStrings.shopFilterAll,
    _ShopShelfFilter.affordable => UiStrings.shopFilterAffordable,
    _ShopShelfFilter.needSaving => UiStrings.shopFilterNeedSaving,
    _ShopShelfFilter.watch => UiStrings.shopFilterWatch,
  };

  bool includes(_ShopShelfEntry entry) => switch (this) {
    _ShopShelfFilter.all => true,
    _ShopShelfFilter.affordable => entry.canAfford,
    _ShopShelfFilter.needSaving => entry.needsSaving,
    _ShopShelfFilter.watch => entry.needsAttention,
  };
}

enum _ShopShelfGroupKind {
  cultivation,
  enhancement,
  forging,
  recovery,
  islandProduction,
  technique,
  common,
}

extension _ShopShelfGroupText on _ShopShelfGroupKind {
  String get label => switch (this) {
    _ShopShelfGroupKind.cultivation => UiStrings.shopShelfGroupCultivation,
    _ShopShelfGroupKind.enhancement => UiStrings.shopShelfGroupEnhancement,
    _ShopShelfGroupKind.forging => UiStrings.shopShelfGroupForging,
    _ShopShelfGroupKind.recovery => UiStrings.shopShelfGroupRecovery,
    _ShopShelfGroupKind.islandProduction =>
      UiStrings.shopShelfGroupIslandProduction,
    _ShopShelfGroupKind.technique => UiStrings.shopShelfGroupTechnique,
    _ShopShelfGroupKind.common => UiStrings.shopShelfGroupCommon,
  };

  String get description => switch (this) {
    _ShopShelfGroupKind.cultivation => UiStrings.shopShelfGroupCultivationDesc,
    _ShopShelfGroupKind.enhancement => UiStrings.shopShelfGroupEnhancementDesc,
    _ShopShelfGroupKind.forging => UiStrings.shopShelfGroupForgingDesc,
    _ShopShelfGroupKind.recovery => UiStrings.shopShelfGroupRecoveryDesc,
    _ShopShelfGroupKind.islandProduction =>
      UiStrings.shopShelfGroupIslandProductionDesc,
    _ShopShelfGroupKind.technique => UiStrings.shopShelfGroupTechniqueDesc,
    _ShopShelfGroupKind.common => UiStrings.shopShelfGroupCommonDesc,
  };
}

class _ShopShelfEntry {
  const _ShopShelfEntry({
    required this.def,
    required this.effectivePrice,
    required this.canAfford,
    required this.displayName,
    required this.hint,
    required this.ownedQuantity,
    required this.group,
  });

  factory _ShopShelfEntry.fromDef(
    ShopItemDef def,
    int silver,
    int? founderEtl, {
    ShopNeedHintService? hintService,
    List<Character> activeCharacters = const [],
    Map<String, int> inventoryQuantities = const {},
  }) {
    final effectivePrice = (def.isDynamicPrice && founderEtl == null)
        ? null
        : ShopService.effectivePrice(def, founderEtl ?? 0);
    final hint = hintService?.hintFor(
      def: def,
      activeCharacters: activeCharacters,
    );
    return _ShopShelfEntry(
      def: def,
      effectivePrice: effectivePrice,
      canAfford: effectivePrice != null && silver >= effectivePrice,
      displayName: hint?.displayName ?? EnumL10n.itemType(def.itemType),
      hint: hint,
      ownedQuantity: inventoryQuantities[def.itemDefId] ?? 0,
      group: _resolveShelfGroup(def, hint),
    );
  }

  final ShopItemDef def;
  final int? effectivePrice;
  final bool canAfford;
  final String displayName;
  final ShopNeedHint? hint;
  final int ownedQuantity;
  final _ShopShelfGroupKind group;

  bool get needsSaving => effectivePrice != null && !canAfford;
  bool get pricingPending => effectivePrice == null;
  bool get needsAttention =>
      needsSaving || pricingPending || def.isDynamicPrice;
}

_ShopShelfGroupKind _resolveShelfGroup(ShopItemDef def, ShopNeedHint? hint) {
  final usageKinds = {
    for (final usage in hint?.usages ?? const <ItemUsage>[]) usage.kind,
  };

  if (usageKinds.contains(ItemUsageKind.realmProgress)) {
    return _ShopShelfGroupKind.cultivation;
  }
  if (usageKinds.contains(ItemUsageKind.techniqueUnlock)) {
    return _ShopShelfGroupKind.technique;
  }
  if (usageKinds.contains(ItemUsageKind.equipmentForging)) {
    return _ShopShelfGroupKind.forging;
  }
  if (usageKinds.contains(ItemUsageKind.injuryRecovery)) {
    return _ShopShelfGroupKind.recovery;
  }
  if (usageKinds.contains(ItemUsageKind.islandBuildingUpgrade) ||
      usageKinds.contains(ItemUsageKind.islandRecipeInput) ||
      usageKinds.contains(ItemUsageKind.islandUpgradeCurrency)) {
    return _ShopShelfGroupKind.islandProduction;
  }
  if (usageKinds.contains(ItemUsageKind.equipmentEnhancement) ||
      usageKinds.contains(ItemUsageKind.equipmentGuarantee)) {
    return _ShopShelfGroupKind.enhancement;
  }

  return switch (def.category) {
    'pill' => _ShopShelfGroupKind.cultivation,
    'technique_clue' ||
    'techniqueClue' ||
    'clue' => _ShopShelfGroupKind.technique,
    _ => _ShopShelfGroupKind.common,
  };
}

class _ShelfFilterBar extends StatelessWidget {
  const _ShelfFilterBar({
    required this.selected,
    required this.entries,
    required this.onSelected,
  });

  final _ShopShelfFilter selected;
  final List<_ShopShelfEntry> entries;
  final ValueChanged<_ShopShelfFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in _ShopShelfFilter.values)
            _ShelfFilterChip(
              label: UiStrings.shopFilterLabel(
                filter.label,
                entries.where(filter.includes).length,
              ),
              selected: selected == filter,
              onTap: () => onSelected(filter),
            ),
        ],
      ),
    );
  }
}

class _ShelfFilterChip extends StatelessWidget {
  const _ShelfFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? WuxiaUi.jiang.withValues(alpha: 0.18)
                : WuxiaUi.paper.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? WuxiaUi.jiang
                  : WuxiaUi.ink.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? WuxiaUi.jiang : WuxiaUi.ink2,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 用途货架面板 ──────────────────────────────────────────────────────────────

class _ShelfGroupPanel extends StatelessWidget {
  const _ShelfGroupPanel({
    required this.group,
    required this.entries,
    required this.silver,
    required this.onBuy,
  });

  final _ShopShelfGroupKind group;
  final List<_ShopShelfEntry> entries;
  final int silver;
  final void Function(ShopItemDef def) onBuy;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 分组标题
          Row(
            children: [
              Expanded(
                child: Text(
                  group.label,
                  style: const TextStyle(
                    color: WuxiaColors.resultHighlight,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Text(
                UiStrings.shopCategorySummary(
                  total: entries.length,
                  affordable: entries.where((entry) => entry.canAfford).length,
                  needSaving: entries
                      .where((entry) => entry.needsSaving)
                      .length,
                ),
                style: const TextStyle(
                  color: WuxiaUi.muted,
                  fontSize: 12.5,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            group.description,
            style: const TextStyle(
              color: WuxiaUi.muted,
              fontSize: 13,
              height: 1.4,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          // 商品列表（Column，每 tile 包 IntrinsicHeight 守滚动体例）
          for (final entry in entries)
            IntrinsicHeight(
              child: _ShopItemTile(
                entry: entry,
                silver: silver,
                onBuy: () => onBuy(entry.def),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 商品卡 ────────────────────────────────────────────────────────────────────

class _ShopItemTile extends StatelessWidget {
  const _ShopItemTile({
    required this.entry,
    required this.silver,
    required this.onBuy,
  });

  final _ShopShelfEntry entry;
  final int silver;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final def = entry.def;
    final effectivePrice = entry.effectivePrice;
    final canAfford = entry.canAfford;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 商品图标（材料多无专图，走 fallback glyph）
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: WuxiaImage(
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
          // 名称 + 用途
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.displayName,
                  style: const TextStyle(
                    // 浅宣纸底用墨色 WuxiaUi.ink；white 叠浅底几乎不可见。
                    color: WuxiaUi.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                _ShopNeedHintLines(hint: entry.hint),
                if (entry.hint?.hasAnyHint == true) const SizedBox(height: 4),
                Text(
                  UiStrings.shopItemPurpose(def.itemDefId),
                  style: const TextStyle(
                    color: WuxiaUi.muted,
                    fontSize: 13,
                    height: 1.4,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // 价格、持有数与购买按钮同列，避免宽屏时信息左下堆叠、按钮孤立在最右。
          SizedBox(
            width: 178,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  effectivePrice == null
                      ? UiStrings.shopPricingUnavailable
                      : UiStrings.shopItemPrice(effectivePrice),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: canAfford
                        ? WuxiaColors.resultHighlight
                        : WuxiaColors.hpLow,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                _ShopItemStatus(entry: entry, silver: silver),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 104,
                    height: 42,
                    child: PlaqueButton(
                      label: UiStrings.shopBuy,
                      primary: true,
                      disabled: !canAfford,
                      onTap: canAfford ? onBuy : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemStatus extends StatelessWidget {
  const _ShopItemStatus({required this.entry, required this.silver});

  final _ShopShelfEntry entry;
  final int silver;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      UiStrings.shopOwnedQuantity(entry.ownedQuantity),
      if (entry.pricingPending)
        UiStrings.shopStatusPricingPending
      else if (entry.canAfford)
        UiStrings.shopStatusAffordable
      else
        UiStrings.shopNeedSilver(entry.effectivePrice! - silver),
      if (entry.def.isDynamicPrice) UiStrings.shopStatusDynamicPrice,
      if (entry.needsAttention) UiStrings.shopWatchHint,
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [for (final label in labels) _ShopStatusPill(label: label)],
    );
  }
}

class _ShopNeedHintLines extends StatelessWidget {
  const _ShopNeedHintLines({required this.hint});

  final ShopNeedHint? hint;

  @override
  Widget build(BuildContext context) {
    final hint = this.hint;
    if (hint == null || !hint.hasAnyHint) return const SizedBox.shrink();

    final lines = <String>[
      if (hint.showCurrentUsers)
        UiStrings.shopNeedCurrentUsers(hint.currentUserNames),
      UiStrings.shopNeedUsageSummary(hint.usages),
      UiStrings.shopNeedAlternateSourceSummary(hint.alternateSources),
    ]..removeWhere((line) => line.isEmpty);

    if (lines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                // 浅宣纸底用墨色柔灰 WuxiaUi.muted；WuxiaColors.textMuted 是深色 UI 专用浅灰会糊。
                color: WuxiaUi.muted,
                fontSize: 12,
                height: 1.3,
                letterSpacing: 0.4,
              ),
            ),
          ),
      ],
    );
  }
}

class _ShopStatusPill extends StatelessWidget {
  const _ShopStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: WuxiaUi.ink2,
            fontSize: 12,
            height: 1,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
