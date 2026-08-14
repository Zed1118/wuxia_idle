/// Semantic presentation events for the Phase 0B feedback draft.
///
/// This is a pure presentation contract: a future gameplay slice (Qoder)
/// emits these events, the HUD state machine consumes them. No AI, Boss,
/// or style gameplay logic lives here, and nothing here is wired to the
/// production battle, drop, or reward pipeline.
library;

import 'package:phase0minus_probe/phase0b/feedback/feedback_loot.dart';

/// Martial style shown on the HUD plaque. Names follow the GDD vocabulary
/// (rigid / agile / sinister) instead of inventing new terms.
enum FeedbackStyle { rigid, agile, sinister }

/// Danger telegraph level. Cinnabar accents may only appear while this is
/// not [none], per the frozen Phase 0B visual language.
enum FeedbackDanger { none, telegraph, imminent }

/// Terminal state of the draft battle presentation.
enum FeedbackEndState { none, victory, defeat }

/// Base type for every presentation event the draft HUD understands.
sealed class FeedbackEvent {
  const FeedbackEvent();
}

/// The player landed an attack on an enemy. Cue-only; carries no numbers.
final class EnemyHit extends FeedbackEvent {
  const EnemyHit({required this.heavy});

  final bool heavy;
}

/// The player took damage, expressed as a fraction of max health.
final class PlayerDamaged extends FeedbackEvent {
  const PlayerDamaged(this.fraction);

  final double fraction;
}

/// The combat resource (qi stand-in) changed by [delta] in the range
/// -1.0 … 1.0 of its maximum.
final class ResourceAdjusted extends FeedbackEvent {
  const ResourceAdjusted(this.delta);

  final double delta;
}

/// The displayed martial style changed.
final class StylePresented extends FeedbackEvent {
  const StylePresented(this.style);

  final FeedbackStyle style;
}

/// A danger telegraph appeared, escalated, or cleared.
final class DangerPresented extends FeedbackEvent {
  const DangerPresented(this.level);

  final FeedbackDanger level;
}

/// A danger telegraph ended; [broken] marks a successful player break.
final class DangerResolved extends FeedbackEvent {
  const DangerResolved({required this.broken});

  final bool broken;
}

/// The Boss phase display moved to [phase] (1-based) out of [total].
final class BossPhasePresented extends FeedbackEvent {
  const BossPhasePresented({required this.phase, required this.total});

  final int phase;
  final int total;
}

/// A loot drop should be shown. Display-only: the entry lives in memory
/// and never reaches the production drop or reward pipeline.
final class LootPresented extends FeedbackEvent {
  const LootPresented({required this.label, required this.kind});

  final String label;
  final LootKind kind;
}

/// The battle ended. [result] must be victory or defeat, never none.
final class BattleConcluded extends FeedbackEvent {
  const BattleConcluded(this.result);

  final FeedbackEndState result;
}

/// Return the draft to its initial presentation state.
final class BattleReset extends FeedbackEvent {
  const BattleReset();
}
