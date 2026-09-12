import 'action_timeline.dart';
import 'phase0a_combat_intent.dart';

/// Accepted input and immutable action cursor travel with the player on forks.
final class Phase0aBasicActionSnapshot {
  const Phase0aBasicActionSnapshot({
    required this.intent,
    required this.timeline,
    required this.startedTick,
    required this.actionId,
  });
  final Phase0aAttackIntent intent;
  final ActionTimelineSnapshot timeline;
  final int startedTick;
  final String actionId;

  Phase0aBasicActionSnapshot withTimeline(ActionTimelineSnapshot value) =>
      Phase0aBasicActionSnapshot(
        intent: intent,
        timeline: value,
        startedTick: startedTick,
        actionId: actionId,
      );

  @override
  bool operator ==(Object other) =>
      other is Phase0aBasicActionSnapshot &&
      intent == other.intent &&
      timeline == other.timeline &&
      startedTick == other.startedTick &&
      actionId == other.actionId;
  @override
  int get hashCode => Object.hash(intent, timeline, startedTick, actionId);
}
