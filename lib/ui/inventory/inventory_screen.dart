import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/enum_localizations.dart';
import '../../data/defs/equipment_def.dart';
import '../../data/game_repository.dart';
import '../../data/models/enums.dart';
import '../../data/models/equipment.dart';
import '../../data/numbers_config.dart';
import '../../providers/battle_providers.dart';
import '../../providers/inventory_providers.dart';
import '../enhancement/enhance_dialog.dart';
import '../strings.dart';
import '../theme/colors.dart';
import '../theme/tier_colors.dart';
import 'equipment_detail_screen.dart';

/// 装备仓库（phase2_tasks T29 §424-425 + T32 #22a/#22b 销账）。
///
/// 一次性 `findAll` 整表展示，按 tier 分段（神物→寻常货 7 阶，已在
/// [allEquipmentsProvider] 中排序）。点击 row 弹 [EnhanceDialog]。
///
/// 持久化 writeTxn 由 [EnhanceDialog] / [ForgingPanel] 自身在调用 service
/// 后委托给各 service.persistResult 完成；本组件 dialog close 后再 invalidate
/// [allEquipmentsProvider] 重读最新装备。
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allEquipmentsProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.inventoryTitle),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: async.when(
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
        ),
      ),
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
