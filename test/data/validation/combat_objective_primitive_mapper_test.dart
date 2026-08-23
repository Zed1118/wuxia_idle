import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/validation/combat_objective_primitive_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/objective_controller.dart';

void main() {
  const tickDuration = Duration(milliseconds: 25);

  group('mapCombatObjectivePrimitive', () {
    test('maps all eight references one-to-one', () {
      final defeatTargets =
          mapCombatObjectivePrimitive(
                CombatDefeatTargetsRef(const ['target_b', 'target_a']),
                tickDuration: tickDuration,
              )
              as DefeatTargetsObjective;
      expect(defeatTargets.targetIds, {'target_a', 'target_b'});

      final destroyAnchors =
          mapCombatObjectivePrimitive(
                CombatDestroyAnchorsRef(const ['anchor_b', 'anchor_a']),
                tickDuration: tickDuration,
              )
              as DestroyAnchorsObjective;
      expect(destroyAnchors.anchorIds, {'anchor_a', 'anchor_b'});

      final defendEntity =
          mapCombatObjectivePrimitive(
                CombatDefendEntityRef(entityId: 'ward', requiredTicks: 3),
                tickDuration: tickDuration,
              )
              as DefendEntityObjective;
      expect(defendEntity.entityId, 'ward');
      expect(defendEntity.requiredDuration, const Duration(milliseconds: 75));

      final surviveDuration =
          mapCombatObjectivePrimitive(
                CombatSurviveDurationRef(requiredTicks: 4),
                tickDuration: tickDuration,
              )
              as SurviveDurationObjective;
      expect(
        surviveDuration.requiredDuration,
        const Duration(milliseconds: 100),
      );

      final reachCheckpoint =
          mapCombatObjectivePrimitive(
                CombatReachCheckpointRef(const [
                  'checkpoint_b',
                  'checkpoint_a',
                ]),
                tickDuration: tickDuration,
              )
              as ReachCheckpointObjective;
      expect(reachCheckpoint.checkpointIds, {'checkpoint_a', 'checkpoint_b'});

      final touchMarkers =
          mapCombatObjectivePrimitive(
                CombatTouchMarkersRef(const ['marker_b', 'marker_a']),
                tickDuration: tickDuration,
              )
              as TouchMarkersObjective;
      expect(touchMarkers.markerIds, {'marker_a', 'marker_b'});

      final pursueTarget =
          mapCombatObjectivePrimitive(
                CombatPursueTargetRef(targetId: 'runner'),
                tickDuration: tickDuration,
              )
              as PursueTargetObjective;
      expect(pursueTarget.targetId, 'runner');

      final defeatCommander =
          mapCombatObjectivePrimitive(
                CombatDefeatCommanderRef(commanderId: 'commander'),
                tickDuration: tickDuration,
              )
              as DefeatCommanderObjective;
      expect(defeatCommander.commanderId, 'commander');
    });

    test('requires a positive explicit tick duration for every ref kind', () {
      final references = <CombatObjectivePrimitiveRef>[
        CombatDefeatTargetsRef(const ['target']),
        CombatDestroyAnchorsRef(const ['anchor']),
        CombatDefendEntityRef(entityId: 'ward', requiredTicks: 1),
        CombatSurviveDurationRef(requiredTicks: 1),
        CombatReachCheckpointRef(const ['checkpoint']),
        CombatTouchMarkersRef(const ['marker']),
        CombatPursueTargetRef(targetId: 'runner'),
        CombatDefeatCommanderRef(commanderId: 'commander'),
      ];

      for (final reference in references) {
        expect(
          () => mapCombatObjectivePrimitive(
            reference,
            tickDuration: Duration.zero,
          ),
          throwsArgumentError,
        );
        expect(
          () => mapCombatObjectivePrimitive(
            reference,
            tickDuration: const Duration(microseconds: -1),
          ),
          throwsArgumentError,
        );
      }
    });

    test('accepts the positive Duration boundary without truncation', () {
      const maxInt = 0x7fffffffffffffff;

      final survive =
          mapCombatObjectivePrimitive(
                CombatSurviveDurationRef(requiredTicks: maxInt),
                tickDuration: const Duration(microseconds: 1),
              )
              as SurviveDurationObjective;
      expect(survive.requiredDuration.inMicroseconds, maxInt);

      final defend =
          mapCombatObjectivePrimitive(
                CombatDefendEntityRef(entityId: 'ward', requiredTicks: 2),
                tickDuration: const Duration(microseconds: maxInt ~/ 2),
              )
              as DefendEntityObjective;
      expect(defend.requiredDuration.inMicroseconds, maxInt - 1);
    });

    test('rejects Duration multiplication overflow', () {
      const maxInt = 0x7fffffffffffffff;

      expect(
        () => mapCombatObjectivePrimitive(
          CombatSurviveDurationRef(requiredTicks: 2),
          tickDuration: const Duration(microseconds: maxInt),
        ),
        throwsArgumentError,
      );
      expect(
        () => mapCombatObjectivePrimitive(
          CombatDefendEntityRef(entityId: 'ward', requiredTicks: maxInt),
          tickDuration: const Duration(microseconds: 2),
        ),
        throwsArgumentError,
      );
    });

    test('preserves id snapshots and exposed collection immutability', () {
      final input = <String>['target_b', 'target_a'];
      final reference = CombatDefeatTargetsRef(input);
      final objective =
          mapCombatObjectivePrimitive(reference, tickDuration: tickDuration)
              as DefeatTargetsObjective;

      input
        ..clear()
        ..add('replacement');

      expect(reference.targetIds, {'target_a', 'target_b'});
      expect(objective.targetIds, {'target_a', 'target_b'});
      expect(() => reference.targetIds.add('target_c'), throwsUnsupportedError);
      expect(() => objective.targetIds.add('target_c'), throwsUnsupportedError);
    });

    test('keeps mapped progress owner-bound to each new objective', () {
      final reference = CombatDefeatTargetsRef(const ['target']);
      final first = mapCombatObjectivePrimitive(
        reference,
        tickDuration: tickDuration,
      );
      final second = mapCombatObjectivePrimitive(
        reference,
        tickDuration: tickDuration,
      );

      expect(first, isNot(same(second)));
      expect(
        () => second.advance(first.initialProgress, TargetDefeated('target')),
        throwsStateError,
      );
    });

    test('preserves event replay and completed-state no-op behavior', () {
      final objective = mapCombatObjectivePrimitive(
        CombatSurviveDurationRef(requiredTicks: 2),
        tickDuration: tickDuration,
      );
      final firstTick = TimeElapsed(tickDuration, eventId: 'tick-1');

      final once = objective.advance(objective.initialProgress, firstTick);
      final replayed = objective.advance(once, firstTick);
      expect(replayed, same(once));
      expect(replayed.elapsed, tickDuration);
      expect(replayed.processedEventIds, {'timeElapsed:tick-1'});

      final completed = objective.advance(
        replayed,
        TimeElapsed(tickDuration, eventId: 'tick-2'),
      );
      expect(completed.completed, isTrue);
      expect(
        objective.advance(
          completed,
          TimeElapsed(tickDuration, eventId: 'tick-3'),
        ),
        same(completed),
      );
    });

    test('same inputs have deterministic fields and observable progress', () {
      final reference = CombatReachCheckpointRef(const [
        'checkpoint_b',
        'checkpoint_a',
      ]);
      final first =
          mapCombatObjectivePrimitive(reference, tickDuration: tickDuration)
              as ReachCheckpointObjective;
      final second =
          mapCombatObjectivePrimitive(reference, tickDuration: tickDuration)
              as ReachCheckpointObjective;

      expect(first.checkpointIds, second.checkpointIds);

      var firstProgress = first.initialProgress;
      var secondProgress = second.initialProgress;
      for (final event in [
        CheckpointReached('checkpoint_b', eventId: 'checkpoint-event-b'),
        CheckpointReached('checkpoint_a', eventId: 'checkpoint-event-a'),
      ]) {
        firstProgress = first.advance(firstProgress, event);
        secondProgress = second.advance(secondProgress, event);
      }

      expect(firstProgress.completed, secondProgress.completed);
      expect(firstProgress.satisfied, secondProgress.satisfied);
      expect(firstProgress.elapsed, secondProgress.elapsed);
      expect(firstProgress.processedEventIds, secondProgress.processedEventIds);
    });
  });

  group('mapCombatObjectiveComposition', () {
    CombatObjectiveCompositionRef composition(
      CombatObjectiveCompletionRule rule,
    ) => CombatObjectiveCompositionRef(
      completionRule: rule,
      clauses: [
        CombatObjectiveClauseRef(
          id: 'clear',
          primitive: CombatDefeatTargetsRef(const ['target']),
        ),
        CombatObjectiveClauseRef(
          id: 'exit',
          primitive: CombatReachCheckpointRef(const ['exit']),
        ),
      ],
    );

    test('preserves explicit all/any rules, clause ids and order', () {
      for (final rule in CombatObjectiveCompletionRule.values) {
        final mapped = mapCombatObjectiveComposition(
          composition(rule),
          tickDuration: tickDuration,
        );
        final expectedRule = switch (rule) {
          CombatObjectiveCompletionRule.all => ObjectiveCompletionRule.all,
          CombatObjectiveCompletionRule.any => ObjectiveCompletionRule.any,
        };
        expect(mapped.completionRule, expectedRule);
        expect(mapped.clauses.map((clause) => clause.id), ['clear', 'exit']);
        expect(mapped.clauses[0].objective, isA<DefeatTargetsObjective>());
        expect(mapped.clauses[1].objective, isA<ReachCheckpointObjective>());
        expect(() => mapped.clauses.clear(), throwsUnsupportedError);
      }
    });

    test('maps fresh owner-bound objectives on each invocation', () {
      final ref = composition(CombatObjectiveCompletionRule.all);
      final first = mapCombatObjectiveComposition(
        ref,
        tickDuration: tickDuration,
      );
      final second = mapCombatObjectiveComposition(
        ref,
        tickDuration: tickDuration,
      );

      expect(first, isNot(same(second)));
      expect(
        first.clauses.first.objective,
        isNot(second.clauses.first.objective),
      );
      expect(
        () => second.advance(first.initialProgress, TargetDefeated('target')),
        throwsStateError,
      );
    });

    test('requires the same explicit positive tick duration', () {
      final ref = composition(CombatObjectiveCompletionRule.any);
      expect(
        () => mapCombatObjectiveComposition(ref, tickDuration: Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => mapCombatObjectiveComposition(
          ref,
          tickDuration: const Duration(microseconds: -1),
        ),
        throwsArgumentError,
      );
    });
  });
}
