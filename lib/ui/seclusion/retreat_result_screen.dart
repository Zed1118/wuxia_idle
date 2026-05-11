import 'package:flutter/material.dart';

import '../../data/defs/seclusion_map_def.dart';
import '../../services/seclusion_service.dart';
import '../strings.dart';
import '../theme/colors.dart';

/// 闭关收功结果屏幕（Phase 3 T49/T50）。
///
/// 显示：地图名 / 实际挂机时长 / 奖励清单（磨剑石 N 颗 + 装备（若有））。
/// 「返回」按钮弹回主菜单（popUntil root）。
class RetreatResultScreen extends StatelessWidget {
  final SeclusionMapDef mapDef;
  final RetreatOutputs outputs;

  const RetreatResultScreen({
    super.key,
    required this.mapDef,
    required this.outputs,
  });

  @override
  Widget build(BuildContext context) {
    final mojianshi = outputs.mojianshi;
    final actualHours = outputs.actualHours;
    final equipDrops = outputs.equipmentDrops;
    final hasReward = mojianshi > 0 || equipDrops.isNotEmpty;

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
                for (final eq in equipDrops)
                  _RewardRow(
                    icon: Icons.sports_martial_arts,
                    label: eq.defId,
                  ),
              ],

              const Spacer(),

              // 返回按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
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
