import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../equipment/application/equipment_disposal_service.dart';
import '../../equipment/domain/equipment_disposal.dart';
import '../../shop/application/shop_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';

/// 批量整理对话框（Task 6 / 2026-06-26）：一键按品级出售或分解背包装备。
///
/// **过滤规则**：仅展示 `ownerCharacterId==null && !isLineageHeritage` 的背包装备；
/// 已装备 / 师承遗物不可批量处置，但其数量不计入件数显示。
/// 全品阶均可批量（含宝物/神物），每次操作均走二次确认弹窗（用户拍板）。
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
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '错误：$e',
                        style: const TextStyle(color: WuxiaColors.hpLow),
                      ),
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
    // 按品阶分桶，只保留可处置（背包且非师承）。
    final byTier = <EquipmentTier, List<Equipment>>{};
    for (final eq in list) {
      if (eq.ownerCharacterId == null && !eq.isLineageHeritage) {
        byTier.putIfAbsent(eq.tier, () => []).add(eq);
      }
    }

    // 高品阶在前（神物→寻常货），只显示非空品阶。
    final tiers =
        EquipmentTier.values.reversed.where((t) => byTier.containsKey(t)).toList();

    if (tiers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            UiStrings.bulkDisposalEmpty,
            style: TextStyle(color: WuxiaColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < tiers.length; i++) ...[
          if (i > 0)
            const Divider(color: WuxiaColors.border, height: 1, thickness: 1),
          _TierRow(
            tier: tiers[i],
            disposable: byTier[tiers[i]]!,
            onSell: () => _handleSell(context, ref, tiers[i], byTier[tiers[i]]!),
            onDisassemble: () =>
                _handleDisassemble(context, ref, tiers[i], byTier[tiers[i]]!),
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

  Future<void> _handleDisassemble(
    BuildContext context,
    WidgetRef ref,
    EquipmentTier tier,
    List<Equipment> disposable,
  ) async {
    final config = GameRepository.instance.numbers.disposal;
    final count = disposable.length;
    var totalMj = 0;
    var totalXx = 0;
    for (final eq in disposable) {
      final r = equipmentDisassembleRewards(eq.tier, eq.enhanceLevel, config);
      totalMj += r.mojianshi;
      totalXx += r.xinxuejiejing;
    }

    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.equipmentDisassemble,
      body: Text(
        UiStrings.disassembleConfirmBody(count, totalMj, totalXx),
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
          label: UiStrings.equipmentDisassemble,
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
    ).disassembleAllOfTier(tier);

    ref.invalidate(allEquipmentsProvider);
    ref.invalidate(allInventoryItemsProvider);
    ref.invalidate(silverBalanceProvider);
  }
}

/// 品阶行：品级标签（件数）+ 「一键出售」+「一键分解」按钮。
class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.tier,
    required this.disposable,
    required this.onSell,
    required this.onDisassemble,
  });

  final EquipmentTier tier;
  final List<Equipment> disposable;
  final VoidCallback onSell;
  final VoidCallback onDisassemble;

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
          const SizedBox(width: 8),
          PlaqueButton(label: UiStrings.bulkDisassembleButton, onTap: onDisassemble),
        ],
      ),
    );
  }
}
