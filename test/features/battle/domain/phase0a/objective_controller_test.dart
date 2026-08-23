import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/objective_controller.dart';

void main() {
  ObjectiveController controller(
    ObjectiveCompletionRule rule, {
    Iterable<ObjectiveClause>? clauses,
  }) => ObjectiveController(
    completionRule: rule,
    clauses:
        clauses ??
        [
          ObjectiveClause(
            id: 'clear',
            objective: DefeatTargetsObjective(const ['target']),
          ),
          ObjectiveClause(
            id: 'exit',
            objective: ReachCheckpointObjective(const ['exit']),
          ),
        ],
  );

  test('all completes only after every clause and preserves stable order', () {
    final objectives = controller(ObjectiveCompletionRule.all);
    var progress = objectives.initialProgress;

    expect(objectives.clauses.map((clause) => clause.id), ['clear', 'exit']);
    expect(progress.clauses.map((clause) => clause.id), ['clear', 'exit']);

    progress = objectives.advance(progress, TargetDefeated('target'));
    expect(progress.completed, isFalse);
    expect(progress.clauses.map((clause) => clause.completed), [true, false]);

    progress = objectives.advance(progress, CheckpointReached('exit'));
    expect(progress.completed, isTrue);
    expect(progress.clauses.map((clause) => clause.completed), [true, true]);
  });

  test('one event is broadcast in order to every unfinished primitive', () {
    for (final rule in ObjectiveCompletionRule.values) {
      final objectives = controller(
        rule,
        clauses: [
          ObjectiveClause(
            id: 'first',
            objective: DefeatTargetsObjective(const ['shared']),
          ),
          ObjectiveClause(
            id: 'second',
            objective: DefeatTargetsObjective(const ['shared']),
          ),
        ],
      );

      final progress = objectives.advance(
        objectives.initialProgress,
        TargetDefeated('shared', eventId: 'shared-defeat'),
      );

      expect(progress.completed, isTrue);
      expect(progress.clauses.map((clause) => clause.id), ['first', 'second']);
      expect(progress.clauses.map((clause) => clause.completed), [true, true]);
    }
  });

  test('any terminal state makes later events a strict no-op', () {
    final objectives = controller(ObjectiveCompletionRule.any);
    final completed = objectives.advance(
      objectives.initialProgress,
      TargetDefeated('target', eventId: 'terminal-event'),
    );

    expect(completed.completed, isTrue);
    expect(completed.clauses.map((clause) => clause.completed), [true, false]);
    expect(
      objectives.advance(
        completed,
        CheckpointReached('exit', eventId: 'after-terminal'),
      ),
      same(completed),
    );
    expect(completed.clauses.last.completed, isFalse);
  });

  test('duplicate replay is deterministic for aggregate duration progress', () {
    final objectives = controller(
      ObjectiveCompletionRule.all,
      clauses: [
        ObjectiveClause(
          id: 'survive-a',
          objective: SurviveDurationObjective(const Duration(seconds: 2)),
        ),
        ObjectiveClause(
          id: 'survive-b',
          objective: SurviveDurationObjective(const Duration(seconds: 2)),
        ),
      ],
    );
    final event = TimeElapsed(const Duration(seconds: 1), eventId: 'tick-1');

    final once = objectives.advance(objectives.initialProgress, event);
    final replayed = objectives.advance(once, event);

    expect(replayed, same(once));
    expect(replayed.clauses.map((clause) => clause.progress.elapsed), const [
      Duration(seconds: 1),
      Duration(seconds: 1),
    ]);
    final completed = objectives.advance(
      replayed,
      TimeElapsed(const Duration(seconds: 1), eventId: 'tick-2'),
    );
    expect(completed.completed, isTrue);
  });

  test('unrelated events reach unfinished clauses without completing them', () {
    final objectives = controller(ObjectiveCompletionRule.all);
    final progress = objectives.advance(
      objectives.initialProgress,
      AnchorDestroyed('unrelated', eventId: 'unrelated-event'),
    );

    expect(progress.completed, isFalse);
    expect(progress.clauses.map((clause) => clause.completed), [false, false]);
    for (final clause in progress.clauses) {
      expect(clause.progress.processedEventIds, {
        'anchorDestroyed:unrelated-event',
      });
    }
  });

  test('progress is bound to its controller before terminal checks', () {
    final first = controller(ObjectiveCompletionRule.any);
    final second = controller(ObjectiveCompletionRule.any);

    expect(
      () => second.advance(first.initialProgress, TargetDefeated('target')),
      throwsStateError,
    );

    final completed = first.advance(
      first.initialProgress,
      TargetDefeated('target'),
    );
    expect(completed.completed, isTrue);
    expect(
      () => second.advance(completed, TargetDefeated('target')),
      throwsStateError,
    );
  });

  test('constructor snapshots input and exposes immutable collections', () {
    final input = <ObjectiveClause>[
      ObjectiveClause(
        id: 'clear',
        objective: DefeatTargetsObjective(const ['target']),
      ),
    ];
    final objectives = controller(ObjectiveCompletionRule.all, clauses: input);
    input.add(
      ObjectiveClause(
        id: 'exit',
        objective: ReachCheckpointObjective(const ['exit']),
      ),
    );

    expect(objectives.clauses.map((clause) => clause.id), ['clear']);
    expect(() => objectives.clauses.clear(), throwsUnsupportedError);
    expect(
      () => objectives.initialProgress.clauses.clear(),
      throwsUnsupportedError,
    );
  });

  test('empty, duplicate and unclean clause ids fail closed', () {
    expect(
      () => controller(ObjectiveCompletionRule.all, clauses: const []),
      throwsArgumentError,
    );
    expect(
      () => ObjectiveClause(
        id: '',
        objective: DefeatTargetsObjective(const ['target']),
      ),
      throwsArgumentError,
    );
    expect(
      () => ObjectiveClause(
        id: 'not clean',
        objective: DefeatTargetsObjective(const ['target']),
      ),
      throwsArgumentError,
    );
    expect(
      () => controller(
        ObjectiveCompletionRule.all,
        clauses: [
          ObjectiveClause(
            id: 'same',
            objective: DefeatTargetsObjective(const ['first']),
          ),
          ObjectiveClause(
            id: 'same',
            objective: DefeatTargetsObjective(const ['second']),
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}
