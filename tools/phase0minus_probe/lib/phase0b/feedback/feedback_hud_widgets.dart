/// Reusable, restrained ink-wash HUD components for the Phase 0B feedback
/// draft. Pure presentation: every widget is driven by constructor
/// parameters and knows nothing about gameplay, AI, or Boss logic.
///
/// Palette follows the frozen Phase 0B visual language: paper, ink, muted
/// teal; cinnabar is reserved for the danger telegraph only.
library;

import 'package:flutter/material.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_cues.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_loot.dart';

/// Paper panel background used by every draft HUD surface.
const hudPaperColor = Color(0xCCEEE6D2);

/// Primary ink text and stroke color.
const hudInkColor = Color(0xFF252D29);

/// Muted dark red for the health meter (not cinnabar).
const hudHealthColor = Color(0xFF672D2A);

/// Muted teal for the resource meter.
const hudResourceColor = Color(0xFF3F6159);

/// Cinnabar accent. Reserved for the danger telegraph; do not reuse for
/// ordinary meters or text.
const hudDangerColor = Color(0xFF8A332E);

/// A labeled horizontal meter (health / resource).
final class FeedbackMeter extends StatelessWidget {
  const FeedbackMeter({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 32,
        child: Text(
          label,
          style: const TextStyle(color: hudInkColor, fontSize: 11),
        ),
      ),
      SizedBox(
        width: 200,
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 9,
          color: color,
          backgroundColor: const Color(0x44252D29),
        ),
      ),
    ],
  );
}

/// Small plaque showing the current martial style.
final class StylePlaque extends StatelessWidget {
  const StylePlaque({required this.style, super.key});

  final FeedbackStyle style;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: hudInkColor.withValues(alpha: 0.55)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        'style · ${style.name}',
        style: const TextStyle(color: hudInkColor, fontSize: 11),
      ),
    ),
  );
}

/// Row of pips for the Boss phase display; filled pips mark phases
/// already reached, the current phase included.
final class BossPhasePips extends StatelessWidget {
  const BossPhasePips({required this.phase, required this.total, super.key});

  final int phase;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('boss', style: TextStyle(color: hudInkColor, fontSize: 11)),
      const SizedBox(width: 6),
      for (var index = 1; index <= total; index++)
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= phase ? hudInkColor : const Color(0x33252D29),
          ),
        ),
    ],
  );
}

/// Cinnabar banner shown only while a danger telegraph is active.
final class DangerTelegraphBanner extends StatelessWidget {
  const DangerTelegraphBanner({required this.level, super.key});

  final FeedbackDanger level;

  @override
  Widget build(BuildContext context) {
    if (level == FeedbackDanger.none) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hudPaperColor,
        border: Border.all(color: hudDangerColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          level == FeedbackDanger.imminent ? 'DANGER · BREAK NOW' : 'danger',
          style: const TextStyle(
            color: hudDangerColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Terminal overlay panel for victory / defeat.
final class EndStatePanel extends StatelessWidget {
  const EndStatePanel({required this.endState, this.onReset, super.key});

  final FeedbackEndState endState;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    if (endState == FeedbackEndState.none) return const SizedBox.shrink();
    final victory = endState == FeedbackEndState.victory;
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hudPaperColor,
          border: Border.all(color: hudInkColor.withValues(alpha: 0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                victory ? 'VICTORY' : 'DEFEAT',
                style: TextStyle(
                  color: victory ? hudInkColor : hudHealthColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: hudInkColor,
                  side: const BorderSide(color: hudInkColor),
                ),
                onPressed: onReset,
                child: const Text('RESET (R)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-right feed of in-memory loot drops, newest last.
final class LootFeedView extends StatelessWidget {
  const LootFeedView({required this.entries, super.key});

  final List<LootEntry> entries;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: hudPaperColor),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'loot · memory only',
            style: TextStyle(color: hudInkColor, fontSize: 11),
          ),
          const SizedBox(height: 4),
          if (entries.isEmpty)
            const Text('—', style: TextStyle(color: hudInkColor, fontSize: 12))
          else
            for (final entry in entries)
              Text(
                '#${entry.sequence} ${entry.label} · ${entry.kind.name}',
                style: const TextStyle(color: hudInkColor, fontSize: 12),
              ),
        ],
      ),
    ),
  );
}

/// Small log of recently triggered cues so the mute audio contract stays
/// observable on screen.
final class CueLogView extends StatelessWidget {
  const CueLogView({required this.cues, super.key});

  final List<FeedbackCue> cues;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: hudPaperColor),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'cues · silent sink',
            style: TextStyle(color: hudInkColor, fontSize: 11),
          ),
          const SizedBox(height: 4),
          if (cues.isEmpty)
            const Text('—', style: TextStyle(color: hudInkColor, fontSize: 12))
          else
            for (final cue in cues)
              Text(
                cue.name,
                style: const TextStyle(color: hudInkColor, fontSize: 12),
              ),
        ],
      ),
    ),
  );
}
