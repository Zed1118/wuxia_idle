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
///
/// Minimal accessibility: meters carry semantics labels/values, the danger
/// telegraph and the end panel are live regions, danger escalation and
/// battle conclusion are announced through [SemanticsService], and the
/// end panel's reset button takes keyboard focus (Enter/Space or the R
/// shortcut activate it). Focus restoration after reset is the consumer's
/// job (the draft app re-focuses its keyboard listener).
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_state.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_widgets.dart';

/// Maximum layout width that still counts as the comfortable envelope.
const hudCompactMaxWidth = 1320.0;

/// Maximum layout height that still counts as the comfortable envelope.
const hudCompactMaxHeight = 800.0;

/// Read-only HUD view: status panel (top-left), cue log (top-right),
/// loot feed (bottom-right), and the terminal end panel overlay.
final class FeedbackHud extends StatefulWidget {
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
  State<FeedbackHud> createState() => _FeedbackHudState();
}

final class _FeedbackHudState extends State<FeedbackHud> {
  @override
  void didUpdateWidget(FeedbackHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    _announceTransitions(oldWidget.state, widget.state);
  }

  /// Edge-triggered announcements: only transitions speak, and a battle
  /// conclusion outranks a simultaneous danger change.
  void _announceTransitions(FeedbackHudState old, FeedbackHudState current) {
    String? message;
    if (current.danger != old.danger) {
      if (current.danger == FeedbackDanger.telegraph) {
        message = 'Danger telegraph.';
      } else if (current.danger == FeedbackDanger.imminent) {
        message = 'Danger imminent. Break now.';
      }
    }
    if (current.endState != old.endState &&
        current.endState != FeedbackEndState.none) {
      message = current.endState == FeedbackEndState.victory
          ? 'Battle over. Victory.'
          : 'Battle over. Defeat.';
    }
    if (message == null) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = FeedbackHud.isCompact(constraints.biggest);
      final endState = widget.state.endState;
      return Stack(
        children: [
          Positioned(
            left: 18,
            top: 14,
            child: IgnorePointer(
              child: _StatusPanel(state: widget.state, compact: compact),
            ),
          ),
          Positioned(
            right: 18,
            top: 14,
            child: IgnorePointer(
              child: CueLogView(cues: widget.state.recentCues),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: IgnorePointer(
              child: LootFeedView(entries: widget.state.loot),
            ),
          ),
          if (endState != FeedbackEndState.none)
            Positioned.fill(
              child: CallbackShortcuts(
                bindings: {
                  if (widget.onReset != null)
                    const SingleActivator(LogicalKeyboardKey.keyR):
                        widget.onReset!,
                },
                child: EndStatePanel(
                  endState: endState,
                  onReset: widget.onReset,
                ),
              ),
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
