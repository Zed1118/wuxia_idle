import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_objective_runtime_tracker.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/objective_controller.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';

void main() {
  ObjectiveController controller(
    Iterable<ObjectiveClause> clauses, {
    ObjectiveCompletionRule rule = ObjectiveCompletionRule.all,
  }) => ObjectiveController(completionRule: rule, clauses: clauses);

  Phase0aEnemyDefeated defeated(String target, {int seq = 1}) =>
      Phase0aEnemyDefeated(
        seq: seq,
        tick: seq,
        target: target,
        defeatKind: Phase0aDefeatKind.normal,
      );

  test('explicit target and commander mappings advance their clauses', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['target-a']),
      ),
      ObjectiveClause(
        id: 'commander',
        objective: DefeatCommanderObjective('commander-a'),
      ),
    ]);
    final tracker = Phase0aObjectiveRuntimeTracker(controller: objectives);

    final afterTarget = tracker.advanceCombatEvents(
      [defeated('actor-target')],
      mapDefeat: (_) => [TargetDefeated('target-a', eventId: 'target-defeat')],
    );
    expect(afterTarget.completed, isFalse);
    expect(afterTarget.clauses.map((clause) => clause.completed), [
      true,
      false,
    ]);

    final completed = tracker.advanceCombatEvents(
      [defeated('actor-commander', seq: 2)],
      mapDefeat: (_) => [
        CommanderDefeated('commander-a', eventId: 'commander-defeat'),
      ],
    );
    expect(completed.completed, isTrue);
    expect(completed.clauses.map((clause) => clause.completed), [true, true]);
  });

  test('one defeat may map to two events in caller order', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['target-a']),
      ),
      ObjectiveClause(
        id: 'commander',
        objective: DefeatCommanderObjective('commander-a'),
      ),
    ]);
    final tracker = Phase0aObjectiveRuntimeTracker(controller: objectives);

    final completed = tracker.advanceCombatEvents(
      [defeated('actor-a')],
      mapDefeat: (_) => [
        CommanderDefeated('commander-a', eventId: 'first'),
        TargetDefeated('target-a', eventId: 'second'),
      ],
    );

    expect(completed.completed, isTrue);
    expect(completed.clauses.first.progress.processedEventIds.toList(), [
      'commanderDefeated:first',
      'targetDefeated:second',
    ]);
  });

  test('zero mapped events and non-defeat events are strict no-ops', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['target-a']),
      ),
    ]);
    final tracker = Phase0aObjectiveRuntimeTracker(controller: objectives);
    final initial = tracker.progress;
    var mapperCalls = 0;

    final afterZero = tracker.advanceCombatEvents(
      [defeated('actor-a')],
      mapDefeat: (_) {
        mapperCalls += 1;
        return const <EncounterObjectiveEvent>[];
      },
    );
    expect(afterZero, same(initial));
    expect(mapperCalls, 1);

    final afterNonDefeat = tracker.advanceCombatEvents(
      const [Phase0aBattleVictory(seq: 2, tick: 2)],
      mapDefeat: (_) {
        mapperCalls += 1;
        return [TargetDefeated('target-a')];
      },
    );
    expect(afterNonDefeat, same(initial));
    expect(mapperCalls, 1);
  });

  test('combat and mapped event order are stable', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'targets',
        objective: DefeatTargetsObjective(const ['target-a', 'target-b']),
      ),
    ]);
    final tracker = Phase0aObjectiveRuntimeTracker(controller: objectives);
    final mappedActors = <String>[];

    final completed = tracker.advanceCombatEvents(
      [defeated('actor-b'), defeated('actor-a', seq: 2)],
      mapDefeat: (event) {
        mappedActors.add(event.target);
        return switch (event.target) {
          'actor-b' => [TargetDefeated('target-b', eventId: 'event-b')],
          'actor-a' => [TargetDefeated('target-a', eventId: 'event-a')],
          _ => const <EncounterObjectiveEvent>[],
        };
      },
    );

    expect(mappedActors, ['actor-b', 'actor-a']);
    expect(completed.clauses.single.progress.processedEventIds.toList(), [
      'targetDefeated:event-b',
      'targetDefeated:event-a',
    ]);
    expect(completed.completed, isTrue);
  });

  test('duplicate objective event replay inherits controller dedupe', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'targets',
        objective: DefeatTargetsObjective(const ['target-a', 'target-b']),
      ),
    ]);
    final tracker = Phase0aObjectiveRuntimeTracker(controller: objectives);
    final event = TargetDefeated('target-a', eventId: 'stable-defeat');
    final once = tracker.advanceCombatEvents([
      defeated('actor-a'),
    ], mapDefeat: (_) => [event]);
    final replayed = tracker.advanceCombatEvents([
      defeated('actor-a', seq: 2),
    ], mapDefeat: (_) => [event]);

    expect(replayed, same(once));
    expect(replayed.clauses.single.progress.satisfied, {'target-a'});
  });

  test('terminal progress avoids input iteration and mapper calls', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['target-a']),
      ),
    ]);
    final tracker = Phase0aObjectiveRuntimeTracker(controller: objectives);
    final terminal = tracker.advanceExternal(
      TargetDefeated('target-a', eventId: 'terminal'),
    );
    var inputIterations = 0;
    var mapperCalls = 0;

    Iterable<Phase0aEvent> events() sync* {
      inputIterations += 1;
      yield defeated('actor-after-terminal');
    }

    final unchanged = tracker.advanceCombatEvents(
      events(),
      mapDefeat: (_) {
        mapperCalls += 1;
        return [TargetDefeated('target-a')];
      },
    );

    expect(unchanged, same(terminal));
    expect(inputIterations, 0);
    expect(mapperCalls, 0);
    expect(tracker.advanceExternal(TargetDefeated('target-a')), same(terminal));
  });

  test('mapper construction failure rolls back the whole batch', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['target-a']),
      ),
    ]);
    final tracker = Phase0aObjectiveRuntimeTracker(controller: objectives);
    final initial = tracker.progress;

    expect(
      () => tracker.advanceCombatEvents([
        defeated('actor-a'),
      ], mapDefeat: (_) => throw StateError('mapper failed')),
      throwsStateError,
    );
    expect(tracker.progress, same(initial));
  });

  test('lazy mapper failure after one yield rolls back the whole batch', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['target-a']),
      ),
    ]);
    final tracker = Phase0aObjectiveRuntimeTracker(controller: objectives);
    final initial = tracker.progress;

    Iterable<EncounterObjectiveEvent> lazyEvents() sync* {
      yield TargetDefeated('target-a', eventId: 'would-complete');
      throw StateError('lazy mapper failed');
    }

    expect(
      () => tracker.advanceCombatEvents([
        defeated('actor-a'),
      ], mapDefeat: (_) => lazyEvents()),
      throwsStateError,
    );
    expect(tracker.progress, same(initial));
  });

  test('lazy combat input failure happens before mapper and rolls back', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['target-a']),
      ),
    ]);
    final tracker = Phase0aObjectiveRuntimeTracker(controller: objectives);
    final initial = tracker.progress;
    var mapperCalls = 0;

    Iterable<Phase0aEvent> lazyCombatEvents() sync* {
      yield defeated('actor-a');
      throw StateError('combat input failed');
    }

    expect(
      () => tracker.advanceCombatEvents(
        lazyCombatEvents(),
        mapDefeat: (_) {
          mapperCalls += 1;
          return [TargetDefeated('target-a')];
        },
      ),
      throwsStateError,
    );
    expect(mapperCalls, 0);
    expect(tracker.progress, same(initial));
  });

  test('combat input is snapshotted before caller mapping can mutate it', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['target-a']),
      ),
    ]);
    final tracker = Phase0aObjectiveRuntimeTracker(controller: objectives);
    final input = <Phase0aEvent>[defeated('actor-a')];

    final completed = tracker.advanceCombatEvents(
      input,
      mapDefeat: (_) {
        input.clear();
        return [TargetDefeated('target-a')];
      },
    );

    expect(input, isEmpty);
    expect(completed.completed, isTrue);
  });

  test('same-owner progress may resume and foreign progress fails closed', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'targets',
        objective: DefeatTargetsObjective(const ['target-a', 'target-b']),
      ),
    ]);
    final resumedProgress = objectives.advance(
      objectives.initialProgress,
      TargetDefeated('target-a', eventId: 'before-resume'),
    );
    final tracker = Phase0aObjectiveRuntimeTracker(
      controller: objectives,
      initialProgress: resumedProgress,
    );

    final completed = tracker.advanceExternal(
      TargetDefeated('target-b', eventId: 'after-resume'),
    );
    expect(completed.completed, isTrue);
    expect(() => completed.clauses.clear(), throwsUnsupportedError);
    expect(
      () => Phase0aObjectiveRuntimeTracker(
        controller: objectives,
        initialProgress: controller([
          ObjectiveClause(
            id: 'other',
            objective: DefeatTargetsObjective(const ['target-a']),
          ),
        ]).initialProgress,
      ),
      throwsStateError,
    );
  });

  test('prepared batch is atomic and commits all completion once', () {
    final objectives = controller([
      ObjectiveClause(
        id: 'target-a',
        objective: DefeatTargetsObjective(const ['target-a']),
      ),
      ObjectiveClause(
        id: 'target-b',
        objective: DefeatTargetsObjective(const ['target-b']),
      ),
    ]);
    final tracker = Phase0aObjectiveRuntimeTracker(controller: objectives);
    final initial = tracker.progress;

    final prepared = tracker.prepareExternalEvents([
      TargetDefeated('target-a', eventId: 'prepared-a'),
      TargetDefeated('target-b', eventId: 'prepared-b'),
    ]);

    expect(prepared.base, same(initial));
    expect(prepared.next.completed, isTrue);
    expect(tracker.progress, same(initial));
    expect(tracker.commit(prepared), same(prepared.next));
    expect(tracker.progress.completed, isTrue);
    expect(() => tracker.commit(prepared), throwsStateError);
  });

  test('prepared transitions preserve all and any completion rules', () {
    Phase0aObjectiveRuntimeTracker trackerFor(ObjectiveCompletionRule rule) {
      return Phase0aObjectiveRuntimeTracker(
        controller: controller([
          ObjectiveClause(
            id: 'target-a',
            objective: DefeatTargetsObjective(const ['target-a']),
          ),
          ObjectiveClause(
            id: 'target-b',
            objective: DefeatTargetsObjective(const ['target-b']),
          ),
        ], rule: rule),
      );
    }

    final all = trackerFor(ObjectiveCompletionRule.all);
    final any = trackerFor(ObjectiveCompletionRule.any);
    final allPrepared = all.prepareExternalEvents([
      TargetDefeated('target-a', eventId: 'all-a'),
    ]);
    final anyPrepared = any.prepareExternalEvents([
      TargetDefeated('target-a', eventId: 'any-a'),
    ]);

    expect(allPrepared.next.completed, isFalse);
    expect(anyPrepared.next.completed, isTrue);
    expect(all.progress.completed, isFalse);
    expect(any.progress.completed, isFalse);
  });

  test('foreign and stale prepared transitions fail closed', () {
    final first = Phase0aObjectiveRuntimeTracker(
      controller: controller([
        ObjectiveClause(
          id: 'targets',
          objective: DefeatTargetsObjective(const ['target-a', 'target-b']),
        ),
      ]),
    );
    final second = Phase0aObjectiveRuntimeTracker(
      controller: controller([
        ObjectiveClause(
          id: 'targets',
          objective: DefeatTargetsObjective(const ['target-a', 'target-b']),
        ),
      ]),
    );
    final prepared = first.prepareExternalEvents([
      TargetDefeated('target-a', eventId: 'prepared-a'),
    ]);
    final secondInitial = second.progress;

    expect(() => second.commit(prepared), throwsStateError);
    expect(second.progress, same(secondInitial));

    final advanced = first.advanceExternal(
      TargetDefeated('target-b', eventId: 'committed-b'),
    );
    expect(() => first.commit(prepared), throwsStateError);
    expect(first.progress, same(advanced));
  });

  test('terminal prepare is a strict no-op without iterating input', () {
    final tracker = Phase0aObjectiveRuntimeTracker(
      controller: controller([
        ObjectiveClause(
          id: 'target',
          objective: DefeatTargetsObjective(const ['target-a']),
        ),
      ]),
    );
    final terminal = tracker.advanceExternal(
      TargetDefeated('target-a', eventId: 'terminal-a'),
    );
    var iterations = 0;

    Iterable<EncounterObjectiveEvent> events() sync* {
      iterations += 1;
      throw StateError('must not iterate terminal input');
    }

    final prepared = tracker.prepareExternalEvents(events());
    expect(prepared.base, same(terminal));
    expect(prepared.next, same(terminal));
    expect(iterations, 0);
    expect(tracker.commit(prepared), same(terminal));
    expect(iterations, 0);
  });
}
