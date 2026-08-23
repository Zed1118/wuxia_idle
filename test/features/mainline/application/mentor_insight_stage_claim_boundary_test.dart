import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_stage_runtime_admission.dart';
import 'package:wuxia_idle/features/mainline/application/mentor_insight_claim_policy.dart';
import 'package:wuxia_idle/features/mainline/application/mentor_insight_stage_claim_boundary.dart';
import 'package:wuxia_idle/features/mainline/application/mentor_insight_stage_occupancy_runtime.dart';
import 'package:wuxia_idle/features/mainline/domain/mentor_insight_policy.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';

import '../../../support/dart_source_contract.dart';

ActivityParticipationRequest _request() => ActivityParticipationRequest(
  contentId: 'mainline_1_1',
  contentKind: ActivityContentKind.mainline,
  characterId: 7,
  loadoutPlanId: 'persistent_plan_7',
  participation: ActivityParticipationMode.direct,
  controller: ActivityController.human,
  clock: ActivityClock.realtime,
  entryKind: ActivityEntryKind.firstClear,
);

MainlineStageRuntimeAdmission _admit({
  String stageId = 'stage_a',
  int? companionCharacterId = 91,
  MentorInsightStageOccupancyRuntime? occupancyPredecessor,
}) {
  final predecessor =
      occupancyPredecessor ?? MentorInsightStageOccupancyRuntime.empty();
  return prepareMainlineStageRuntimeAdmission(
    request: _request(),
    currentLeaderId: 7,
    requestedIdleEligible: true,
    runId: 'run_1',
    stageId: stageId,
    loadoutSnapshotId: 'opaque_snapshot_1',
    occupancyPredecessor: predecessor,
    mentorChoice: MentorInsightChoice(
      stageId: stageId,
      menteeCharacterId: companionCharacterId,
    ),
    blockingStatus: const MentorInsightBlockingStatus(),
  ).commit(predecessor);
}

MentorInsightStageClaimCandidate _candidate() {
  final candidate = prepareMentorInsightStageClaimCandidate(
    admission: _admit(),
  );
  expect(candidate, isNotNull);
  return candidate!;
}

RewardClaimKey _wrongKindKey() => RewardClaimKey.battleSessionGrant(
  battleSessionId: 'session_1',
  stageId: 'stage_a',
  rewardGrantId: 'mentor_insight',
);

RewardClaimKey _wrongStageKey() =>
    RewardClaimKey.mentorInsight(stageId: 'stage_b', characterId: 91);

RewardClaimKey _wrongCharacterKey() =>
    RewardClaimKey.mentorInsight(stageId: 'stage_a', characterId: 92);

MentorInsightDurableClaimObservation _observation(
  RewardClaimKey claimKey,
  bool durablyClaimed,
) => MentorInsightDurableClaimObservation(
  claimKey: claimKey,
  durablyClaimed: durablyClaimed,
);

void main() {
  group('prepare claim candidate', () {
    test('keeps exact provenance and one canonical round-trippable key', () {
      final admission = _admit(
        stageId: 'stage_exact',
        companionCharacterId: 73,
      );
      final companion = admission.admittedCompanion!;

      final candidate = prepareMentorInsightStageClaimCandidate(
        admission: admission,
      );

      expect(candidate, isNotNull);
      expect(candidate!.companion, same(companion));
      expect(candidate.claimKey.kind, RewardClaimKeyKind.mentorInsight);
      expect(candidate.claimKey.stageId, 'stage_exact');
      expect(candidate.claimKey.characterId, 73);
      expect(candidate.claimKey.canonical, 'v1|mentorInsight|stage_exact|73');
      expect(
        RewardClaimKey.parse(candidate.claimKey.canonical),
        candidate.claimKey,
      );
      expect(admission.admittedCompanion, same(companion));
    });

    test('returns null for an empty companion choice', () {
      final admission = _admit(companionCharacterId: null);

      expect(
        prepareMentorInsightStageClaimCandidate(admission: admission),
        isNull,
      );
    });

    test('returns null for empty choice over an occupied predecessor', () {
      final oldCompanion = MentorInsightCompanion(
        stageId: 'stage_old',
        characterId: 51,
      );
      final predecessor = MentorInsightStageOccupancyRuntime.restore(
        revision: 8,
        companion: oldCompanion,
      );
      final oldSnapshot = predecessor.snapshot;
      final admission = _admit(
        companionCharacterId: null,
        occupancyPredecessor: predecessor,
      );

      expect(admission.admittedCompanion, isNull);
      expect(admission.occupancyRuntime.snapshot, same(oldSnapshot));
      expect(admission.occupancyRuntime.snapshot.companion, same(oldCompanion));
      expect(
        prepareMentorInsightStageClaimCandidate(admission: admission),
        isNull,
      );
    });
  });

  group('failed settlement', () {
    test('missing observation delegates false and fails closed', () {
      final candidate = _candidate();

      final decision = decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: false,
      );

      expect(decision.outcome, MentorInsightClaimOutcome.failClosed);
      expect(decision.companion, same(candidate.companion));
      expect(decision.claimKey, same(candidate.claimKey));
    });

    test('wrong-kind observation fails closed without throwing getters', () {
      final candidate = _candidate();

      final decision = decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: false,
        durableObservation: _observation(_wrongKindKey(), true),
      );

      expect(decision.outcome, MentorInsightClaimOutcome.failClosed);
    });

    test('wrong-stage observation fails closed', () {
      final decision = decideMentorInsightStageClaim(
        candidate: _candidate(),
        isSuccessfulSettlement: false,
        durableObservation: _observation(_wrongStageKey(), true),
      );

      expect(decision.outcome, MentorInsightClaimOutcome.failClosed);
    });

    test('wrong-character observation fails closed', () {
      final decision = decideMentorInsightStageClaim(
        candidate: _candidate(),
        isSuccessfulSettlement: false,
        durableObservation: _observation(_wrongCharacterKey(), true),
      );

      expect(decision.outcome, MentorInsightClaimOutcome.failClosed);
    });

    test('exact unclaimed observation still delegates and fails closed', () {
      final candidate = _candidate();
      final decision = decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: false,
        durableObservation: _observation(candidate.claimKey, false),
      );

      expect(decision.outcome, MentorInsightClaimOutcome.failClosed);
    });

    test('exact claimed observation still delegates and fails closed', () {
      final candidate = _candidate();
      final decision = decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: false,
        durableObservation: _observation(candidate.claimKey, true),
      );

      expect(decision.outcome, MentorInsightClaimOutcome.failClosed);
    });
  });

  group('successful settlement', () {
    test('missing observation fails closed', () {
      final decision = decideMentorInsightStageClaim(
        candidate: _candidate(),
        isSuccessfulSettlement: true,
      );

      expect(decision.outcome, MentorInsightClaimOutcome.failClosed);
    });

    test('wrong-kind observation fails closed without throwing getters', () {
      final decision = decideMentorInsightStageClaim(
        candidate: _candidate(),
        isSuccessfulSettlement: true,
        durableObservation: _observation(_wrongKindKey(), false),
      );

      expect(decision.outcome, MentorInsightClaimOutcome.failClosed);
    });

    test('wrong-stage observation fails closed', () {
      final decision = decideMentorInsightStageClaim(
        candidate: _candidate(),
        isSuccessfulSettlement: true,
        durableObservation: _observation(_wrongStageKey(), false),
      );

      expect(decision.outcome, MentorInsightClaimOutcome.failClosed);
    });

    test('wrong-character observation fails closed', () {
      final decision = decideMentorInsightStageClaim(
        candidate: _candidate(),
        isSuccessfulSettlement: true,
        durableObservation: _observation(_wrongCharacterKey(), false),
      );

      expect(decision.outcome, MentorInsightClaimOutcome.failClosed);
    });

    test('exact unclaimed observation grants', () {
      final candidate = _candidate();
      final decision = decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: true,
        durableObservation: _observation(candidate.claimKey, false),
      );

      expect(decision.outcome, MentorInsightClaimOutcome.grant);
    });

    test('exact claimed observation skips', () {
      final candidate = _candidate();
      final decision = decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: true,
        durableObservation: _observation(candidate.claimKey, true),
      );

      expect(decision.outcome, MentorInsightClaimOutcome.skip);
    });

    test('equal but non-identical canonical key is accepted', () {
      final candidate = _candidate();
      final restoredKey = RewardClaimKey.parse(candidate.claimKey.canonical);
      expect(restoredKey, isNot(same(candidate.claimKey)));

      final decision = decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: true,
        durableObservation: _observation(restoredKey, false),
      );

      expect(decision.outcome, MentorInsightClaimOutcome.grant);
      expect(decision.claimKey, same(candidate.claimKey));
    });
  });

  group('decision value discipline', () {
    test('each call returns a fresh decision with exact candidate values', () {
      final candidate = _candidate();
      final observation = _observation(candidate.claimKey, false);

      final first = decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: true,
        durableObservation: observation,
      );
      final second = decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: true,
        durableObservation: observation,
      );

      expect(first, isNot(same(second)));
      expect(first.companion, same(candidate.companion));
      expect(second.companion, same(candidate.companion));
      expect(first.claimKey, same(candidate.claimKey));
      expect(second.claimKey, same(candidate.claimKey));
    });

    test('recovery replay with exact claimed observation skips', () {
      final candidate = _candidate();

      final replay = decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: true,
        durableObservation: _observation(candidate.claimKey, true),
      );

      expect(replay.outcome, MentorInsightClaimOutcome.skip);
    });

    test('recovery replay with exact unclaimed observation still grants', () {
      final candidate = _candidate();

      final replay = decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: true,
        durableObservation: _observation(candidate.claimKey, false),
      );

      expect(replay.outcome, MentorInsightClaimOutcome.grant);
    });

    test('candidate observation and admission inputs stay unchanged', () {
      final admission = _admit();
      final occupancySnapshot = admission.occupancyRuntime.snapshot;
      final candidate = prepareMentorInsightStageClaimCandidate(
        admission: admission,
      )!;
      final companion = candidate.companion;
      final claimKey = candidate.claimKey;
      final observation = _observation(claimKey, false);

      decideMentorInsightStageClaim(
        candidate: candidate,
        isSuccessfulSettlement: true,
        durableObservation: observation,
      );

      expect(admission.admittedCompanion, same(companion));
      expect(admission.occupancyRuntime.snapshot, same(occupancySnapshot));
      expect(candidate.companion, same(companion));
      expect(candidate.claimKey, same(claimKey));
      expect(observation.claimKey, same(claimKey));
      expect(observation.durablyClaimed, isFalse);
    });
  });

  test('source is one canonical observation-to-policy seam', () {
    const sourcePath =
        'lib/features/mainline/application/'
        'mentor_insight_stage_claim_boundary.dart';
    final source = File(sourcePath).readAsStringSync();
    final contract = DartSourceContract.parse(source, path: sourcePath);
    final imports = RegExp(
      "^import '([^']+)';",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)).toList();

    expect(imports, [
      '../../../shared/battle_shared/reward_claim_key.dart',
      '../domain/mentor_insight_policy.dart',
      'mainline_stage_runtime_admission.dart',
      'mentor_insight_claim_policy.dart',
    ]);
    expect(
      RegExp(
        r'const MentorInsightDurableClaimObservation\(',
      ).allMatches(source),
      hasLength(1),
    );
    expect(
      RegExp(r'const MentorInsightStageClaimCandidate\._\(').allMatches(source),
      hasLength(1),
    );
    expect(
      RegExp(r'const MentorInsightStageClaimDecision\._\(').allMatches(source),
      hasLength(1),
    );
    expect(
      RegExp(r'RewardClaimKey\.mentorInsight\(').allMatches(source),
      hasLength(1),
    );
    expect(
      contract.methodCalls(
        targetSource: 'MentorInsightClaimPolicy',
        methodName: 'decide',
      ),
      hasLength(1),
    );
    expect(
      source.indexOf('companion.stageId != currentStageId'),
      lessThan(source.indexOf('RewardClaimKey.mentorInsight(')),
    );
    expect(
      contract.memberAccessCount(
        'stageId',
        receiverSource: 'durableObservation.claimKey',
      ),
      0,
    );
    expect(
      contract.memberAccessCount(
        'characterId',
        receiverSource: 'durableObservation.claimKey',
      ),
      0,
    );
    expect(source, isNot(contains('identical(')));

    for (final forbiddenIdentifier in const [
      'RewardGrantGuard',
      'ActivityOccupancy',
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
    for (final forbiddenText in const [
      'RewardClaimKey.parse',
      'componentSeparator',
      'versionPrefix',
      'try {',
      'catch',
      'store',
      'ledger',
      'repository',
      'package:isar',
      'SaveData',
      'CAS',
      'outbox',
      'RewardGrantGuard',
      'callback',
      'rate',
      'cap',
      'amount',
      'host',
      'ActivityOccupancy',
      'releaseReason',
      'MentorInsightReleaseReason',
    ]) {
      expect(source, isNot(contains(forbiddenText)), reason: forbiddenText);
    }
  });
}
