import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../../shared/battle_shared/enum_localizations.dart';
import '../domain/advancement_entry.dart';

/// 多角色升层 banner（mainline / tower victory dialog 共用）。
///
/// 收一组 `(角色名, AdvancementResult)`,统一渲染修为经验、派生等级和境界突破。
/// 若无任何修为变化,返回 [SizedBox.shrink],dialog caller 不用单独判空。
///
/// 体例对齐 `retreat_result_screen._AdvancementBanner`(单角色版)。
/// seclusion 用单 `seclusionAdvancement` 文案;本组件多角色版用
/// [UiStrings.advancementForCharacter] 加角色名前缀,一行一条。
class AdvancementSummary extends StatelessWidget {
  final List<AdvancementEntry> entries;

  const AdvancementSummary({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final progressed = entries
        .where((e) => e.result.experienceGained > 0 || e.result.didAdvance)
        .toList();
    if (progressed.isEmpty) return const SizedBox.shrink();
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
          for (final e in progressed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: e.result.crossedTier
                  ? _TierUpRow(entry: e)
                  : e.result.didAdvance
                  ? _LayerUpRow(entry: e)
                  : _ExperienceProgressRow(entry: e),
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
            _realmProgressText(entry),
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
                _realmProgressText(entry),
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

class _ExperienceProgressRow extends StatelessWidget {
  const _ExperienceProgressRow({required this.entry});

  final AdvancementEntry entry;

  @override
  Widget build(BuildContext context) {
    final progress = entry.result.progressChange;
    return Row(
      children: [
        const _RowGlyph(icon: Icons.trending_up, color: WuxiaColors.gangMeng),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            progress.didLevelUp
                ? UiStrings.cultivationLevelChanged(
                    entry.chName,
                    progress.before.level,
                    progress.after.level,
                  )
                : UiStrings.cultivationExperienceGained(
                    entry.chName,
                    entry.result.experienceGained,
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

String _realmProgressText(AdvancementEntry entry) {
  final realmText = UiStrings.advancementForCharacter(
    entry.chName,
    EnumL10n.realm(entry.result.tierAfter, entry.result.layerAfter),
    entry.result.layersGained,
  );
  final progress = entry.result.progressChange;
  return progress.didLevelUp
      ? UiStrings.cultivationRealmAndLevelChanged(
          realmText,
          progress.before.level,
          progress.after.level,
        )
      : realmText;
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
