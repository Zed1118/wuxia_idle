import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_cues.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_loot.dart';

void main() {
  group('cueForEvent mapping table', () {
    final cases = <(FeedbackEvent, FeedbackCue?)>{
      (const EnemyHit(heavy: false), FeedbackCue.lightStrike),
      (const EnemyHit(heavy: true), FeedbackCue.heavyStrike),
      (const PlayerDamaged(0.1), FeedbackCue.playerHurt),
      (const ResourceAdjusted(0.2), null),
      (const ResourceAdjusted(-0.2), null),
      (const StylePresented(FeedbackStyle.agile), null),
      (const DangerPresented(FeedbackDanger.none), null),
      (
        const DangerPresented(FeedbackDanger.telegraph),
        FeedbackCue.dangerTelegraph,
      ),
      (
        const DangerPresented(FeedbackDanger.imminent),
        FeedbackCue.dangerTelegraph,
      ),
      (const DangerResolved(broken: true), FeedbackCue.breakSuccess),
      (const DangerResolved(broken: false), null),
      (
        const BossPhasePresented(phase: 2, total: 3),
        FeedbackCue.bossPhaseShift,
      ),
      (
        const LootPresented(label: 'silver taels', kind: LootKind.currency),
        FeedbackCue.lootArrived,
      ),
      (const BattleConcluded(FeedbackEndState.victory), FeedbackCue.victory),
      (const BattleConcluded(FeedbackEndState.defeat), FeedbackCue.defeat),
      (const BattleConcluded(FeedbackEndState.none), null),
      (const BattleReset(), null),
    };

    for (final (event, expected) in cases) {
      test('${event.runtimeType} maps to $expected', () {
        expect(cueForEvent(event), expected);
      });
    }
  });

  test('mapping is deterministic across repeated and equal events', () {
    const event = DangerResolved(broken: true);
    expect(cueForEvent(event), cueForEvent(event));
    expect(cueForEvent(event), cueForEvent(const DangerResolved(broken: true)));

    final first = cueForEvent(const EnemyHit(heavy: true));
    for (var index = 0; index < 50; index++) {
      expect(cueForEvent(const EnemyHit(heavy: true)), first);
    }
  });

  test('silent sink plays nothing but stays observable', () {
    final observed = <FeedbackCue>[];
    final sink = SilentFeedbackCueSink(onCue: observed.add);

    sink.emit(FeedbackCue.lightStrike);
    sink.emit(FeedbackCue.victory);

    expect(sink.emittedCount, 2);
    expect(observed, [FeedbackCue.lightStrike, FeedbackCue.victory]);

    // The mute default has no tap and still accepts cues.
    final plain = SilentFeedbackCueSink();
    plain.emit(FeedbackCue.defeat);
    expect(plain.emittedCount, 1);
  });
}
