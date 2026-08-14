/// Presentation state machine for the Phase 0B feedback draft HUD.
///
/// The controller consumes semantic [FeedbackEvent]s and exposes a single
/// immutable [FeedbackHudState] through [ValueNotifier]. It deliberately
/// knows nothing about enemy AI, Boss mechanics, or style gameplay; those
/// belong to a separate gameplay slice that will emit these events.
library;

import 'package:flutter/foundation.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_cues.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_loot.dart';

/// How many recent cues the HUD keeps visible for cue observability.
const recentCueLimit = 5;

/// Immutable snapshot of everything the draft HUD renders.
final class FeedbackHudState {
  const FeedbackHudState({
    required this.health,
    required this.resource,
    required this.style,
    required this.bossPhase,
    required this.bossPhaseTotal,
    required this.danger,
    required this.endState,
    required this.loot,
    required this.recentCues,
  });

  /// Initial presentation state: full health, modest opening resource
  /// (mirrors the "opening qi below maximum" idea without borrowing
  /// production numbers), rigid style, phase 1 of 3, no danger, no end.
  factory FeedbackHudState.initial() => const FeedbackHudState(
    health: 1,
    resource: 0.4,
    style: FeedbackStyle.rigid,
    bossPhase: 1,
    bossPhaseTotal: 3,
    danger: FeedbackDanger.none,
    endState: FeedbackEndState.none,
    loot: <LootEntry>[],
    recentCues: <FeedbackCue>[],
  );

  /// Remaining health fraction, always within 0.0 … 1.0.
  final double health;

  /// Remaining resource fraction, always within 0.0 … 1.0.
  final double resource;

  /// Currently displayed martial style.
  final FeedbackStyle style;

  /// Current Boss phase, 1-based and clamped to [bossPhaseTotal].
  final int bossPhase;

  /// Total Boss phases shown by the pips.
  final int bossPhaseTotal;

  /// Active danger telegraph level.
  final FeedbackDanger danger;

  /// Terminal state; once non-none, only [BattleReset] is accepted.
  final FeedbackEndState endState;

  /// In-memory loot feed snapshot, oldest first.
  final List<LootEntry> loot;

  /// Last few cues emitted, oldest first, for UI observability.
  final List<FeedbackCue> recentCues;

  FeedbackHudState copyWith({
    double? health,
    double? resource,
    FeedbackStyle? style,
    int? bossPhase,
    int? bossPhaseTotal,
    FeedbackDanger? danger,
    FeedbackEndState? endState,
    List<LootEntry>? loot,
    List<FeedbackCue>? recentCues,
  }) => FeedbackHudState(
    health: health ?? this.health,
    resource: resource ?? this.resource,
    style: style ?? this.style,
    bossPhase: bossPhase ?? this.bossPhase,
    bossPhaseTotal: bossPhaseTotal ?? this.bossPhaseTotal,
    danger: danger ?? this.danger,
    endState: endState ?? this.endState,
    loot: loot ?? this.loot,
    recentCues: recentCues ?? this.recentCues,
  );
}

/// Drives the draft HUD. Cues are forwarded to a [FeedbackCueSink] that
/// defaults to the mute [SilentFeedbackCueSink].
final class FeedbackHudController extends ValueNotifier<FeedbackHudState> {
  FeedbackHudController({FeedbackCueSink? cueSink, int lootCapacity = 6})
    : _cueSink = cueSink ?? SilentFeedbackCueSink(),
      _lootFeed = LootFeed(capacity: lootCapacity),
      super(FeedbackHudState.initial());

  final FeedbackCueSink _cueSink;
  final LootFeed _lootFeed;

  /// Sink actually in use, exposed so tests and the app can observe cues.
  FeedbackCueSink get cueSink => _cueSink;

  /// Apply one presentation event. After victory or defeat every event
  /// except [BattleReset] is ignored, keeping the end panel stable.
  void apply(FeedbackEvent event) {
    if (value.endState != FeedbackEndState.none && event is! BattleReset) {
      return;
    }
    switch (event) {
      case EnemyHit():
        // Cue-only: hit feedback carries no HUD number changes.
        break;
      case PlayerDamaged(:final fraction):
        final remaining = (value.health - fraction).clamp(0.0, 1.0);
        value = value.copyWith(health: remaining);
        if (remaining <= 0) {
          // Lethal damage concludes the battle: the defeat cue replaces
          // the hurt cue so one event still yields one cue.
          value = value.copyWith(endState: FeedbackEndState.defeat);
          _emit(FeedbackCue.defeat);
          return;
        }
      case ResourceAdjusted(:final delta):
        value = value.copyWith(
          resource: (value.resource + delta).clamp(0.0, 1.0),
        );
      case StylePresented(:final style):
        value = value.copyWith(style: style);
      case DangerPresented(:final level):
        value = value.copyWith(danger: level);
      case DangerResolved():
        value = value.copyWith(danger: FeedbackDanger.none);
      case BossPhasePresented(:final phase, :final total):
        if (total < 1) {
          throw ArgumentError.value(total, 'total', 'must be >= 1');
        }
        value = value.copyWith(
          bossPhase: phase.clamp(1, total),
          bossPhaseTotal: total,
        );
      case LootPresented(:final label, :final kind):
        _lootFeed.add(label: label, kind: kind);
        value = value.copyWith(loot: _lootFeed.entries);
      case BattleConcluded(:final result):
        if (result == FeedbackEndState.none) {
          throw ArgumentError.value(
            result,
            'result',
            'must be victory or defeat',
          );
        }
        value = value.copyWith(endState: result);
      case BattleReset():
        _lootFeed.clear();
        value = FeedbackHudState.initial();
        return;
    }
    final cue = cueForEvent(event);
    if (cue != null) _emit(cue);
  }

  void _emit(FeedbackCue cue) {
    _cueSink.emit(cue);
    final recent = <FeedbackCue>[...value.recentCues, cue];
    while (recent.length > recentCueLimit) {
      recent.removeAt(0);
    }
    value = value.copyWith(recentCues: recent);
  }
}
