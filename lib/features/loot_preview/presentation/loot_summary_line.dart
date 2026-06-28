// lib/features/loot_preview/presentation/loot_summary_line.dart
import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../battle/domain/enum_localizations.dart';
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
        .map(
          (e) => e.isEquipment
              ? DropNameResolver.equipmentName(e.defId)
              : DropNameResolver.itemName(e.defId),
        )
        .join(' · ');
    return Text(
      '${UiStrings.lootSummaryPrefix}$names',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, color: WuxiaColors.textMuted),
    );
  }
}

/// 关卡卡片标题区行内掉落摘要。
///
/// 不显示百分比与掉落桶名，只显示推荐境界与掉落名称。
/// 装备条目用装备阶色，物品条目用物品类型色区分。
class InlineLootSummaryLine extends StatelessWidget {
  const InlineLootSummaryLine({
    super.key,
    required this.table,
    this.recommendedRealm,
    this.showRecommendedRealm = true,
    this.maxItems = 3,
    this.alignment = WrapAlignment.end,
  });

  final DropRumorTable table;
  final RealmTier? recommendedRealm;
  final bool showRecommendedRealm;
  final int maxItems;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final tokens = <Widget>[];
    if (showRecommendedRealm && recommendedRealm != null) {
      tokens.add(
        Text(
          '${UiStrings.previewRecommendedRealmLabel}: '
          '${EnumL10n.realmTier(recommendedRealm!)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: WuxiaColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (table.isEmpty) {
      tokens.add(
        const Text(
          UiStrings.lootNoFixedDrop,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: WuxiaColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      tokens.addAll(
        table.topRepresentatives(maxItems).map(_InlineLootToken.new),
      );
    }
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 2,
      children: tokens,
    );
  }
}

class _InlineLootToken extends StatelessWidget {
  const _InlineLootToken(this.entry);

  final DropRumorEntry entry;

  @override
  Widget build(BuildContext context) {
    final name = entry.isEquipment
        ? DropNameResolver.equipmentName(entry.defId)
        : DropNameResolver.itemName(entry.defId);
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: _inlineLootColor(entry),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

Color _inlineLootColor(DropRumorEntry entry) {
  if (entry.isEquipment) {
    final tier = DropNameResolver.equipmentTier(entry.defId);
    return tier == null
        ? WuxiaColors.textSecondary
        : tierColorForEquipment(tier);
  }
  return switch (ItemType.fromDefId(entry.defId)) {
    ItemType.moJianShi => WuxiaColors.internalForce,
    ItemType.xinXueJieJing => WuxiaColors.yinRou,
    ItemType.jingYanDan => WuxiaColors.hpHigh,
    ItemType.techniqueScroll => WuxiaColors.lingQiao,
    ItemType.miscMaterial => WuxiaColors.hpMid,
    ItemType.silver => WuxiaColors.resultHighlight,
  };
}
