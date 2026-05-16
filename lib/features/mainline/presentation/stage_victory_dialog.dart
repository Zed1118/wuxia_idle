import 'package:flutter/material.dart';

import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../ui/strings.dart';
import '../../../ui/theme/colors.dart';
import '../../cultivation/presentation/advancement_summary.dart';
import '../../equipment/application/drop_service.dart';

/// 主线 victory dialog(W15 #30 P3 后续 A 任务)。
///
/// 体例对齐塔 `_showVictoryDialog`,但主线 victory 此前完全无 dialog,本批新建。
/// content = drop 列表 + [AdvancementSummary](升层多角色 banner)。
/// dialog 关闭后由 caller 继续 push `NarrativeReaderScreen` 显胜利剧情。
Future<void> showStageVictoryDialog({
  required BuildContext context,
  required StageDef stage,
  required DropResult drops,
  required List<AdvancementEntry> advancements,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text('${stage.name} · ${UiStrings.stageVictoryTitle}'),
      content: StageVictoryContent(drops: drops, advancements: advancements),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(UiStrings.stageVictoryConfirm),
        ),
      ],
    ),
  );
}

/// dialog content widget(公开便于 widget test 直接 pump,无需走 showDialog)。
class StageVictoryContent extends StatelessWidget {
  const StageVictoryContent({
    super.key,
    required this.drops,
    required this.advancements,
  });

  final DropResult drops;
  final List<AdvancementEntry> advancements;

  @override
  Widget build(BuildContext context) {
    final dropLines = <String>[
      for (final eq in drops.equipments)
        GameRepository.isLoaded
            ? GameRepository.instance.getEquipment(eq.defId).name
            : eq.defId,
      for (final item in drops.items) '${item.defId} ×${item.quantity}',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(UiStrings.stageVictoryDropLabel),
        const SizedBox(height: 4),
        if (drops.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              UiStrings.stageVictoryNoDrop,
              style: TextStyle(color: WuxiaColors.textMuted),
            ),
          )
        else
          for (final line in dropLines)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('· $line'),
            ),
        if (advancements.any((e) => e.result.didAdvance)) ...[
          const SizedBox(height: 12),
          AdvancementSummary(entries: advancements),
        ],
      ],
    );
  }
}
