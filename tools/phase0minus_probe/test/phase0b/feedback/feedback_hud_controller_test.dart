import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_cues.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_state.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_loot.dart';

void main() {
  group('HUD state transitions', () {
    test('damage lowers health and clamps at zero floor', () {
      final controller = FeedbackHudController();
      controller.apply(const PlayerDamaged(0.3));
      expect(controller.value.health, closeTo(0.7, 0.0001));
      expect(controller.value.endState, FeedbackEndState.none);
      expect(controller.value.recentCues, [FeedbackCue.playerHurt]);
      controller.dispose();
    });

    test('lethal damage concludes with defeat and defeat cue', () {
      final controller = FeedbackHudController();
      controller.apply(const PlayerDamaged(1.5));
      expect(controller.value.health, 0);
      expect(controller.value.endState, FeedbackEndState.defeat);
      expect(controller.value.recentCues, [FeedbackCue.defeat]);
      controller.dispose();
    });

    test('resource adjusts and clamps into 0..1', () {
      final controller = FeedbackHudController();
      controller.apply(const ResourceAdjusted(0.5));
      expect(controller.value.resource, closeTo(0.9, 0.0001));
      controller.apply(const ResourceAdjusted(0.5));
      expect(controller.value.resource, 1);
      controller.apply(const ResourceAdjusted(-2));
      expect(controller.value.resource, 0);
      // Silent events leave the cue log untouched.
      expect(controller.value.recentCues, isEmpty);
      controller.dispose();
    });

    test('style and danger presentations update the state', () {
      final controller = FeedbackHudController();
      controller.apply(const StylePresented(FeedbackStyle.sinister));
      expect(controller.value.style, FeedbackStyle.sinister);

      controller.apply(const DangerPresented(FeedbackDanger.telegraph));
      expect(controller.value.danger, FeedbackDanger.telegraph);
      expect(controller.value.recentCues, [FeedbackCue.dangerTelegraph]);

      controller.apply(const DangerResolved(broken: true));
      expect(controller.value.danger, FeedbackDanger.none);
      expect(controller.value.recentCues.last, FeedbackCue.breakSuccess);
      controller.dispose();
    });

    test('boss phase clamps into its total', () {
      final controller = FeedbackHudController();
      controller.apply(const BossPhasePresented(phase: 9, total: 4));
      expect(controller.value.bossPhase, 4);
      expect(controller.value.bossPhaseTotal, 4);
      expect(
        () => controller.apply(const BossPhasePresented(phase: 1, total: 0)),
        throwsArgumentError,
      );
      controller.dispose();
    });

    test('end state is terminal until reset', () {
      final controller = FeedbackHudController();
      controller.apply(const BattleConcluded(FeedbackEndState.victory));
      expect(controller.value.endState, FeedbackEndState.victory);

      controller.apply(const PlayerDamaged(0.9));
      controller.apply(const LootPresented(label: 'x', kind: LootKind.gear));
      expect(controller.value.health, 1);
      expect(controller.value.loot, isEmpty);
      expect(controller.value.endState, FeedbackEndState.victory);

      controller.apply(const BattleReset());
      expect(controller.value.endState, FeedbackEndState.none);
      expect(controller.value.health, 1);
      expect(controller.value.recentCues, isEmpty);
      controller.dispose();
    });

    test('battle conclusion rejects a none result', () {
      final controller = FeedbackHudController();
      expect(
        () => controller.apply(const BattleConcluded(FeedbackEndState.none)),
        throwsArgumentError,
      );
      controller.dispose();
    });

    test('cue log stays bounded in emission order', () {
      final controller = FeedbackHudController();
      for (var index = 0; index < recentCueLimit + 3; index++) {
        controller.apply(const EnemyHit(heavy: false));
      }
      expect(controller.value.recentCues.length, recentCueLimit);
      expect(
        controller.value.recentCues.every(
          (cue) => cue == FeedbackCue.lightStrike,
        ),
        isTrue,
      );
      controller.dispose();
    });

    test('cues reach the injected sink as well as the HUD log', () {
      final sink = SilentFeedbackCueSink();
      final controller = FeedbackHudController(cueSink: sink);
      controller.apply(const EnemyHit(heavy: true));
      controller.apply(const DangerPresented(FeedbackDanger.imminent));
      expect(sink.emittedCount, 2);
      expect(controller.value.recentCues, [
        FeedbackCue.heavyStrike,
        FeedbackCue.dangerTelegraph,
      ]);
      controller.dispose();
    });
  });

  group('input contract', () {
    test('damage fraction must be finite and non-negative', () {
      final controller = FeedbackHudController();
      for (final bad in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
        -0.1,
      ]) {
        expect(
          () => controller.apply(PlayerDamaged(bad)),
          throwsArgumentError,
          reason: 'fraction $bad must be rejected',
        );
      }
      // Rejected inputs left the view model untouched.
      expect(controller.value.health, 1);
      expect(controller.value.endState, FeedbackEndState.none);
      expect(controller.value.recentCues, isEmpty);
      controller.dispose();
    });

    test('resource delta must be finite', () {
      final controller = FeedbackHudController();
      for (final bad in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => controller.apply(ResourceAdjusted(bad)),
          throwsArgumentError,
          reason: 'delta $bad must be rejected',
        );
      }
      expect(controller.value.resource, 0.4);
      controller.dispose();
    });

    test('boss phase total and battle result validation stay intact', () {
      final controller = FeedbackHudController();
      expect(
        () => controller.apply(const BossPhasePresented(phase: 1, total: 0)),
        throwsArgumentError,
      );
      expect(
        () => controller.apply(const BattleConcluded(FeedbackEndState.none)),
        throwsArgumentError,
      );
      controller.dispose();
    });
  });

  group('read-only view model', () {
    test('state collections are unmodifiable', () {
      final controller = FeedbackHudController();
      controller.apply(const EnemyHit(heavy: false));
      controller.apply(const LootPresented(label: 'x', kind: LootKind.gear));

      final state = controller.value;
      expect(
        () => state.recentCues.add(FeedbackCue.victory),
        throwsUnsupportedError,
      );
      expect(() => state.loot.add(state.loot.first), throwsUnsupportedError);
      controller.dispose();
    });

    test('initial state collections are unmodifiable and empty', () {
      final state = FeedbackHudState.initial();
      expect(state.loot, isEmpty);
      expect(state.recentCues, isEmpty);
      expect(
        () => state.recentCues.add(FeedbackCue.defeat),
        throwsUnsupportedError,
      );
    });
  });
}
