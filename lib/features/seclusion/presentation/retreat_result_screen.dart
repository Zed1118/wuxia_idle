import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../features/battle/domain/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../application/seclusion_service.dart';
import '../domain/seclusion_map_def.dart';
import 'seclusion_map_visuals.dart';

/// 闭关收功结果屏幕（Phase 3 T49/T50 / W15 #30 P3 扩 EXP + 升层 banner）。
///
/// 显示：地图名 / 实际挂机时长 / 5 维奖励清单（磨剑石 / 经验 / 内力 / 心法
/// 领悟点 / 装备）/ 升层 banner（若本次收功触发升层,显示「突破至 X·Y」）。
/// 「返回」按钮弹回主菜单（popUntil root）。
class RetreatResultScreen extends StatelessWidget {
  final SeclusionMapDef mapDef;
  final RetreatResult result;

  const RetreatResultScreen({
    super.key,
    required this.mapDef,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final mojianshi = result.mojianshi;
    final actualHours = result.actualHours;
    final equipDrops = result.equipmentDrops;
    final internalForce = result.internalForcePoints;
    final insightPoints = result.techniqueLearnPoints;
    final experience = result.experiencePoints;
    final advancement = result.advancement;
    final hasReward =
        mojianshi > 0 ||
        equipDrops.isNotEmpty ||
        internalForce > 0 ||
        insightPoints > 0 ||
        experience > 0;

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.seclusionResultTitle),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: PaperPanel(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                paperOpacity: 0.32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResultHero(mapDef: mapDef, actualHours: actualHours),
                    const SizedBox(height: 12),
                    const SectionHeader(UiStrings.seclusionResultReportTitle),
                    const SizedBox(height: 10),
                    if (!hasReward)
                      const _EmptyReward()
                    else ...[
                      if (mojianshi > 0)
                        _RewardRow(
                          icon: Icons.construction,
                          label: UiStrings.seclusionMojianshi(mojianshi),
                        ),
                      if (experience > 0)
                        _RewardRow(
                          icon: Icons.trending_up,
                          label: UiStrings.seclusionExperience(experience),
                        ),
                      if (internalForce > 0)
                        _RewardRow(
                          icon: Icons.bolt,
                          label: UiStrings.seclusionInternalForce(
                            internalForce,
                          ),
                        ),
                      if (insightPoints > 0)
                        _RewardRow(
                          icon: Icons.auto_stories,
                          label: UiStrings.seclusionInsightPoints(
                            insightPoints,
                          ),
                        ),
                      for (final eq in equipDrops)
                        _RewardRow(
                          icon: Icons.sports_martial_arts,
                          // H1 批3:显中文名而非 raw defId(真 bug)。沿 character_panel
                          // / stage_victory_dialog 体例,GameRepository 未加载兜底 defId。
                          label: GameRepository.isLoaded
                              ? GameRepository.instance
                                    .getEquipment(eq.defId)
                                    .name
                              : eq.defId,
                        ),
                    ],
                    if (insightPoints > 0) ...[
                      const SizedBox(height: 8),
                      const _InsightHint(),
                    ],
                    if (advancement != null && advancement.didAdvance) ...[
                      const SizedBox(height: 10),
                      _AdvancementBanner(advancement: advancement),
                    ],
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.center,
                      child: PlaqueButton(
                        label: UiStrings.seclusionResultBack,
                        primary: true,
                        // 经 pushReplacement 链回 list；list 收 true 触发 refresh。
                        // 不用 popUntil(isFirst) — 会把 list 也弹掉退到主菜单。
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({required this.mapDef, required this.actualHours});

  final SeclusionMapDef mapDef;
  final double actualHours;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 168,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              WuxiaUi.ceremonyRetreatResult,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, _, _) => _MapImage(path: mapDef.imagePath),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 16,
              child: SeclusionMapTraitIcon(def: mapDef, size: 46),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ReportSeal(),
                  const SizedBox(height: 8),
                  Text(
                    mapDef.mapName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SeclusionMapTraitStrip(def: mapDef),
                  const SizedBox(height: 5),
                  Text(
                    UiStrings.seclusionActualHours(actualHours),
                    style: const TextStyle(
                      color: WuxiaColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapImage extends StatelessWidget {
  const _MapImage({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null) return _fallback();
    return Image(
      image: ExactAssetImage(path!, bundle: DefaultAssetBundle.of(context)),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => Container(color: WuxiaColors.background);
}

class _RewardRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RewardRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaUi.muted.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: WuxiaUi.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSeal extends StatelessWidget {
  const _ReportSeal();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.jiang.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: WuxiaUi.gold.withValues(alpha: 0.72)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          UiStrings.seclusionResultTitle,
          style: TextStyle(
            color: WuxiaColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyReward extends StatelessWidget {
  const _EmptyReward();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaUi.muted.withValues(alpha: 0.28)),
      ),
      child: const Text(
        UiStrings.seclusionResultEmpty,
        style: TextStyle(color: WuxiaUi.ink2, fontSize: 14),
      ),
    );
  }
}

/// 根因A B3 sink 引导气泡:领悟点 → 「心法面板」凝练为修炼度路径提示。
/// 低调样式(tip 图标 + 次要文字),不抢升层 banner 风头(§5.7 非教程弹窗)。
class _InsightHint extends StatelessWidget {
  const _InsightHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.tips_and_updates_outlined, color: WuxiaUi.ink2, size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            UiStrings.seclusionInsightHint,
            style: TextStyle(color: WuxiaUi.ink2, fontSize: 13, height: 1.3),
          ),
        ),
      ],
    );
  }
}

class _AdvancementBanner extends StatelessWidget {
  final AdvancementResult advancement;

  const _AdvancementBanner({required this.advancement});

  @override
  Widget build(BuildContext context) {
    final tierAfter = advancement.tierAfter;
    final layerAfter = advancement.layerAfter;
    final layers = advancement.layersGained;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: WuxiaUi.jiang.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WuxiaUi.jiang.withValues(alpha: 0.62)),
      ),
      // H2 C2:大境界突破(跨 tier)走醒目勋章 + badge,区别小层升级。
      child: Row(
        children: [
          Icon(
            advancement.crossedTier ? Icons.military_tech : Icons.auto_awesome,
            color: advancement.crossedTier ? WuxiaUi.gold : WuxiaUi.jiang,
            size: advancement.crossedTier ? 24 : 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (advancement.crossedTier)
                  const Text(
                    UiStrings.advancementTierUpBadge,
                    style: TextStyle(
                      color: WuxiaUi.gold,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  UiStrings.seclusionAdvancement(
                    EnumL10n.realm(tierAfter, layerAfter),
                    layers,
                  ),
                  style: const TextStyle(
                    color: WuxiaUi.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
