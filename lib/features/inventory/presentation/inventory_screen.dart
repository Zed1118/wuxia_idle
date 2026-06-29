import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/defs/item_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/application/inventory_providers.dart';
import '../../equipment/presentation/enhance_dialog.dart';
import '../../equipment/domain/equipment_disposal.dart';
import '../../equipment/domain/equipment_slot_occupancy.dart';
import '../../inner_demon/application/inner_demon_service.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../application/inventory_organization.dart';
import '../application/item_use_service.dart';
import '../application/item_usage_lookup_service.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../core/application/character_providers.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/error_fallback.dart';
import '../../../shared/widgets/wuxia_ui/item_slot.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../../../shared/widgets/wuxia_ui/plaque_tab.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../help/domain/help_topic.dart';
import '../../shop/presentation/shop_screen.dart';
import '../../help/presentation/context_help_button.dart';
import '../../shop/application/shop_providers.dart';
import 'bulk_disposal_dialog.dart';
import 'equipment_detail_screen.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

Set<int> _watchActiveEquippedIds(WidgetRef ref) {
  final ids = ref.watch(activeCharacterIdsProvider).value ?? const <int>[];
  final characters = [
    for (final id in ids) ref.watch(characterByIdProvider(id)).value,
  ].nonNulls;
  return equippedEquipmentIdsForCharacters(characters);
}

/// 装备仓库（phase2_tasks T29 §424-425 + T32 #22a/#22b 销账 +
/// W15 #30 P3 后续 A 物料 Tab）。
///
/// 2 Tab：装备 / 物料。装备 Tab 一次性 `findAll` 整表展示，按 tier 分段
/// （神物→寻常货 7 阶，已在 [allEquipmentsProvider] 中排序）。点击 row
/// 走 [EquipmentDetailScreen] 或 [EnhanceDialog]。物料 Tab 一次性
/// `findAll` 整表展示（[allInventoryItemsProvider]），按 [ItemType] enum
/// 顺序分组（磨剑石 / 心血结晶 / 经验丹 / 心法秘籍 / 杂项材料），目前
/// Demo 仅磨剑石 + 心血结晶有生产路径。
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key, this.initialTab = 0});

  /// 初始 Tab(0=装备 / 1=物料)。默认 0,向后兼容;供视觉验收直开物料 tab。
  final int initialTab;

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  late int _selectedTab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.inventoryTitle,
        onBack: () => Navigator.of(context).maybePop(),
        trailing: const ContextHelpButton(topic: HelpTopic.equipmentTier),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PlaqueTab(
                    label: UiStrings.inventoryTabEquipment,
                    selected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  const SizedBox(width: 12),
                  PlaqueTab(
                    label: UiStrings.inventoryTabMaterial,
                    selected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? const _EquipmentTab()
                  : const _MaterialTab(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentTab extends ConsumerStatefulWidget {
  const _EquipmentTab();

  @override
  ConsumerState<_EquipmentTab> createState() => _EquipmentTabState();
}

class _EquipmentTabState extends ConsumerState<_EquipmentTab> {
  InventorySlotFilter _slotFilter = InventorySlotFilter.all;
  InventoryTierFilter _tierFilter = InventoryTierFilter.all;
  InventorySchoolFilter _schoolFilter = InventorySchoolFilter.all;
  InventoryOwnershipFilter _ownershipFilter = InventoryOwnershipFilter.all;
  InventoryEquipmentSort _sort = InventoryEquipmentSort.tierDesc;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allEquipmentsProvider);
    final ids = ref.watch(activeCharacterIdsProvider).value ?? const [];
    final playerRealm = ids.isEmpty
        ? null
        : ref.watch(characterByIdProvider(ids.first)).value?.realmTier;
    final equippedIds = _watchActiveEquippedIds(ref);
    return async.when(
      loading: () => const Center(child: InkLoadingIndicator()),
      error: (e, _) => ErrorFallback(
        error: e,
        onRetry: () => ref.invalidate(allEquipmentsProvider),
      ),
      data: (list) {
        final filtered = organizeInventoryEquipments(
          list,
          InventoryEquipmentQuery(
            slot: _slotFilter,
            tier: _tierFilter,
            school: _schoolFilter,
            ownership: _ownershipFilter,
            sort: _sort,
          ),
          realm: playerRealm,
          equippedEquipmentIds: equippedIds,
          activeFormationEquipmentIds: equippedIds,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 批量整理入口（Task 6）
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: PlaqueButton(
                  label: UiStrings.equipmentBulkEntry,
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => const BulkDisposalDialog(),
                  ),
                ),
              ),
            ),
            _OrganizationBar(
              slotFilter: _slotFilter,
              tierFilter: _tierFilter,
              schoolFilter: _schoolFilter,
              ownershipFilter: _ownershipFilter,
              sort: _sort,
              onSlotSelect: (f) => setState(() => _slotFilter = f),
              onTierSelect: (f) => setState(() => _tierFilter = f),
              onSchoolSelect: (f) => setState(() => _schoolFilter = f),
              onOwnershipSelect: (f) => setState(() => _ownershipFilter = f),
              onSortSelect: (s) => setState(() => _sort = s),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        UiStrings.inventoryEmpty,
                        style: TextStyle(color: WuxiaColors.textMuted),
                      ),
                    )
                  : _EquipmentGrid(
                      equipments: filtered,
                      playerRealm: playerRealm,
                      equippedIds: equippedIds,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _OrganizationBar extends StatelessWidget {
  const _OrganizationBar({
    required this.slotFilter,
    required this.tierFilter,
    required this.schoolFilter,
    required this.ownershipFilter,
    required this.sort,
    required this.onSlotSelect,
    required this.onTierSelect,
    required this.onSchoolSelect,
    required this.onOwnershipSelect,
    required this.onSortSelect,
  });

  final InventorySlotFilter slotFilter;
  final InventoryTierFilter tierFilter;
  final InventorySchoolFilter schoolFilter;
  final InventoryOwnershipFilter ownershipFilter;
  final InventoryEquipmentSort sort;
  final ValueChanged<InventorySlotFilter> onSlotSelect;
  final ValueChanged<InventoryTierFilter> onTierSelect;
  final ValueChanged<InventorySchoolFilter> onSchoolSelect;
  final ValueChanged<InventoryOwnershipFilter> onOwnershipSelect;
  final ValueChanged<InventoryEquipmentSort> onSortSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final f in InventorySlotFilter.values)
            _FilterChip(
              label: _slotFilterLabel(f),
              selected: f == slotFilter,
              onTap: () => onSlotSelect(f),
            ),
          for (final f in InventoryTierFilter.values)
            _FilterChip(
              label: _tierFilterLabel(f),
              selected: f == tierFilter,
              onTap: () => onTierSelect(f),
            ),
          for (final f in InventorySchoolFilter.values)
            _FilterChip(
              label: _schoolFilterLabel(f),
              selected: f == schoolFilter,
              onTap: () => onSchoolSelect(f),
            ),
          for (final f in InventoryOwnershipFilter.values)
            _FilterChip(
              label: _ownershipFilterLabel(f),
              selected: f == ownershipFilter,
              onTap: () => onOwnershipSelect(f),
            ),
          PopupMenuButton<InventoryEquipmentSort>(
            tooltip: UiStrings.inventorySortLabel(_sortLabel(sort)),
            color: WuxiaColors.panel,
            onSelected: onSortSelect,
            itemBuilder: (context) => [
              for (final s in InventoryEquipmentSort.values)
                PopupMenuItem(
                  value: s,
                  child: Text(
                    _sortLabel(s),
                    style: const TextStyle(color: WuxiaColors.textPrimary),
                  ),
                ),
            ],
            child: _FilterChip(
              label: UiStrings.inventorySortLabel(_sortLabel(sort)),
              selected: true,
              onTap: null,
            ),
          ),
        ],
      ),
    );
  }
}

String _slotFilterLabel(InventorySlotFilter filter) {
  return switch (filter) {
    InventorySlotFilter.all => UiStrings.inventoryFilterSlotAll,
    InventorySlotFilter.weapon => UiStrings.inventoryFilterSlotLabel(
      EnumL10n.equipmentSlot(EquipmentSlot.weapon),
    ),
    InventorySlotFilter.armor => UiStrings.inventoryFilterSlotLabel(
      EnumL10n.equipmentSlot(EquipmentSlot.armor),
    ),
    InventorySlotFilter.accessory => UiStrings.inventoryFilterSlotLabel(
      EnumL10n.equipmentSlot(EquipmentSlot.accessory),
    ),
  };
}

String _tierFilterLabel(InventoryTierFilter filter) {
  return switch (filter) {
    InventoryTierFilter.all => UiStrings.inventoryFilterTierAll,
    InventoryTierFilter.xunChang => UiStrings.inventoryFilterTierLabel(
      EnumL10n.equipmentTier(EquipmentTier.xunChang),
    ),
    InventoryTierFilter.xiangYang => UiStrings.inventoryFilterTierLabel(
      EnumL10n.equipmentTier(EquipmentTier.xiangYang),
    ),
    InventoryTierFilter.haoJiaHuo => UiStrings.inventoryFilterTierLabel(
      EnumL10n.equipmentTier(EquipmentTier.haoJiaHuo),
    ),
    InventoryTierFilter.liQi => UiStrings.inventoryFilterTierLabel(
      EnumL10n.equipmentTier(EquipmentTier.liQi),
    ),
    InventoryTierFilter.zhongQi => UiStrings.inventoryFilterTierLabel(
      EnumL10n.equipmentTier(EquipmentTier.zhongQi),
    ),
    InventoryTierFilter.baoWu => UiStrings.inventoryFilterTierLabel(
      EnumL10n.equipmentTier(EquipmentTier.baoWu),
    ),
    InventoryTierFilter.shenWu => UiStrings.inventoryFilterTierLabel(
      EnumL10n.equipmentTier(EquipmentTier.shenWu),
    ),
  };
}

String _schoolFilterLabel(InventorySchoolFilter filter) {
  return switch (filter) {
    InventorySchoolFilter.all => UiStrings.inventoryFilterSchoolAll,
    InventorySchoolFilter.gangMeng => UiStrings.inventoryFilterSchoolLabel(
      EnumL10n.school(TechniqueSchool.gangMeng),
    ),
    InventorySchoolFilter.lingQiao => UiStrings.inventoryFilterSchoolLabel(
      EnumL10n.school(TechniqueSchool.lingQiao),
    ),
    InventorySchoolFilter.yinRou => UiStrings.inventoryFilterSchoolLabel(
      EnumL10n.school(TechniqueSchool.yinRou),
    ),
    InventorySchoolFilter.none => UiStrings.inventoryFilterSchoolNone,
  };
}

String _ownershipFilterLabel(InventoryOwnershipFilter filter) {
  return switch (filter) {
    InventoryOwnershipFilter.all => UiStrings.inventoryFilterOwnershipAll,
    InventoryOwnershipFilter.free => UiStrings.inventoryFilterFree,
    InventoryOwnershipFilter.equipped => UiStrings.inventoryFilterEquipped,
    InventoryOwnershipFilter.heritage => UiStrings.inventoryFilterHeritage,
    InventoryOwnershipFilter.locked => UiStrings.inventoryFilterLocked,
    InventoryOwnershipFilter.protected => UiStrings.inventoryFilterProtected,
    InventoryOwnershipFilter.equippable => UiStrings.inventoryFilterEquippable,
    InventoryOwnershipFilter.forgeable => UiStrings.inventoryFilterForgeable,
    InventoryOwnershipFilter.realmLocked =>
      UiStrings.inventoryFilterRealmLocked,
  };
}

String _sortLabel(InventoryEquipmentSort sort) {
  return switch (sort) {
    InventoryEquipmentSort.tierDesc => UiStrings.inventorySortTierDesc,
    InventoryEquipmentSort.tierAsc => UiStrings.inventorySortTierAsc,
    InventoryEquipmentSort.enhanceDesc => UiStrings.inventorySortEnhanceDesc,
    InventoryEquipmentSort.obtainedDesc => UiStrings.inventorySortObtainedDesc,
    InventoryEquipmentSort.obtainedAsc => UiStrings.inventorySortObtainedAsc,
  };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? WuxiaColors.textPrimary.withValues(alpha: 0.15)
              : WuxiaColors.panel,
          border: Border.all(
            color: selected ? WuxiaColors.textPrimary : WuxiaColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? WuxiaColors.textPrimary : WuxiaColors.textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _MaterialTab extends ConsumerWidget {
  const _MaterialTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allInventoryItemsProvider);
    final silverAsync = ref.watch(silverBalanceProvider);
    final silverBalance = silverAsync.maybeWhen(
      data: (n) => n,
      orElse: () => 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 货币位：银两余额顶栏
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: WuxiaColors.panel,
            border: Border.all(color: WuxiaColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.monetization_on_outlined,
                size: 18,
                color: WuxiaColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                UiStrings.silverBalanceLabel(silverBalance),
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              PlaqueButton(
                label: UiStrings.inventoryShopEntry,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: InkLoadingIndicator()),
            error: (e, _) => ErrorFallback(
              error: e,
              onRetry: () => ref.invalidate(allInventoryItemsProvider),
            ),
            data: (list) {
              // 排除 ItemType.silver：银两以货币位展示，不进材料分组
              final nonEmpty = list
                  .where(
                    (it) => it.quantity > 0 && it.itemType != ItemType.silver,
                  )
                  .toList();
              if (nonEmpty.isEmpty) {
                return const Center(
                  child: Text(
                    UiStrings.inventoryMaterialEmpty,
                    style: TextStyle(color: WuxiaColors.textMuted),
                  ),
                );
              }
              return _MaterialList(items: nonEmpty);
            },
          ),
        ),
      ],
    );
  }
}

class _EquipmentGrid extends ConsumerWidget {
  const _EquipmentGrid({
    required this.equipments,
    required this.playerRealm,
    required this.equippedIds,
  });

  final List<Equipment> equipments;
  final RealmTier? playerRealm;
  final Set<int> equippedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bySlot = <EquipmentSlot, List<Equipment>>{};
    for (final eq in equipments) {
      bySlot.putIfAbsent(eq.slot, () => []).add(eq);
    }
    const order = [
      EquipmentSlot.weapon,
      EquipmentSlot.armor,
      EquipmentSlot.accessory,
    ];
    final sections = order
        .where((s) => bySlot[s]?.isNotEmpty ?? false)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1180 ? 3 : 1;
            if (columns == 1) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final slot in sections) ...[
                    _SlotGroupSection(
                      slot: slot,
                      items: bySlot[slot]!,
                      playerRealm: playerRealm,
                      equippedIds: equippedIds,
                    ),
                    if (slot != sections.last) const SizedBox(height: 14),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final slot in sections) ...[
                  Expanded(
                    child: _SlotGroupSection(
                      slot: slot,
                      items: bySlot[slot]!,
                      playerRealm: playerRealm,
                      equippedIds: equippedIds,
                    ),
                  ),
                  if (slot != sections.last) const SizedBox(width: 14),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// 按部位分段(武器/护甲/饰品):段标题 + 装备格子 Wrap。
class _SlotGroupSection extends StatelessWidget {
  const _SlotGroupSection({
    required this.slot,
    required this.items,
    required this.playerRealm,
    required this.equippedIds,
  });

  final EquipmentSlot slot;
  final List<Equipment> items;
  final RealmTier? playerRealm;
  final Set<int> equippedIds;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(EnumL10n.equipmentSlot(slot)),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final eq in items)
                _EquipmentGridTile(
                  equipment: eq,
                  playerRealm: playerRealm,
                  equippedIds: equippedIds,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 单个装备格子:tier 色边框方块 + 图标 contain(缺图 EquipGlyph)+ 名 +
/// 强化徽章(右上)+ 师承标记(左上)+ 境界锁(灰化 + 锁图标)。点击进详情/强化。
class _EquipmentGridTile extends ConsumerWidget {
  const _EquipmentGridTile({
    required this.equipment,
    required this.playerRealm,
    required this.equippedIds,
  });

  final Equipment equipment;
  final RealmTier? playerRealm;
  final Set<int> equippedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = equipment;
    final color = tierColorForEquipment(eq.tier);
    final def = GameRepository.instance.equipmentDefs[eq.defId];
    final locked = playerRealm != null && !eq.isEquippableAtRealm(playerRealm!);
    final equipped = isEquipmentEquippedBySlot(eq, equippedIds);
    final protected = isEquipmentProtected(
      eq,
      equippedEquipmentIds: equippedIds,
      activeFormationEquipmentIds: equippedIds,
    );
    // T11:封条显具体境界原因(§5.3 装备阶↔境界 1:1,需同序境界),非泛化「未达境界」。
    final requiredRealmName = EnumL10n.realmTier(
      RealmTier.values[eq.tier.index],
    );

    return ItemSlot(
      imagePath: def?.iconPath,
      name: def?.name ?? eq.defId,
      tierColor: color,
      equipmentSlot: eq.slot,
      enhanceLevel: eq.enhanceLevel,
      locked: locked,
      lockText: UiStrings.inventoryRealmLockBanner(requiredRealmName),
      highTier:
          eq.tier == EquipmentTier.baoWu || eq.tier == EquipmentTier.shenWu,
      tierLabel: EnumL10n.equipmentTier(eq.tier),
      leadingBadgeIcon: eq.isLineageHeritage ? Icons.auto_awesome : null,
      leadingBadgeColor: WuxiaColors.bossFrame,
      leadingBadgeTooltip: UiStrings.inventoryLineageSealLabel,
      trailingBadgeIcon: eq.isLocked ? Icons.lock_outline : null,
      trailingBadgeColor: WuxiaColors.bossFrame,
      trailingBadgeTooltip: UiStrings.inventoryLockedSealLabel,
      protected: protected,
      protectedText: UiStrings.inventoryProtectedSealText,
      protectedTooltip: UiStrings.inventoryProtectedSealLabel,
      statusText: equipped ? UiStrings.equippedBadge : null,
      selected: equipped,
      onTap: () async {
        await _openEquipment(context, ref, def, eq);
      },
    );
  }

  Future<void> _openEquipment(
    BuildContext context,
    WidgetRef ref,
    EquipmentDef? def,
    Equipment eq,
  ) async {
    if (def != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => EquipmentDetailScreen(equipment: eq, def: def),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => EnhanceDialog(equipment: eq, def: def),
      );
    }
    ref.invalidate(allEquipmentsProvider);
    ref.invalidate(allInventoryItemsProvider);
  }
}

/// 物料列表（W15 #30 P3 后续 A · #39 round2 polish 隐藏 defId）。
///
/// 入参已按 [ItemType] enum 顺序排序（[allInventoryItemsProvider] 保证），
/// 同 itemType 内按 quantity 倒序。按 itemType 分组渲染：每组一个
/// ExpansionTile（沿装备 [_TierGroup] 体例），组标题 = 中文物料名 + 行数；
/// 行内仅显示「磨剑石 × 1234」（raw defId 已隐藏，避免暴露调试 id 给玩家）。
class _MaterialList extends StatelessWidget {
  const _MaterialList({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final groups = <ItemType, List<InventoryItem>>{};
    for (final it in items) {
      groups.putIfAbsent(it.itemType, () => []).add(it);
    }
    final types = groups.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: types.length,
      itemBuilder: (ctx, i) {
        final type = types[i];
        final rows = groups[type]!;
        return _MaterialGroup(type: type, items: rows);
      },
    );
  }
}

/// 物料分组（Task 9 格子化：替代旧 Card + ExpansionTile 列表体例）。
///
/// 组标题行（色条 + EnumL10n.itemType + 计数）+ Wrap 格子，spacing/runSpacing=12
/// 与装备 grid 保持一致。每项走 [_MaterialGridTile]。
class _MaterialGroup extends StatelessWidget {
  const _MaterialGroup({required this.type, required this.items});

  final ItemType type;
  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final name = EnumL10n.itemType(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 组标题行（保留色条 + 名 + 计数体例）
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(width: 3, height: 18, color: WuxiaColors.textPrimary),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${items.length})',
                  style: const TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 格子网格（spacing 与装备 grid 保持一致）
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items
                .map((it) => _MaterialGridTile(item: it, groupName: name))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// 物料格子（Task 9 格子化：替代旧 _MaterialRow 行布局）。
///
/// 80×80 宣纸底 + 墨框方块，内显图标（coin_icon 占位）+ 数量角标（×N 右下）。
/// 可用类（经验丹 / 秘籍 `_usable`）在方块底部附「使用」标识条，整格 tap 触发
/// 原有 `_onUse` 流程（确认弹窗 → [ItemUseService.use] → 结果浮层 →
/// invalidate），**逻辑体不动，仅换触发载体**。
/// 名称 × 数量以 [UiStrings.materialQuantity] 格式显于方块下方（保留 T9 测试兼
/// 容性）；用途说明（T12）作为小号副文字跟在名称行后。
class _MaterialGridTile extends ConsumerWidget {
  const _MaterialGridTile({required this.item, required this.groupName});

  final InventoryItem item;
  final String groupName; // itemDef 缺失时退回的组名

  static const double _size = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemDef = GameRepository.instance.itemDefs[item.defId];
    final displayName = itemDef?.name ?? groupName;
    final usages = ItemUsageLookupService(
      GameRepository.instance,
    ).usagesFor(item.defId);
    final usage = UiStrings.materialUsageSummary(usages);
    final canUse = itemDef?.isUsable ?? false;
    // 显式局部非空引用，供 onTap 闭包捕获（闭包内不做 flow promotion）。
    final usableDef = canUse ? itemDef : null;

    return SizedBox(
      width: _size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 格子方块
          InkWell(
            onTap: usableDef != null
                ? () => _onUse(context, ref, usableDef, displayName)
                : null,
            borderRadius: BorderRadius.circular(5),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: WuxiaUi.slotFill,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: WuxiaUi.ink, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 图标（通用铜钱占位；未来可走 itemDef.iconPath）
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: WuxiaImage(
                      'assets/ui/coin_icon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.expand(),
                    ),
                  ),
                  // 数量角标（右下）
                  Positioned(
                    bottom: 2,
                    right: 4,
                    child: Text(
                      '×${item.quantity}',
                      style: const TextStyle(
                        color: WuxiaUi.paper,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                      ),
                    ),
                  ),
                  // 可用标识条（底部）—— 使 find.text('使用') 可定位，整格 tap 触发
                  if (canUse)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: const Text(
                          UiStrings.itemUseButton,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: WuxiaColors.textPrimary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 名称 × 数量（UiStrings.materialQuantity 格式，test find.text 兼容）
          Text(
            UiStrings.materialQuantity(displayName, item.quantity),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: WuxiaUi.ink, fontSize: 11),
          ),
          // 用途说明（T12：materialUsage）
          if (usage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                usage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 确认 → service → 结果浮层 → invalidate（沿 shop_screen `_handleBuy` 体例）。
  /// **逻辑体原样保留**，仅触发入口从行末 TextButton 改为格子 InkWell tap。
  Future<void> _onUse(
    BuildContext context,
    WidgetRef ref,
    ItemDef itemDef,
    String displayName,
  ) async {
    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.itemUseConfirmTitle,
      body: Text(
        UiStrings.itemUseConfirmBody(displayName),
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
          label: UiStrings.itemUseButton,
          primary: true,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final isar = IsarSetup.instance;
    // 心魔余毒锁层 hook：照搬 stage_entry_flow 体例（升层时拦截）。
    final progress = await isar.mainlineProgress
        .filter()
        .saveDataIdEqualTo(IsarSetup.currentSlotId)
        .findFirst();
    final clearedSet = progress?.clearedStageIds.toSet() ?? <String>{};
    final innerDemonDef = GameRepository.instance.numbers.innerDemon;

    final result = await ItemUseService.use(
      isar,
      def: itemDef,
      realmLookup: GameRepository.instance.getRealm,
      isLayerLocked: (tier, layer) => InnerDemonService.isLayerLocked(
        nextTier: tier,
        nextLayer: layer,
        innerDemonDef: innerDemonDef,
        clearedStageIds: clearedSet,
      ),
      levelConfig: GameRepository.instance.numbers.level,
    );

    // 背包数量 + 角色经验/境界刷新。
    ref.invalidate(allInventoryItemsProvider);
    ref.invalidate(characterByIdProvider);
    ref.invalidate(activeCharacterIdsProvider);

    if (!context.mounted) return;
    final message = switch (result.kind) {
      ItemUseKind.experienceApplied => UiStrings.itemUseExpResult(
        displayName,
        result.layersGained,
      ),
      ItemUseKind.skillUnlocked => UiStrings.itemUseScrollResult(displayName),
      ItemUseKind.recoveryApplied => UiStrings.itemUseRecoveryResult(
        displayName,
        result.targetName ?? '',
      ),
      ItemUseKind.alreadyKnown => UiStrings.itemUseAlreadyKnown(displayName),
      ItemUseKind.noEffect => UiStrings.itemUseNoEffect(
        displayName,
        result.targetName ?? '',
      ),
      _ => UiStrings.itemUseFailed,
    };
    await PaperDialog.show<void>(
      context,
      title: UiStrings.itemUseConfirmTitle,
      body: Text(
        message,
        style: const TextStyle(
          color: WuxiaUi.ink,
          fontSize: 14,
          height: 1.8,
          letterSpacing: 1,
        ),
      ),
      actions: [
        PlaqueButton(
          label: UiStrings.itemUseDismiss,
          primary: true,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
