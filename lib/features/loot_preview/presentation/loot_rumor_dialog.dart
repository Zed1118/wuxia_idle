// lib/features/loot_preview/presentation/loot_rumor_dialog.dart
import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../domain/drop_name_resolver.dart';
import '../domain/drop_rumor.dart';

const Map<DropRumorBucket, String> _bucketLabels = {
  DropRumorBucket.shouTongBiDe: UiStrings.lootBucketShouTongBiDe,
  DropRumorBucket.changKeDe: UiStrings.lootBucketChangKeDe,
  DropRumorBucket.ouKeDe: UiStrings.lootBucketOuKeDe,
  DropRumorBucket.shaoYouRenDe: UiStrings.lootBucketShaoYouRenDe,
  DropRumorBucket.jiangHuChuanWen: UiStrings.lootBucketJiangHuChuanWen,
};

/// 分组列正文（dialog body / 可独立测，不含 PaperDialog 外壳）。
class LootRumorContent extends StatelessWidget {
  const LootRumorContent({super.key, required this.table, this.currentRealm});

  final DropRumorTable table;
  final RealmTier? currentRealm;

  @override
  Widget build(BuildContext context) {
    if (table.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(UiStrings.lootNoFixedDrop),
      );
    }
    final grouped = table.grouped();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              _bucketLabels[entry.key]!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: WuxiaColors.textMuted,
              ),
            ),
          ),
          for (final e in entry.value)
            _RumorItemRow(entry: e, currentRealm: currentRealm),
        ],
        if (table.isFirstClearGated)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              UiStrings.lootTowerFirstClearOnlyFooter,
              style: TextStyle(fontSize: 11, color: WuxiaColors.textMuted),
            ),
          ),
      ],
    );
  }
}

class _RumorItemRow extends StatelessWidget {
  const _RumorItemRow({required this.entry, this.currentRealm});

  final DropRumorEntry entry;
  final RealmTier? currentRealm;

  @override
  Widget build(BuildContext context) {
    final String name;
    Color? color;
    bool aboveRealm = false;
    if (entry.isEquipment) {
      name = DropNameResolver.equipmentName(entry.defId);
      final tier = DropNameResolver.equipmentTier(entry.defId);
      if (tier != null) {
        color = tierColorForEquipment(tier);
        if (currentRealm != null) {
          aboveRealm = DropNameResolver.isAboveRealm(tier, currentRealm!);
        }
      }
    } else {
      name = DropNameResolver.itemName(entry.defId);
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Row(
        children: [
          Flexible(child: Text('· $name', style: TextStyle(color: color))),
          if (aboveRealm) ...[
            const SizedBox(width: 6),
            const Text(
              UiStrings.lootAboveRealmHint,
              style: TextStyle(fontSize: 11, color: WuxiaColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// 便捷弹窗：info 角标点击调用。
Future<void> showLootRumorDialog(
  BuildContext context, {
  required DropRumorTable table,
  RealmTier? currentRealm,
}) {
  return PaperDialog.show<void>(
    context,
    title: UiStrings.lootRumorDialogTitle,
    body: SingleChildScrollView(
      child: LootRumorContent(table: table, currentRealm: currentRealm),
    ),
    actions: const [],
  );
}
