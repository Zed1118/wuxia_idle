import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/application/mentor_insight_stage_occupancy_runtime.dart';
import 'package:wuxia_idle/features/mainline/domain/mentor_insight_policy.dart';

import '../../../support/dart_source_contract.dart';

const _unblocked = MentorInsightBlockingStatus();

MentorInsightChoice _choice(String stageId, [int? characterId]) =>
    MentorInsightChoice(stageId: stageId, menteeCharacterId: characterId);

MentorInsightCompanion _companion(String stageId, int characterId) =>
    MentorInsightCompanion(stageId: stageId, characterId: characterId);

MentorInsightStageOccupancyRuntime _occupied(
  MentorInsightCompanion companion, {
  int revision = 0,
}) => MentorInsightStageOccupancyRuntime.restore(
  revision: revision,
  companion: companion,
);

void main() {
  group('snapshot and restore', () {
    test('empty runtime starts at revision zero without a companion', () {
      final runtime = MentorInsightStageOccupancyRuntime.empty();

      expect(runtime.snapshot.revision, 0);
      expect(runtime.snapshot.companion, isNull);
    });

    test(
      'restore retains immutable scalar facts and rejects negative revision',
      () {
        final companion = _companion('stage_seed', 17);
        final runtime = MentorInsightStageOccupancyRuntime.restore(
          revision: 9,
          companion: companion,
        );

        expect(runtime.snapshot.revision, 9);
        expect(runtime.snapshot.companion, same(companion));
        expect(runtime.snapshot.companion!.stageId, 'stage_seed');
        expect(runtime.snapshot.companion!.characterId, 17);
        expect(
          () => MentorInsightStageOccupancyRuntime.restore(revision: -1),
          throwsArgumentError,
        );
      },
    );
  });

  group('ordered acquire and release', () {
    test(
      'allowed acquire preserves exact caller stage and character facts',
      () {
        final runtime = MentorInsightStageOccupancyRuntime.empty();
        final base = runtime.snapshot;

        final prepared = runtime.prepare([
          AcquireMentorInsightStageOccupancy(
            choice: _choice('stage_a', 31),
            blockingStatus: _unblocked,
          ),
        ]);

        expect(prepared.base, same(base));
        expect(prepared.next.revision, 1);
        expect(prepared.next.companion, _companion('stage_a', 31));
        expect(runtime.snapshot, same(base));
        expect(runtime.snapshot.companion, isNull);

        final successor = runtime.commit(prepared);
        expect(successor, isNot(same(runtime)));
        expect(successor.snapshot, same(prepared.next));
        expect(successor.snapshot.companion, _companion('stage_a', 31));
      },
    );

    test('empty choice is a strict no-op even while blocked and occupied', () {
      final active = _companion('stage_active', 41);
      final runtime = _occupied(active, revision: 7);
      final base = runtime.snapshot;

      final prepared = runtime.prepare([
        AcquireMentorInsightStageOccupancy(
          choice: _choice('stage_ignored'),
          blockingStatus: const MentorInsightBlockingStatus(
            inRetreat: true,
            inExpedition: true,
            inBossGauntlet: true,
            inHealingRecovery: true,
          ),
        ),
      ]);

      expect(prepared.next, same(base));
      final successor = runtime.commit(prepared);
      expect(successor, isNot(same(runtime)));
      expect(successor.snapshot, same(base));
      expect(successor.snapshot.revision, 7);
      expect(successor.snapshot.companion, same(active));
    });

    test('all four R02 reasons release the exact active companion', () {
      expect(MentorInsightReleaseReason.values, [
        MentorInsightReleaseReason.successSettlement,
        MentorInsightReleaseReason.failureSettlement,
        MentorInsightReleaseReason.explicitExit,
        MentorInsightReleaseReason.idempotentRecoverySettlement,
      ]);

      for (final reason in MentorInsightReleaseReason.values) {
        final active = _companion('stage_release', 51);
        final runtime = _occupied(active, revision: 4);

        final successor = runtime.commit(
          runtime.prepare([
            ReleaseMentorInsightStageOccupancy(
              companion: active,
              reason: reason,
            ),
          ]),
        );

        expect(successor.snapshot.revision, 5, reason: reason.name);
        expect(successor.snapshot.companion, isNull, reason: reason.name);
      }
    });

    test(
      'same-batch acquire and release increments once with net empty state',
      () {
        final companion = _companion('stage_ephemeral', 61);
        final runtime = MentorInsightStageOccupancyRuntime.empty();

        final successor = runtime.commit(
          runtime.prepare([
            AcquireMentorInsightStageOccupancy(
              choice: _choice(companion.stageId, companion.characterId),
              blockingStatus: _unblocked,
            ),
            ReleaseMentorInsightStageOccupancy(
              companion: companion,
              reason: MentorInsightReleaseReason.successSettlement,
            ),
          ]),
        );

        expect(successor.snapshot.revision, 1);
        expect(successor.snapshot.companion, isNull);
      },
    );

    test(
      'release then acquire permits an explicit cross-stage replacement',
      () {
        final first = _companion('stage_first', 71);
        final runtime = _occupied(first, revision: 3);

        final successor = runtime.commit(
          runtime.prepare([
            ReleaseMentorInsightStageOccupancy(
              companion: first,
              reason: MentorInsightReleaseReason.explicitExit,
            ),
            AcquireMentorInsightStageOccupancy(
              choice: _choice('stage_second', 72),
              blockingStatus: _unblocked,
            ),
          ]),
        );

        expect(successor.snapshot.revision, 4);
        expect(successor.snapshot.companion, _companion('stage_second', 72));
      },
    );
  });

  group('fail-closed validation and atomic preparation', () {
    test('each blocking status rejects a non-empty acquire', () {
      final blockedStatuses = [
        const MentorInsightBlockingStatus(inRetreat: true),
        const MentorInsightBlockingStatus(inExpedition: true),
        const MentorInsightBlockingStatus(inBossGauntlet: true),
        const MentorInsightBlockingStatus(inHealingRecovery: true),
      ];

      for (final status in blockedStatuses) {
        final runtime = MentorInsightStageOccupancyRuntime.empty();
        final base = runtime.snapshot;

        expect(
          () => runtime.prepare([
            AcquireMentorInsightStageOccupancy(
              choice: _choice('stage_blocked', 81),
              blockingStatus: status,
            ),
          ]),
          throwsStateError,
        );
        expect(runtime.snapshot, same(base));
      }
    });

    test('active duplicate and stage or character mismatches all reject', () {
      final active = _companion('stage_active', 91);
      final cases = [
        _choice('stage_active', 91),
        _choice('stage_active', 92),
        _choice('stage_other', 91),
      ];

      for (final choice in cases) {
        final runtime = _occupied(active, revision: 2);
        final base = runtime.snapshot;
        expect(
          () => runtime.prepare([
            AcquireMentorInsightStageOccupancy(
              choice: choice,
              blockingStatus: _unblocked,
            ),
          ]),
          throwsStateError,
        );
        expect(runtime.snapshot, same(base));
      }
    });

    test(
      'unknown, stage-mismatched, and character-mismatched releases reject',
      () {
        final active = _companion('stage_active', 101);
        final cases = [
          (MentorInsightStageOccupancyRuntime.empty(), active),
          (_occupied(active), _companion('stage_other', 101)),
          (_occupied(active), _companion('stage_active', 102)),
        ];

        for (final (runtime, requested) in cases) {
          final base = runtime.snapshot;
          expect(
            () => runtime.prepare([
              ReleaseMentorInsightStageOccupancy(
                companion: requested,
                reason: MentorInsightReleaseReason.failureSettlement,
              ),
            ]),
            throwsStateError,
          );
          expect(runtime.snapshot, same(base));
        }
      },
    );

    test('a later validation failure rejects the whole ordered batch', () {
      final runtime = MentorInsightStageOccupancyRuntime.empty();
      final originalRuntime = runtime;
      final base = runtime.snapshot;

      expect(
        () => runtime.prepare([
          AcquireMentorInsightStageOccupancy(
            choice: _choice('stage_valid_first', 111),
            blockingStatus: _unblocked,
          ),
          ReleaseMentorInsightStageOccupancy(
            companion: _companion('stage_wrong', 111),
            reason: MentorInsightReleaseReason.successSettlement,
          ),
        ]),
        throwsStateError,
      );

      expect(runtime, same(originalRuntime));
      expect(runtime.snapshot, same(base));
      expect(runtime.snapshot.revision, 0);
      expect(runtime.snapshot.companion, isNull);
    });

    test(
      'lazy iterable is fully materialized before any validation publishes',
      () {
        final runtime = MentorInsightStageOccupancyRuntime.empty();
        final base = runtime.snapshot;

        Iterable<MentorInsightStageOccupancyMutation> lazyMutations() sync* {
          yield AcquireMentorInsightStageOccupancy(
            choice: _choice('stage_lazy', 121),
            blockingStatus: _unblocked,
          );
          throw StateError('lazy occupancy input failed');
        }

        expect(() => runtime.prepare(lazyMutations()), throwsStateError);
        expect(runtime.snapshot, same(base));
        expect(runtime.snapshot.revision, 0);
        expect(runtime.snapshot.companion, isNull);
      },
    );
  });

  group('defensive prepared values and owner lineage', () {
    test('prepare copies caller input and exposes an unmodifiable list', () {
      final mutation = AcquireMentorInsightStageOccupancy(
        choice: _choice('stage_input', 131),
        blockingStatus: _unblocked,
      );
      final callerList = <MentorInsightStageOccupancyMutation>[mutation];
      final runtime = MentorInsightStageOccupancyRuntime.empty();

      final prepared = runtime.prepare(callerList);
      callerList.clear();

      expect(prepared.mutations, [same(mutation)]);
      expect(() => prepared.mutations.clear(), throwsUnsupportedError);
      expect(
        runtime.commit(prepared).snapshot.companion,
        _companion('stage_input', 131),
      );
    });

    test('foreign, stale predecessor, and double commit all fail closed', () {
      final root = MentorInsightStageOccupancyRuntime.empty();
      final foreign = MentorInsightStageOccupancyRuntime.empty();
      final prepared = root.prepare([
        AcquireMentorInsightStageOccupancy(
          choice: _choice('stage_a', 141),
          blockingStatus: _unblocked,
        ),
      ]);

      expect(() => foreign.commit(prepared), throwsStateError);

      final sibling = root.commit(
        root.prepare([
          AcquireMentorInsightStageOccupancy(
            choice: _choice('stage_b', 142),
            blockingStatus: _unblocked,
          ),
        ]),
      );
      expect(() => sibling.commit(prepared), throwsStateError);

      final successor = root.commit(prepared);
      expect(successor.snapshot.companion, _companion('stage_a', 141));
      expect(() => root.commit(prepared), throwsStateError);
      expect(() => successor.commit(prepared), throwsStateError);
    });

    test(
      'no-op prepared value is consumed and preserves snapshot identity',
      () {
        final runtime = MentorInsightStageOccupancyRuntime.empty();
        final base = runtime.snapshot;
        final prepared = runtime.prepare(const []);

        expect(prepared.next, same(base));
        final successor = runtime.commit(prepared);

        expect(successor, isNot(same(runtime)));
        expect(successor.snapshot, same(base));
        expect(() => runtime.commit(prepared), throwsStateError);
        expect(() => successor.commit(prepared), throwsStateError);
      },
    );

    test('separate prepared values produce isolated sibling successors', () {
      final root = MentorInsightStageOccupancyRuntime.empty();
      final branchAPrepared = root.prepare([
        AcquireMentorInsightStageOccupancy(
          choice: _choice('stage_a', 151),
          blockingStatus: _unblocked,
        ),
      ]);
      final branchBPrepared = root.prepare([
        AcquireMentorInsightStageOccupancy(
          choice: _choice('stage_b', 152),
          blockingStatus: _unblocked,
        ),
      ]);

      final branchA = root.commit(branchAPrepared);
      final branchB = root.commit(branchBPrepared);

      expect(root.snapshot.companion, isNull);
      expect(branchA.snapshot.companion, _companion('stage_a', 151));
      expect(branchB.snapshot.companion, _companion('stage_b', 152));
      expect(branchA.snapshot, isNot(same(branchB.snapshot)));
      expect(branchA.snapshot.revision, 1);
      expect(branchB.snapshot.revision, 1);
    });

    test('restore and empty create independent owner lineages', () {
      final restored = MentorInsightStageOccupancyRuntime.restore(revision: 3);
      final empty = MentorInsightStageOccupancyRuntime.empty();
      final prepared = restored.prepare([
        AcquireMentorInsightStageOccupancy(
          choice: _choice('stage_restored', 161),
          blockingStatus: _unblocked,
        ),
      ]);

      expect(() => empty.commit(prepared), throwsStateError);
      expect(restored.snapshot.revision, 3);
      expect(restored.snapshot.companion, isNull);
      expect(empty.snapshot.revision, 0);
      expect(empty.snapshot.companion, isNull);
    });
  });

  test('source contract stays isolated from claim, host, and tuning paths', () {
    const sourcePath =
        'lib/features/mainline/application/'
        'mentor_insight_stage_occupancy_runtime.dart';
    final source = File(sourcePath).readAsStringSync();
    final imports = RegExp(
      "^import '([^']+)';",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)).toList();
    final contract = DartSourceContract.parse(source, path: sourcePath);

    expect(imports, ['../domain/mentor_insight_policy.dart']);
    expect(
      contract.methodCalls(
        targetSource: 'MentorInsightPolicy',
        methodName: 'canAccompany',
      ),
      hasLength(1),
    );
    expect(
      contract.methodCalls(
        targetSource: 'MentorInsightPolicy.releaseReasons',
        methodName: 'contains',
      ),
      hasLength(1),
    );

    for (final forbiddenIdentifier in const [
      'MentorInsightClaimPolicy',
      'RewardClaimKey',
      'RewardGrantGuard',
      'MentorInsightGrowthTarget',
      'ActivityOccupancy',
      'CharacterOccupancyService',
      'GameRepository',
      'SaveData',
      'Isar',
    ]) {
      expect(
        contract.identifierCount(forbiddenIdentifier),
        0,
        reason: forbiddenIdentifier,
      );
    }
    for (final forbiddenMember in const [
      'isBlocked',
      'inRetreat',
      'inExpedition',
      'inBossGauntlet',
      'inHealingRecovery',
      'rate',
      'cap',
      'amount',
      'pct',
      'percent',
    ]) {
      expect(
        contract.memberAccessCount(forbiddenMember),
        0,
        reason: forbiddenMember,
      );
    }
    for (final forbiddenText in const [
      'package:isar',
      "'/data/",
      'phase0a_combat_host',
      'MainlineRun',
    ]) {
      expect(source, isNot(contains(forbiddenText)), reason: forbiddenText);
    }
  });
}
