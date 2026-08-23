import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';

void main() {
  test('all set objectives are order independent and idempotent', () {
    final cases = <EncounterObjective, List<EncounterObjectiveEvent>>{
      DefeatTargetsObjective(const ['a', 'b']): [
        const TargetDefeated('b'),
        const TargetDefeated('a'),
        const TargetDefeated('a'),
      ],
      DestroyAnchorsObjective(const ['a', 'b']): [
        const AnchorDestroyed('b'),
        const AnchorDestroyed('a'),
        const AnchorDestroyed('b'),
      ],
      ReachCheckpointObjective(const ['a', 'b']): [
        const CheckpointReached('b'),
        const CheckpointReached('a'),
      ],
      TouchMarkersObjective(const ['a', 'b']): [
        const MarkerTouched('b'),
        const MarkerTouched('a'),
      ],
    };
    for (final entry in cases.entries) {
      var state = entry.key.initialProgress;
      for (final event in entry.value) {
        state = entry.key.advance(state, event);
      }
      expect(state.completed, isTrue);
      expect(entry.key.advance(state, entry.value.last), same(state));
    }
  });

  test('single-target and duration objectives advance deterministically', () {
    final defend = DefendEntityObjective('npc', const Duration(seconds: 3));
    var state = defend.initialProgress;
    state = defend.advance(
      state,
      EntityDefended('other', const Duration(seconds: 9), eventId: 'other'),
    );
    expect(state.elapsed, Duration.zero);
    state = defend.advance(
      state,
      EntityDefended('npc', const Duration(seconds: 2), eventId: 'defend-1'),
    );
    state = defend.advance(
      state,
      EntityDefended('npc', const Duration(seconds: 1), eventId: 'defend-2'),
    );
    expect(state.completed, isTrue);

    final survive = SurviveDurationObjective(const Duration(seconds: 3));
    state = survive.initialProgress;
    state = survive.advance(
      state,
      TimeElapsed(const Duration(seconds: 2), eventId: 'survive-1'),
    );
    state = survive.advance(
      state,
      TimeElapsed(const Duration(seconds: 1), eventId: 'survive-2'),
    );
    expect(state.completed, isTrue);
  });

  test('invalid contracts fail closed', () {
    expect(() => DefeatTargetsObjective(const []), throwsArgumentError);
    expect(() => DefeatTargetsObjective(const ['a', 'a']), throwsArgumentError);
    expect(
      () => DefendEntityObjective('', const Duration(seconds: 1)),
      throwsArgumentError,
    );
    expect(() => SurviveDurationObjective(Duration.zero), throwsArgumentError);
    expect(() => TimeElapsed(Duration.zero, eventId: 'zero'), returnsNormally);
    expect(() => TimeElapsed(Duration.zero, eventId: ''), throwsArgumentError);
  });

  test(
    'constructor collections and progress collections are immutable snapshots',
    () {
      final ids = <String>['a'];
      final objective = DefeatTargetsObjective(ids);
      ids.add('b');
      expect(objective.targetIds, {'a'});
      final state = objective.advance(
        objective.initialProgress,
        const TargetDefeated('a'),
      );
      expect(() => state.satisfied.add('x'), throwsUnsupportedError);
      expect(() => objective.targetIds.add('x'), throwsUnsupportedError);
    },
  );

  test('pursue and commander objectives require matching targets', () {
    final pursue = PursueTargetObjective('target');
    var state = pursue.advance(
      pursue.initialProgress,
      const TargetPursued('other'),
    );
    expect(state.completed, isFalse);
    state = pursue.advance(state, const TargetPursued('target'));
    expect(state.completed, isTrue);

    final commander = DefeatCommanderObjective('boss');
    state = commander.advance(
      commander.initialProgress,
      const CommanderDefeated('boss'),
    );
    expect(state.completed, isTrue);
  });

  test(
    'identical duration ticks accumulate, while explicit replay is idempotent',
    () {
      final survive = SurviveDurationObjective(const Duration(seconds: 2));
      var state = survive.initialProgress;
      final first = TimeElapsed(const Duration(seconds: 1), eventId: 'tick-1');
      state = survive.advance(state, first);
      state = survive.advance(
        state,
        TimeElapsed(const Duration(seconds: 1), eventId: 'tick-2'),
      );
      expect(state.elapsed, const Duration(seconds: 2));
      expect(state.completed, isTrue);

      final defend = DefendEntityObjective('npc', const Duration(seconds: 2));
      state = defend.initialProgress;
      final event = EntityDefended(
        'npc',
        const Duration(seconds: 1),
        eventId: 'defend-tick-1',
      );
      state = defend.advance(state, event);
      final replayed = defend.advance(state, event);
      expect(replayed.elapsed, const Duration(seconds: 1));
      expect(replayed.completed, isFalse);
    },
  );
}
