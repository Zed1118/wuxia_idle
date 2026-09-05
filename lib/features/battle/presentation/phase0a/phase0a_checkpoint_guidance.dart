import 'package:flutter/material.dart';

import '../../../../data/narrative_loader.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../../application/phase0a/phase0a_checkpoint_objective_observation.dart';
import '../../domain/phase0a/arena_vector.dart';
import 'phase0a_presentation_tokens.dart';
import 'phase0a_stage.dart';

final class Phase0aCheckpointGuidanceCopy {
  const Phase0aCheckpointGuidanceCopy({
    required this.exitLabel,
    required this.inCombat,
    required this.roadCleared,
    required this.exitReached,
  });

  static Phase0aCheckpointGuidanceCopy? fromNarrative(
    NarrativeContent content,
  ) {
    if (content.isPlaceholder ||
        content.title == null ||
        content.title!.trim().isEmpty ||
        content.paragraphs.length != 3 ||
        content.paragraphs.any((line) => line.trim().isEmpty)) {
      return null;
    }
    return Phase0aCheckpointGuidanceCopy(
      exitLabel: content.title!,
      inCombat: content.paragraphs[0],
      roadCleared: content.paragraphs[1],
      exitReached: content.paragraphs[2],
    );
  }

  final String exitLabel;
  final String inCombat;
  final String roadCleared;
  final String exitReached;
}

/// Shows the actual checkpoint without driving movement or changing victory.
final class Phase0aCheckpointGuidance extends StatelessWidget {
  const Phase0aCheckpointGuidance({
    super.key,
    required this.progress,
    required this.checkpointXById,
    required this.copy,
    required this.stage,
    required this.playerPosition,
  });

  final Phase0aCheckpointObjectiveObservation progress;
  final Map<String, double> checkpointXById;
  final Phase0aCheckpointGuidanceCopy copy;
  final Phase0aStage stage;
  final ArenaVector playerPosition;

  @override
  Widget build(BuildContext context) {
    final label = progress.reached
        ? copy.exitReached
        : progress.remainingEnemies == 0
        ? copy.roadCleared
        : copy.inCombat;
    final pending = progress.checkpoints.entries.where((entry) => !entry.value);
    final targetX = pending.isEmpty ? null : checkpointXById[pending.first.key];
    final target = targetX == null
        ? null
        : stage.worldToScreen(ArenaVector(targetX, playerPosition.y));
    const markerWidth = Phase0aPresentationTokens.checkpointMarkerWidth;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: Phase0aPresentationTokens.hudInset,
            left: Phase0aPresentationTokens.hudInset,
            right: Phase0aPresentationTokens.hudInset,
            child: Align(
              alignment: Alignment.topLeft,
              child: _PaperLabel(
                key: const ValueKey('phase0a_checkpoint_condition_banner'),
                label: label,
              ),
            ),
          ),
          if (target != null)
            Positioned(
              left: (target.dx - markerWidth / 2).clamp(
                stage.safeRect.left,
                stage.safeRect.right - markerWidth,
              ),
              top: stage.safeRect.top,
              width: markerWidth,
              child: _PaperLabel(
                key: const ValueKey('phase0a_checkpoint_exit_marker'),
                label: copy.exitLabel,
                arrow: targetX! >= playerPosition.x
                    ? Icons.arrow_forward
                    : Icons.arrow_back,
              ),
            ),
        ],
      ),
    );
  }
}

final class _PaperLabel extends StatelessWidget {
  const _PaperLabel({super.key, required this.label, this.arrow});

  final String label;
  final IconData? arrow;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(
          alpha: Phase0aPresentationTokens.hudPaperOpacity,
        ),
        border: Border.all(color: WuxiaUi.gold),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Phase0aPresentationTokens.hudGap),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label, style: const TextStyle(color: WuxiaUi.ink)),
            ),
            if (arrow != null) Icon(arrow, color: WuxiaUi.ink),
          ],
        ),
      ),
    ),
  );
}
