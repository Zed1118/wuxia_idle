// lib/features/loot_preview/presentation/loot_summary_line.dart
import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../domain/drop_name_resolver.dart';
import '../domain/drop_rumor.dart';

/// 卡片简版「可能收获：X · Y · Z」一行（最多 3 代表）。空表显无固定收获。
class LootSummaryLine extends StatelessWidget {
  const LootSummaryLine({super.key, required this.table, this.maxItems = 3});

  final DropRumorTable table;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    if (table.isEmpty) {
      return const Text(
        UiStrings.lootNoFixedDrop,
        style: TextStyle(fontSize: 12, color: WuxiaColors.textMuted),
      );
    }
    final reps = table.topRepresentatives(maxItems);
    final names = reps
        .map((e) => e.isEquipment
            ? DropNameResolver.equipmentName(e.defId)
            : DropNameResolver.itemName(e.defId))
        .join(' · ');
    return Text(
      '${UiStrings.lootSummaryPrefix}$names',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, color: WuxiaColors.textMuted),
    );
  }
}
