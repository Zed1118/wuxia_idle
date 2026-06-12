import 'package:flutter/material.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_proficiency.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/stage_progress_row.dart';

/// 招式熟练度展示行（藏经阁主屏 · P1b Task7）。
///
/// 显示一条招式的当前熟练阶段名、进度条、伤害加成%、
/// 距下一阶所需次数，以及是否已装配标记。
/// 无状态组件，由上层传入所有数据。
///
/// D（2026-06-12）重构：布局委托给共享基元 [StageProgressRow]，
/// 与修炼度 / 共鸣度统一「五要素」展示语言；本类只保留熟练度计算映射。
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

    return StageProgressRow(
      title: skill.name,
      stageName: stageName,
      ratio: ratio,
      currentEffect: '+$bonusPct%',
      // 最高阶：金字「已达化境」标记；否则：柔灰「还需 N 次」。
      nextEffect: isMax ? UiStrings.cangjingProficiencyMaxStage : null,
      progressText: needText,
      tag: equipped ? UiStrings.cangjingEquippedTag : null,
      tagHighlighted: true,
      onTap: onTap,
    );
  }
}
