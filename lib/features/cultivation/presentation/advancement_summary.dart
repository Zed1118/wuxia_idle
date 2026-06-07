import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
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
    return CeremonyImagePanel(
      assetPath: WuxiaUi.ceremonyRealmBreakthrough,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      borderRadius: 8,
      borderColor: WuxiaColors.resultHighlight.withValues(alpha: 0.58),
      imageOpacity: 0.32,
      paperVeilOpacity: 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CeremonyTitle(
            icon: Icons.terrain_outlined,
            title: UiStrings.advancementCeremonyTitle,
          ),
          const SizedBox(height: 8),
          for (final e in advanced)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
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
        const _RowGlyph(icon: Icons.auto_awesome, color: WuxiaColors.gangMeng),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            UiStrings.advancementForCharacter(
              entry.chName,
              EnumL10n.realm(entry.result.tierAfter, entry.result.layerAfter),
              entry.result.layersGained,
            ),
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
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
        const _RowGlyph(
          icon: Icons.military_tech,
          color: WuxiaColors.resultHighlight,
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
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                UiStrings.advancementForCharacter(
                  entry.chName,
                  EnumL10n.realm(
                    entry.result.tierAfter,
                    entry.result.layerAfter,
                  ),
                  entry.result.layersGained,
                ),
                style: const TextStyle(
                  color: WuxiaUi.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
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

class _CeremonyTitle extends StatelessWidget {
  const _CeremonyTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: WuxiaColors.resultHighlight, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: WuxiaUi.ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: WuxiaUi.ink.withValues(alpha: 0.28),
          ),
        ),
      ],
    );
  }
}

class _RowGlyph extends StatelessWidget {
  const _RowGlyph({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
