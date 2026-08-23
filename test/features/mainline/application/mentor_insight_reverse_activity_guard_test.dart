import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/application/mentor_insight_reverse_activity_guard.dart';
import 'package:wuxia_idle/features/mainline/application/mentor_insight_stage_occupancy_runtime.dart';
import 'package:wuxia_idle/features/mainline/domain/mentor_insight_policy.dart';

import '../../../support/dart_source_contract.dart';

MentorInsightCompanion _companion(int characterId) =>
    MentorInsightCompanion(stageId: 'stage_guard', characterId: characterId);

MentorInsightStageOccupancySnapshot _snapshot({
  required int revision,
  MentorInsightCompanion? companion,
}) => MentorInsightStageOccupancyRuntime.restore(
  revision: revision,
  companion: companion,
).snapshot;

void main() {
  group('exact active character reverse activity guard', () {
    for (final activity in MentorInsightBlockingActivity.values) {
      test('${activity.name} refuses the exact active companion', () {
        final active = _companion(41);
        final occupancy = _snapshot(revision: 7, companion: active);

        expect(
          () => requireMentorInsightActivityEntryAllowed(
            occupancy: occupancy,
            characterId: active.characterId,
            activity: activity,
          ),
          throwsA(
            isA<MentorInsightActivityEntryRefusedError>()
                .having(
                  (error) => error.activeCompanion,
                  'activeCompanion',
                  same(active),
                )
                .having((error) => error.activity, 'activity', same(activity))
                .having(
                  (error) => error.characterId,
                  'characterId',
                  active.characterId,
                ),
          ),
        );
      });
    }

    test('empty occupancy allows every frozen activity', () {
      final occupancy = _snapshot(revision: 3);

      for (final activity in MentorInsightBlockingActivity.values) {
        expect(
          () => requireMentorInsightActivityEntryAllowed(
            occupancy: occupancy,
            characterId: 51,
            activity: activity,
          ),
          returnsNormally,
          reason: activity.name,
        );
      }
    });

    test('another character allows every frozen activity', () {
      final active = _companion(61);
      final occupancy = _snapshot(revision: 5, companion: active);

      for (final activity in MentorInsightBlockingActivity.values) {
        expect(
          () => requireMentorInsightActivityEntryAllowed(
            occupancy: occupancy,
            characterId: 62,
            activity: activity,
          ),
          returnsNormally,
          reason: activity.name,
        );
      }
    });

    test('restore revision does not change exact-character refusal', () {
      final active = _companion(71);

      for (final revision in [0, 1, 19]) {
        final occupancy = _snapshot(revision: revision, companion: active);
        expect(
          () => requireMentorInsightActivityEntryAllowed(
            occupancy: occupancy,
            characterId: active.characterId,
            activity: MentorInsightBlockingActivity.expedition,
          ),
          throwsA(isA<MentorInsightActivityEntryRefusedError>()),
          reason: 'revision $revision',
        );
      }
    });
  });

  group('fail-closed validation and immutable input', () {
    test('zero character ID fails before an empty occupancy can allow', () {
      final occupancy = _snapshot(revision: 0);

      expect(
        () => requireMentorInsightActivityEntryAllowed(
          occupancy: occupancy,
          characterId: 0,
          activity: MentorInsightBlockingActivity.retreat,
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'characterId')
              .having((error) => error.invalidValue, 'invalidValue', 0),
        ),
      );
    });

    test('negative character ID fails before occupied-character matching', () {
      final occupancy = _snapshot(revision: 2, companion: _companion(81));

      expect(
        () => requireMentorInsightActivityEntryAllowed(
          occupancy: occupancy,
          characterId: -1,
          activity: MentorInsightBlockingActivity.healing,
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'characterId')
              .having((error) => error.invalidValue, 'invalidValue', -1),
        ),
      );
    });

    test('allowed and refused calls preserve the exact input snapshot', () {
      final active = _companion(91);
      final occupancy = _snapshot(revision: 11, companion: active);

      requireMentorInsightActivityEntryAllowed(
        occupancy: occupancy,
        characterId: 92,
        activity: MentorInsightBlockingActivity.bossGauntlet,
      );
      expect(occupancy.revision, 11);
      expect(occupancy.companion, same(active));

      expect(
        () => requireMentorInsightActivityEntryAllowed(
          occupancy: occupancy,
          characterId: active.characterId,
          activity: MentorInsightBlockingActivity.bossGauntlet,
        ),
        throwsA(isA<MentorInsightActivityEntryRefusedError>()),
      );
      expect(occupancy.revision, 11);
      expect(occupancy.companion, same(active));
      expect(active.stageId, 'stage_guard');
      expect(active.characterId, 91);
    });
  });

  test('frozen activity set has exactly the four R02 values', () {
    expect(MentorInsightBlockingActivity.values, hasLength(4));
    expect(
      MentorInsightBlockingActivity.values.toSet(),
      MentorInsightPolicy.mutuallyExclusiveActivities,
    );
  });

  test('source stays a read-only snapshot guard with two exact imports', () {
    const sourcePath =
        'lib/features/mainline/application/'
        'mentor_insight_reverse_activity_guard.dart';
    final source = File(sourcePath).readAsStringSync();
    final imports = RegExp(
      "^import '([^']+)';",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)).toList();
    final contract = DartSourceContract.parse(source, path: sourcePath);

    expect(imports, [
      '../domain/mentor_insight_policy.dart',
      'mentor_insight_stage_occupancy_runtime.dart',
    ]);
    expect(
      contract.methodCalls(
        targetSource: 'MentorInsightPolicy.mutuallyExclusiveActivities',
        methodName: 'contains',
      ),
      hasLength(1),
    );

    for (final forbiddenIdentifier in const [
      'ActivityOccupancy',
      'CharacterOccupancyService',
      'Character',
      'MentorInsightStageOccupancyRuntime',
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
      'revision',
      'snapshot',
      'activityOf',
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
      'fallback',
      'candidate',
      'tuning',
    ]) {
      expect(source, isNot(contains(forbiddenText)), reason: forbiddenText);
    }
  });
}
