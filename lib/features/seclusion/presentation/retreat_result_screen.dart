import 'package:flutter/material.dart';

import '../../../features/battle/domain/enum_localizations.dart';
import '../../../ui/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../application/seclusion_service.dart';
import '../domain/seclusion_map_def.dart';

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
    final hasReward = mojianshi > 0 ||
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 地图名
              Text(
                mapDef.mapName,
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 实际时长
              Text(
                UiStrings.seclusionActualHours(actualHours),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // 奖励列表
              if (!hasReward)
                const Text(
                  UiStrings.seclusionResultEmpty,
                  style: TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 14,
                  ),
                )
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
                    label: UiStrings.seclusionInternalForce(internalForce),
                  ),
                if (insightPoints > 0)
                  _RewardRow(
                    icon: Icons.auto_stories,
                    label: UiStrings.seclusionInsightPoints(insightPoints),
                  ),
                for (final eq in equipDrops)
                  _RewardRow(
                    icon: Icons.sports_martial_arts,
                    label: eq.defId,
                  ),
              ],

              // 升层 banner(本批 W15 #30 P3 加,advancement 非 null 且
              // didAdvance 才显)
              if (advancement != null && advancement.didAdvance) ...[
                const SizedBox(height: 16),
                _AdvancementBanner(advancement: advancement),
              ],

              const Spacer(),

              // 返回按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // 经 pushReplacement 链回 list；list 收 true 触发 refresh。
                  // 不用 popUntil(isFirst) — 会把 list 也弹掉退到主菜单。
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WuxiaColors.gangMeng,
                    foregroundColor: WuxiaColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    UiStrings.seclusionResultBack,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RewardRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: WuxiaColors.resultHighlight, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WuxiaColors.gangMeng.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WuxiaColors.gangMeng.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: WuxiaColors.gangMeng,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              UiStrings.seclusionAdvancement(
                EnumL10n.realm(tierAfter, layerAfter),
                layers,
              ),
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
