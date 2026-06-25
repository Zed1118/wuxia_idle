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
import '../../inner_demon/application/inner_demon_service.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../application/item_use_service.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../core/application/character_providers.dart';
import '../../../shared/widgets/wuxia_ui/item_slot.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../../../shared/widgets/wuxia_ui/plaque_tab.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../help/domain/help_topic.dart';
import '../../help/presentation/context_help_button.dart';
import '../../shop/application/shop_providers.dart';
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
    final silverAsync = ref.watch(silverBalanceProvider);
    final silverBalance = silverAsync.maybeWhen(data: (n) => n, orElse: () => 0);

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
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: SelectableText(
                'load error: $e',
                style: const TextStyle(color: WuxiaColors.hpLow),
              ),
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

/// 单条物料行（材料经济 P2 T4：经验丹 / 秘籍可「使用」）。
///
/// 名取 [ItemDef.name]（items.yaml，凝神丹 / 开碑手·秘籍…），缺 def 退回
/// itemType 组名 [name]。经验丹 / 秘籍行末加「使用」按钮 → 确认弹窗 →
/// [ItemUseService.use] → 结果浮层 + invalidate（背包 + 角色 provider）。
/// 磨剑石 / 心血结晶 / 银两无按钮（service 也只识别前二者）。
class _MaterialRow extends ConsumerWidget {
  const _MaterialRow({required this.item, required this.name});

  final InventoryItem item;
  final String name;

  bool get _usable =>
      item.itemType == ItemType.jingYanDan ||
      item.itemType == ItemType.techniqueScroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemDef = GameRepository.instance.itemDefs[item.defId];
    final displayName = itemDef?.name ?? name;
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
                  UiStrings.materialQuantity(displayName, item.quantity),
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
          if (_usable && itemDef != null)
            TextButton(
              onPressed: () => _onUse(context, ref, itemDef, displayName),
              child: const Text(
                UiStrings.itemUseButton,
                style: TextStyle(color: WuxiaColors.textPrimary),
              ),
            ),
        ],
      ),
    );
  }

  /// 确认 → service → 结果浮层 → invalidate（沿 shop_screen `_handleBuy` 体例）。
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
      ItemUseKind.alreadyKnown => UiStrings.itemUseAlreadyKnown(displayName),
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
