import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../loot_preview/domain/drop_name_resolver.dart';
import '../../loot_preview/domain/drop_rumor.dart';
import '../application/new_save_goal_guidance.dart';

abstract final class NewSaveGoalText {
  static String target(NewSaveGoalGuidance guidance) =>
      UiStrings.stageGoalTarget(
        guidance.chapterIndex,
        guidance.stageIndex,
        guidance.stage.name,
      );

  static String reward(NewSaveGoalGuidance guidance) {
    final reps = guidance.rumorTable.topRepresentatives(1);
    if (reps.isNotEmpty) return _dropName(reps.first);
    if (guidance.stage.dropSkillManualId != null) {
      return UiStrings.stageGoalRewardSkillManual;
    }
    return UiStrings.stageGoalRewardProgress;
  }

  static String reason(NewSaveGoalGuidance guidance) {
    return switch (guidance.reason) {
      NewSaveGoalReason.firstClearBoss => UiStrings.stageGoalReasonBoss,
      NewSaveGoalReason.learnSkill => UiStrings.stageGoalReasonSkill,
      NewSaveGoalReason.getEquipment => UiStrings.stageGoalReasonEquipment,
      NewSaveGoalReason.gatherMaterial => UiStrings.stageGoalReasonMaterial,
      NewSaveGoalReason.continueJourney => UiStrings.stageGoalReasonProgress,
    };
  }

  static String mainMenuHint(NewSaveGoalGuidance guidance) =>
      UiStrings.mainMenuMainlineGoalHint(
        target(guidance),
        reward(guidance),
        reason(guidance),
      );

  static String line(NewSaveGoalGuidance guidance) =>
      UiStrings.stageGoalGuidanceLine(
        target(guidance),
        reward(guidance),
        reason(guidance),
      );

  static String _dropName(DropRumorEntry entry) => entry.isEquipment
      ? DropNameResolver.equipmentName(entry.defId)
      : DropNameResolver.itemName(entry.defId);
}

class NewSaveGoalHintLine extends StatelessWidget {
  const NewSaveGoalHintLine({
    super.key,
    required this.guidance,
    this.padding = const EdgeInsets.only(top: 5),
  });

  final NewSaveGoalGuidance guidance;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${UiStrings.stageGoalGuidanceTitle} · '
          '${NewSaveGoalText.line(guidance)}',
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.assistant_direction_outlined,
                size: 13,
                color: WuxiaColors.resultHighlight,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                NewSaveGoalText.line(guidance),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WuxiaColors.resultHighlight,
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
