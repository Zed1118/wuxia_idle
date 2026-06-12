import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/game_repository.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/application/inventory_providers.dart';
import '../../equipment/presentation/enhance_dialog.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../core/application/character_providers.dart';
import '../../../shared/widgets/wuxia_ui/item_slot.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/plaque_tab.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import 'equipment_detail_screen.dart';

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
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  var _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.inventoryTitle,
        onBack: () => Navigator.of(context).maybePop(),
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

/// T11 仓库筛选维度(全部/可装备/已穿戴/可开锋/境界未达)。
/// 全部维度数据确定、零假入口(不含语义模糊的「可强化」——强化无封顶上限)。
enum _EquipFilter { all, equippable, equipped, forgeable, realmLocked }

class _EquipmentTab extends ConsumerStatefulWidget {
  const _EquipmentTab();

  @override
  ConsumerState<_EquipmentTab> createState() => _EquipmentTabState();
}

class _EquipmentTabState extends ConsumerState<_EquipmentTab> {
  _EquipFilter _filter = _EquipFilter.all;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allEquipmentsProvider);
    final ids = ref.watch(activeCharacterIdsProvider).value ?? const [];
    final playerRealm = ids.isEmpty
        ? null
        : ref.watch(characterByIdProvider(ids.first)).value?.realmTier;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: SelectableText(
          'load error: $e',
          style: const TextStyle(color: WuxiaColors.hpLow),
        ),
      ),
      data: (list) {
        final filtered = list.where((eq) => _matches(eq, playerRealm)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FilterBar(
              selected: _filter,
              onSelect: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        UiStrings.inventoryEmpty,
                        style: TextStyle(color: WuxiaColors.textMuted),
                      ),
                    )
                  : _EquipmentGrid(equipments: filtered),
            ),
          ],
        );
      },
    );
  }

  bool _matches(Equipment eq, RealmTier? realm) {
    return switch (_filter) {
      _EquipFilter.all => true,
      _EquipFilter.equippable =>
        eq.ownerCharacterId == null &&
            (realm == null || eq.isEquippableAtRealm(realm)),
      _EquipFilter.equipped => eq.ownerCharacterId != null,
      _EquipFilter.forgeable => eq.forgingSlots.any((s) => !s.unlocked),
      _EquipFilter.realmLocked =>
        realm != null && !eq.isEquippableAtRealm(realm),
    };
  }
}

/// T11 筛选条:5 个可选 chip,水墨风。
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelect});

  final _EquipFilter selected;
  final ValueChanged<_EquipFilter> onSelect;

  static const Map<_EquipFilter, String> _labels = {
    _EquipFilter.all: UiStrings.inventoryFilterAll,
    _EquipFilter.equippable: UiStrings.inventoryFilterEquippable,
    _EquipFilter.equipped: UiStrings.inventoryFilterEquipped,
    _EquipFilter.forgeable: UiStrings.inventoryFilterForgeable,
    _EquipFilter.realmLocked: UiStrings.inventoryFilterRealmLocked,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final f in _EquipFilter.values)
            _FilterChip(
              label: _labels[f]!,
              selected: f == selected,
              onTap: () => onSelect(f),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: SelectableText(
          'load error: $e',
          style: const TextStyle(color: WuxiaColors.hpLow),
        ),
      ),
      data: (list) {
        final nonEmpty = list.where((it) => it.quantity > 0).toList();
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
    );
  }
}

class _EquipmentGrid extends ConsumerWidget {
  const _EquipmentGrid({required this.equipments});

  final List<Equipment> equipments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 玩家主角境界 → 可装备状态判定基准(取 active 队首;无则不锁)。
    final ids = ref.watch(activeCharacterIdsProvider).value ?? const [];
    final playerRealm = ids.isEmpty
        ? null
        : ref.watch(characterByIdProvider(ids.first)).value?.realmTier;

    final bySlot = <EquipmentSlot, List<Equipment>>{};
    for (final eq in equipments) {
      bySlot.putIfAbsent(eq.slot, () => []).add(eq);
    }
    for (final list in bySlot.values) {
      list.sort((a, b) => b.tier.index.compareTo(a.tier.index));
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
  });

  final EquipmentSlot slot;
  final List<Equipment> items;
  final RealmTier? playerRealm;

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
                _EquipmentGridTile(equipment: eq, playerRealm: playerRealm),
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
  });

  final Equipment equipment;
  final RealmTier? playerRealm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = equipment;
    final color = tierColorForEquipment(eq.tier);
    final def = GameRepository.instance.equipmentDefs[eq.defId];
    final locked = playerRealm != null && !eq.isEquippableAtRealm(playerRealm!);
    // T11:封条显具体境界原因(§5.3 装备阶↔境界 1:1,需同序境界),非泛化「未达境界」。
    final requiredRealmName =
        EnumL10n.realmTier(RealmTier.values[eq.tier.index]);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ItemSlot(
          imagePath: def?.iconPath,
          name: def?.name ?? eq.defId,
          tierColor: color,
          equipmentSlot: eq.slot,
          enhanceLevel: eq.enhanceLevel,
          locked: locked,
          lockText: UiStrings.inventoryRealmLockBanner(requiredRealmName),
          highTier:
              eq.tier == EquipmentTier.baoWu || eq.tier == EquipmentTier.shenWu,
          onTap: () async {
            await _openEquipment(context, ref, def, eq);
          },
        ),
        if (eq.isLineageHeritage)
          const Positioned(
            top: 2,
            left: 2,
            child: Icon(
              Icons.auto_awesome,
              size: 14,
              color: WuxiaColors.bossFrame,
            ),
          ),
      ],
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

class _MaterialGroup extends StatelessWidget {
  const _MaterialGroup({required this.type, required this.items});

  final ItemType type;
  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final name = EnumL10n.itemType(type);
    return Card(
      color: WuxiaColors.panel,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: WuxiaColors.textPrimary,
        collapsedIconColor: WuxiaColors.textPrimary,
        title: Row(
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
        children: items
            .map((it) => _MaterialRow(item: it, name: name))
            .toList(),
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.item, required this.name});

  final InventoryItem item;
  final String name;

  @override
  Widget build(BuildContext context) {
    final usage = UiStrings.materialUsage(item.itemType.name);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: WuxiaColors.avatarFill,
        border: Border(
          left: BorderSide(color: WuxiaColors.textPrimary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/ui/coin_icon.png',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(width: 16, height: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  UiStrings.materialQuantity(name, item.quantity),
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (usage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      usage,
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 11,
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
