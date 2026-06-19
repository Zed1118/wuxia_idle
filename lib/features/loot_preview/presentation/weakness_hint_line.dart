// lib/features/loot_preview/presentation/weakness_hint_line.dart
import 'package:flutter/material.dart';

import '../../../data/defs/stage_def.dart';
import '../../../shared/theme/colors.dart';
import '../domain/weakness_hint.dart';

/// 第七阶段批二②：通关后战前「弱点/抗性」提示行（drop_rumor LootSummaryLine 兄弟）。
///
/// 仅 [cleared]==true 且 Boss 配了 schoolDamageTakenMult 时渲染；否则 shrink（§5.7
/// 未通关不显 + 无弱点配置不显）。每条派生行（似惧 X 路数 / X 路难伤）一行水墨小字。
class WeaknessHintLine extends StatelessWidget {
  const WeaknessHintLine({
    super.key,
    required this.enemyTeam,
    required this.cleared,
  });

  final List<EnemyDef> enemyTeam;
  final bool cleared;

  @override
  Widget build(BuildContext context) {
    final lines = weaknessHintLines(enemyTeam, cleared: cleared);
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: WuxiaColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}
