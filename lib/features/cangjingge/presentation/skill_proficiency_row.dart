import 'package:flutter/material.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_proficiency.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/meridian_bar.dart';

/// 招式熟练度展示行（藏经阁主屏 · P1b Task7）。
///
/// 显示一条招式的当前熟练阶段名、进度条、伤害加成%、
/// 距下一阶所需次数，以及是否已装配标记。
/// 无状态组件，由上层传入所有数据。
class SkillProficiencyRow extends StatelessWidget {
  /// 招式定义（提供 `name`）。
  final SkillDef skill;

  /// 当前使用次数（来自 `Technique.skillUsageCount`）。
  final int uses;

  /// 全局熟练度阶段配置（来自 `NumbersConfig.skillProficiency`）。
  final SkillProficiencyConfig cfg;

  /// 是否已装配到出战槽位。
  final bool equipped;

  /// 点击整行的回调（T6 武学库直接装配入口）。null = 不可点（纯展示）。
  final VoidCallback? onTap;

  const SkillProficiencyRow({
    super.key,
    required this.skill,
    required this.uses,
    required this.cfg,
    required this.equipped,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stages = cfg.stages;
    final stage = SkillProficiency.stageFor(uses, cfg);
    final stageIdx = stages.indexWhere((s) => s.id == stage.id);
    final isMax = stageIdx == stages.length - 1;

    // 进度条比值
    final double ratio;
    final String? needText;
    if (isMax) {
      ratio = 1.0;
      needText = null; // 最高阶不显示
    } else {
      final nextStage = stages[stageIdx + 1];
      final rangeStart = stage.minUses;
      final rangeEnd = nextStage.minUses;
      ratio = ((uses - rangeStart) / (rangeEnd - rangeStart)).clamp(0.0, 1.0);
      needText = UiStrings.cangjingProficiencyNeed(nextStage.minUses - uses);
    }

    final damageMult = SkillProficiency.damageMultFor(uses, cfg);
    final bonusPct = ((damageMult - 1.0) * 100).round();
    final stageName = UiStrings.cangjingProficiencyStageName(stage.id);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 第一行：招名 + 阶段名 + 装配标记
            Row(
              children: [
                Expanded(
                  child: Text(
                    skill.name,
                    style: const TextStyle(
                      color: WuxiaUi.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  stageName,
                  style: const TextStyle(color: WuxiaUi.qing, fontSize: 12),
                ),
                if (equipped) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: WuxiaUi.qing,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      UiStrings.cangjingEquippedTag,
                      style: TextStyle(color: WuxiaUi.paper, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // 第二行：进度条
            MeridianBar(ratio: ratio),
            const SizedBox(height: 3),
            // 第三行：加成% + 还需次数（最高阶则只显示加成）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '+$bonusPct%',
                  style: const TextStyle(color: WuxiaUi.muted, fontSize: 11),
                ),
                if (needText != null)
                  Text(
                    needText,
                    style: TextStyle(
                      color: WuxiaUi.ink.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  )
                else
                  const Text(
                    UiStrings.cangjingProficiencyMaxStage,
                    style: TextStyle(color: WuxiaUi.gold, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
