/// Reusable, read-only HUD view for the Phase 0B feedback slice.
///
/// This is the presentation boundary a future gameplay mode drops in: hand
/// it the immutable [FeedbackHudState] view model and an optional reset
/// callback. The view holds no controller reference and cannot emit
/// events; the controller's only input boundary stays
/// `FeedbackHudController.apply`.
///
/// Responsive: below the comfortable desktop envelope (see
/// [hudCompactMaxWidth] / [hudCompactMaxHeight]) the HUD switches to a
/// compact variant — narrower meter bars, tighter panel padding — so
/// 1280x720 stays overflow-free while 1440x900 keeps comfortable spacing.
/// Palette stays restrained ink-wash; cinnabar remains reserved for the
/// danger telegraph.
library;

import 'package:flutter/material.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_state.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_widgets.dart';

/// Maximum layout width that still counts as the comfortable envelope.
const hudCompactMaxWidth = 1320.0;

/// Maximum layout height that still counts as the comfortable envelope.
const hudCompactMaxHeight = 800.0;

/// Read-only HUD view: status panel (top-left), cue log (top-right),
/// loot feed (bottom-right), and the terminal end panel overlay.
final class FeedbackHud extends StatelessWidget {
  const FeedbackHud({required this.state, this.onReset, super.key});

  /// The read-only view model to render.
  final FeedbackHudState state;

  /// Invoked when the player activates reset on the end panel. Null when
  /// no reset affordance should run (pure observation).
  final VoidCallback? onReset;

  /// Whether [size] falls into the compact variant. 1280x720 is compact;
  /// 1440x900 is comfortable.
  static bool isCompact(Size size) =>
      size.width < hudCompactMaxWidth || size.height < hudCompactMaxHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = isCompact(constraints.biggest);
      return Stack(
        children: [
          Positioned(
            left: 18,
            top: 14,
            child: IgnorePointer(
              child: _StatusPanel(state: state, compact: compact),
            ),
          ),
          Positioned(
            right: 18,
            top: 14,
            child: IgnorePointer(child: CueLogView(cues: state.recentCues)),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: IgnorePointer(child: LootFeedView(entries: state.loot)),
          ),
          if (state.endState != FeedbackEndState.none)
            Positioned.fill(
              child: EndStatePanel(endState: state.endState, onReset: onReset),
            ),
        ],
      );
    },
  );
}

/// Meters, style plaque, Boss phase pips, and the danger telegraph.
final class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.state, required this.compact});

  final FeedbackHudState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final barWidth = compact ? 150.0 : 200.0;
    return DecoratedBox(
      decoration: const BoxDecoration(color: hudPaperColor),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FeedbackMeter(
              key: const ValueKey('meter-hp'),
              label: 'HP',
              value: state.health,
              color: hudHealthColor,
              barWidth: barWidth,
            ),
            const SizedBox(height: 6),
            FeedbackMeter(
              key: const ValueKey('meter-resource'),
              label: 'QI',
              value: state.resource,
              color: hudResourceColor,
              barWidth: barWidth,
            ),
            const SizedBox(height: 10),
            StylePlaque(style: state.style),
            const SizedBox(height: 8),
            BossPhasePips(phase: state.bossPhase, total: state.bossPhaseTotal),
            const SizedBox(height: 8),
            DangerTelegraphBanner(level: state.danger),
          ],
        ),
      ),
    );
  }
}
