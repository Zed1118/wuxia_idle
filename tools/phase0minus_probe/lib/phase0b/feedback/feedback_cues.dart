/// Temporary audio cue contract for the Phase 0B feedback draft.
///
/// The event→cue mapping is a pure function so it can be pinned by
/// deterministic tests. The only shipped implementation is mute: it plays
/// nothing, ships no audio assets, and adds no audio dependencies. Real
/// audio is a later, separately gated decision.
library;

import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';

/// Every cue the draft HUD can ask for. Names describe the presentation
/// moment, not any concrete sound file.
enum FeedbackCue {
  lightStrike,
  heavyStrike,
  playerHurt,
  dangerTelegraph,
  breakSuccess,
  bossPhaseShift,
  lootArrived,
  victory,
  defeat,
}

/// Deterministic event→cue mapping. Pure: same event in, same cue out,
/// no state, no randomness. A `null` result means the event is silent.
FeedbackCue? cueForEvent(FeedbackEvent event) => switch (event) {
  EnemyHit(heavy: false) => FeedbackCue.lightStrike,
  EnemyHit(heavy: true) => FeedbackCue.heavyStrike,
  PlayerDamaged() => FeedbackCue.playerHurt,
  ResourceAdjusted() => null,
  StylePresented() => null,
  DangerPresented(level: FeedbackDanger.none) => null,
  DangerPresented() => FeedbackCue.dangerTelegraph,
  DangerResolved(broken: true) => FeedbackCue.breakSuccess,
  DangerResolved(broken: false) => null,
  BossPhasePresented() => FeedbackCue.bossPhaseShift,
  LootPresented() => FeedbackCue.lootArrived,
  BattleConcluded(result: FeedbackEndState.victory) => FeedbackCue.victory,
  BattleConcluded(result: FeedbackEndState.defeat) => FeedbackCue.defeat,
  BattleConcluded(result: FeedbackEndState.none) => null,
  BattleReset() => null,
};

/// Consumer of cue requests. Kept interface-small so a real audio backend
/// could later be swapped in without touching the HUD state machine.
abstract interface class FeedbackCueSink {
  void emit(FeedbackCue cue);
}

/// Mute implementation: plays nothing and owns no audio assets or
/// dependencies. The counter and optional tap exist only so the draft UI
/// and tests can observe that a cue was triggered.
final class SilentFeedbackCueSink implements FeedbackCueSink {
  SilentFeedbackCueSink({void Function(FeedbackCue cue)? onCue})
    : _onCue = onCue;

  final void Function(FeedbackCue cue)? _onCue;

  /// How many cues this sink was asked to play (and silently dropped).
  int emittedCount = 0;

  @override
  void emit(FeedbackCue cue) {
    emittedCount += 1;
    _onCue?.call(cue);
  }
}
