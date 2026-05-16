import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/game_repository.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../data/numbers_config.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../equipment/presentation/enhance_dialog.dart';
import '../../../ui/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
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
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: WuxiaColors.background,
        appBar: AppBar(
          title: const Text(UiStrings.inventoryTitle),
          backgroundColor: WuxiaColors.sidebar,
          foregroundColor: WuxiaColors.textPrimary,
          bottom: const TabBar(
            tabs: [
              Tab(text: UiStrings.inventoryTabEquipment),
              Tab(text: UiStrings.inventoryTabMaterial),
            ],
            labelColor: WuxiaColors.textPrimary,
            unselectedLabelColor: WuxiaColors.textMuted,
            indicatorColor: WuxiaColors.textPrimary,
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              _EquipmentTab(),
              _MaterialTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipmentTab extends ConsumerWidget {
  const _EquipmentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allEquipmentsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: SelectableText(
          'load error: $e',
          style: const TextStyle(color: WuxiaColors.hpLow),
        ),
      ),
      data: (list) => list.isEmpty
          ? const Center(
              child: Text(
                UiStrings.inventoryEmpty,
                style: TextStyle(color: WuxiaColors.textMuted),
              ),
            )
          : _List(equipments: list),
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

class _List extends ConsumerWidget {
  const _List({required this.equipments});

  final List<Equipment> equipments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(numbersConfigProvider);
    final groups = <EquipmentTier, List<Equipment>>{};
    for (final eq in equipments) {
      groups.putIfAbsent(eq.tier, () => []).add(eq);
    }
    final tiers = groups.keys.toList()
      ..sort((a, b) => b.index.compareTo(a.index));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: tiers.length,
      itemBuilder: (ctx, i) {
        final tier = tiers[i];
        final items = groups[tier]!;
        return _TierGroup(tier: tier, items: items, numbers: n);
      },
    );
  }
}

class _TierGroup extends StatelessWidget {
  const _TierGroup({
    required this.tier,
    required this.items,
    required this.numbers,
  });

  final EquipmentTier tier;
  final List<Equipment> items;
  final NumbersConfig numbers;

  @override
  Widget build(BuildContext context) {
    final color = tierColorForEquipment(tier);
    return Card(
      color: WuxiaColors.panel,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: color,
        collapsedIconColor: color,
        title: Row(
          children: [
            Container(width: 3, height: 18, color: color),
            const SizedBox(width: 8),
            Text(
              EnumL10n.equipmentTier(tier),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
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
            .map((eq) => _Row(equipment: eq, numbers: numbers))
            .toList(),
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.equipment, required this.numbers});

  final Equipment equipment;
  final NumbersConfig numbers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = equipment;
    final color = tierColorForEquipment(eq.tier);
    final resonance = eq.resonanceStage(numbers);
    EquipmentDef? def;
    try {
      def = GameRepository.instance.getEquipment(eq.defId);
    } catch (_) {
      // fixture / unknown defId → ForgingPanel 用 null 兜底，row 不渲染装备名
      def = null;
    }
    return InkWell(
      onTap: () async {
        // def 非空走详情屏(W15 LoreLoader 接入后);def == null(fixture /
        // 未知 defId)兜底直弹 EnhanceDialog,保持向后兼容。
        if (def != null) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) =>
                  EquipmentDetailScreen(equipment: eq, def: def!),
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
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: WuxiaColors.avatarFill,
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                EnumL10n.equipmentSlot(eq.slot),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              UiStrings.enhanceLevel(eq.enhanceLevel),
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (def != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  def.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(
              EnumL10n.resonanceStage(resonance),
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
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
        children:
            items.map((it) => _MaterialRow(item: it, name: name)).toList(),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: WuxiaColors.avatarFill,
        border: Border(
          left: BorderSide(color: WuxiaColors.textPrimary, width: 3),
        ),
      ),
      child: Text(
        UiStrings.materialQuantity(name, item.quantity),
        style: const TextStyle(
          color: WuxiaColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
