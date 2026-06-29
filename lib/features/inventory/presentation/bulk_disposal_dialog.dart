import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/inventory_providers.dart';
import '../../../core/application/character_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../equipment/application/equipment_disposal_service.dart';
import '../../equipment/domain/equipment_disposal.dart';
import '../../equipment/domain/equipment_slot_occupancy.dart';
import '../../shop/application/shop_providers.dart';
import '../application/inventory_organization.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/error_fallback.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';

/// 批量整理对话框（Task 6 / 2026-06-26）：一键按品级出售背包装备。
///
/// **过滤规则**：仅展示批量安全策略允许的自由装备；已装备 / 师承遗物 /
/// 玩家锁定 / 高阶 / 带个人典故或传承链路的装备不可批量出售，并在顶部汇总原因。
/// 每次操作均走二次确认弹窗。
///
/// 入口：`inventory_screen.dart` 装备 Tab 顶部 `PlaqueButton(equipmentBulkEntry)`
/// 通过 `showDialog<void>(builder: (_) => const BulkDisposalDialog())` 弹出。
class BulkDisposalDialog extends ConsumerWidget {
  const BulkDisposalDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allEquipmentsProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: PaperPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              const Text(
                UiStrings.equipmentBulkEntry,
                style: TextStyle(
                  color: WuxiaUi.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              // 内容（高度限制 + 可滚动）
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: async.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => ErrorFallback(
                      error: e,
                      onRetry: () => ref.invalidate(allEquipmentsProvider),
                    ),
                    data: (list) => _buildContent(context, ref, list),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: PlaqueButton(
                  label: UiStrings.commonCancel,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Equipment> list,
  ) {
    final equippedIds = _watchActiveEquippedIds(ref);
    final policy = defaultEquipmentProtectionPolicy();
    final protected = _ProtectionCounts.from(list, equippedIds, policy);
    // 按品阶分桶（不在槽位 && 非师承 && 非锁定），高品阶在前。
    final plan = buildBulkDisposalPlan(
      list,
      equippedIds,
      activeFormationEquipmentIds: equippedIds,
      policy: policy,
    );

    if (plan.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                UiStrings.bulkDisposalEmpty,
                style: TextStyle(color: WuxiaColors.textMuted),
              ),
            ),
          ),
          _ProtectedSummary(counts: protected),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProtectedSummary(counts: protected),
        for (int i = 0; i < plan.tiers.length; i++) ...[
          if (i > 0)
            const Divider(color: WuxiaColors.border, height: 1, thickness: 1),
          _TierRow(
            tier: plan.tiers[i],
            disposable: plan.itemsFor(plan.tiers[i]),
            onSell: () => _handleSell(
              context,
              ref,
              plan.tiers[i],
              plan.itemsFor(plan.tiers[i]),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleSell(
    BuildContext context,
    WidgetRef ref,
    EquipmentTier tier,
    List<Equipment> disposable,
  ) async {
    final config = GameRepository.instance.numbers.disposal;
    final count = disposable.length;
    final totalSilver = disposable.fold(
      0,
      (sum, eq) => sum + equipmentSellPrice(eq.tier, eq.enhanceLevel, config),
    );

    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.equipmentSell,
      body: Text(
        UiStrings.sellConfirmBody(count, totalSilver),
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
          label: UiStrings.equipmentSell,
          primary: true,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    await EquipmentDisposalService(
      isar: IsarSetup.instance,
      config: config,
    ).sellAllOfTier(tier);

    ref.invalidate(allEquipmentsProvider);
    ref.invalidate(allInventoryItemsProvider);
    ref.invalidate(silverBalanceProvider);
  }
}

Set<int> _watchActiveEquippedIds(WidgetRef ref) {
  final ids = ref.watch(activeCharacterIdsProvider).value ?? const <int>[];
  final characters = [
    for (final id in ids) ref.watch(characterByIdProvider(id)).value,
  ].nonNulls;
  return equippedEquipmentIdsForCharacters(characters);
}

class _ProtectionCounts {
  const _ProtectionCounts({
    required this.locked,
    required this.equipped,
    required this.heritage,
    required this.highTier,
    required this.story,
  });

  final int locked;
  final int equipped;
  final int heritage;
  final int highTier;
  final int story;

  bool get isEmpty =>
      locked == 0 &&
      equipped == 0 &&
      heritage == 0 &&
      highTier == 0 &&
      story == 0;

  factory _ProtectionCounts.from(
    List<Equipment> list,
    Set<int> equippedIds,
    EquipmentProtectionPolicy policy,
  ) {
    var locked = 0;
    var equipped = 0;
    var heritage = 0;
    var highTier = 0;
    var story = 0;
    for (final eq in list) {
      final reason = equipmentProtectionReason(
        eq,
        equippedEquipmentIds: equippedIds,
        activeFormationEquipmentIds: equippedIds,
        policy: policy,
      );
      switch (reason) {
        case EquipmentProtectionReason.locked:
          locked++;
        case EquipmentProtectionReason.currentFormation:
        case EquipmentProtectionReason.equipped:
          equipped++;
        case EquipmentProtectionReason.lineageHeritage:
          heritage++;
        case EquipmentProtectionReason.highTier:
          highTier++;
        case EquipmentProtectionReason.protectedSource:
        case EquipmentProtectionReason.story:
          story++;
        case null:
          break;
      }
    }
    return _ProtectionCounts(
      locked: locked,
      equipped: equipped,
      heritage: heritage,
      highTier: highTier,
      story: story,
    );
  }
}

class _ProtectedSummary extends StatelessWidget {
  const _ProtectedSummary({required this.counts});

  final _ProtectionCounts counts;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          UiStrings.bulkProtectedSummary(
            locked: counts.locked,
            equipped: counts.equipped,
            heritage: counts.heritage,
            highTier: counts.highTier,
            story: counts.story,
          ),
          style: const TextStyle(
            color: WuxiaColors.textMuted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

/// 品阶行：品级标签（件数）+ 「一键出售」按钮。
class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.tier,
    required this.disposable,
    required this.onSell,
  });

  final EquipmentTier tier;
  final List<Equipment> disposable;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final label = UiStrings.bulkTierLabel(
      EnumL10n.equipmentTier(tier),
      disposable.length,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PlaqueButton(label: UiStrings.bulkSellButton, onTap: onSell),
        ],
      ),
    );
  }
}
