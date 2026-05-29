import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/character_advancement_service.dart';

/// 多角色升层 banner（mainline / tower victory dialog 共用）。
///
/// 收一组 `(角色名, AdvancementResult)`,仅渲染 `didAdvance == true` 的条目。
/// 若无任何角色升层,返回 [SizedBox.shrink],dialog caller 不用单独判空。
///
/// 体例对齐 `retreat_result_screen._AdvancementBanner`(单角色版)。
/// seclusion 用单 `seclusionAdvancement` 文案;本组件多角色版用
/// [UiStrings.advancementForCharacter] 加角色名前缀,一行一条。
class AdvancementSummary extends StatelessWidget {
  final List<AdvancementEntry> entries;

  const AdvancementSummary({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final advanced = entries.where((e) => e.result.didAdvance).toList();
    if (advanced.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WuxiaColors.gangMeng.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WuxiaColors.gangMeng.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in advanced)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: e.result.crossedTier
                  ? _TierUpRow(entry: e)
                  : _LayerUpRow(entry: e),
            ),
        ],
      ),
    );
  }
}

/// 同境界内小层升级行(普通 auto_awesome 图标)。
class _LayerUpRow extends StatelessWidget {
  const _LayerUpRow({required this.entry});

  final AdvancementEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome, color: WuxiaColors.gangMeng, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            UiStrings.advancementForCharacter(
              entry.chName,
              EnumL10n.realm(entry.result.tierAfter, entry.result.layerAfter),
              entry.result.layersGained,
            ),
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// H2 C2:大境界突破行 — 跨境界 tier 的里程碑,醒目区别于小层升级
/// (military_tech 勋章图标 + 高亮色 +「大境界突破」badge)。
class _TierUpRow extends StatelessWidget {
  const _TierUpRow({required this.entry});

  final AdvancementEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.military_tech,
          color: WuxiaColors.resultHighlight,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                UiStrings.advancementTierUpBadge,
                style: TextStyle(
                  color: WuxiaColors.resultHighlight,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                UiStrings.advancementForCharacter(
                  entry.chName,
                  EnumL10n.realm(
                      entry.result.tierAfter, entry.result.layerAfter),
                  entry.result.layersGained,
                ),
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// [AdvancementSummary.entries] 元素:角色名 + 升层结果。
class AdvancementEntry {
  final String chName;
  final AdvancementResult result;

  const AdvancementEntry({required this.chName, required this.result});
}
