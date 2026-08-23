import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';

void main() {
  group('canonical stability', () {
    test('same inputs always produce equal keys and identical canonicals', () {
      final a = RewardClaimKey.battleSessionGrant(
        battleSessionId: 'session-1',
        stageId: 'stage-1-2',
        rewardGrantId: 'first_clear',
      );
      final b = RewardClaimKey.battleSessionGrant(
        battleSessionId: 'session-1',
        stageId: 'stage-1-2',
        rewardGrantId: 'first_clear',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.canonical, b.canonical);
      expect(
        a.canonical,
        'v1|battleSessionGrant|session-1|stage-1-2|first_clear',
      );
    });

    test('parse round-trips canonical strings exactly', () {
      final battleKey = RewardClaimKey.battleSessionGrant(
        battleSessionId: 'session-1',
        stageId: 'stage-1-2',
        rewardGrantId: 'repeat',
      );
      final runKey = RewardClaimKey.runChoice(
        runId: 'run-7',
        rewardChoiceId: 'choice-b',
      );

      expect(RewardClaimKey.parse(battleKey.canonical), battleKey);
      expect(RewardClaimKey.parse(runKey.canonical), runKey);
      expect(runKey.canonical, 'v1|runChoice|run-7|choice-b');
    });
  });

  group('isolation', () {
    test('distinct sessions, stages and grants never collide', () {
      RewardClaimKey key(String session, String stage, String grant) =>
          RewardClaimKey.battleSessionGrant(
            battleSessionId: session,
            stageId: stage,
            rewardGrantId: grant,
          );

      final base = key('session-1', 'stage-1', 'first_clear');
      final variants = [
        key('session-2', 'stage-1', 'first_clear'),
        key('session-1', 'stage-2', 'first_clear'),
        key('session-1', 'stage-1', 'repeat'),
      ];

      for (final variant in variants) {
        expect(variant, isNot(base));
        expect(variant.canonical, isNot(base.canonical));
      }
    });

    test('swapped component values stay distinct from each other', () {
      final swapped = RewardClaimKey.battleSessionGrant(
        battleSessionId: 'stage-1',
        stageId: 'session-1',
        rewardGrantId: 'first_clear',
      );
      final original = RewardClaimKey.battleSessionGrant(
        battleSessionId: 'session-1',
        stageId: 'stage-1',
        rewardGrantId: 'first_clear',
      );

      expect(swapped, isNot(original));
    });

    test('battle-session and run-choice kinds never collide', () {
      final battleKey = RewardClaimKey.battleSessionGrant(
        battleSessionId: 'x',
        stageId: 'y',
        rewardGrantId: 'z',
      );
      final runKey = RewardClaimKey.runChoice(runId: 'x', rewardChoiceId: 'y');

      expect(battleKey, isNot(runKey));
    });

    test('distinct runs and choices never collide', () {
      final a = RewardClaimKey.runChoice(runId: 'run-1', rewardChoiceId: 'c1');
      final b = RewardClaimKey.runChoice(runId: 'run-2', rewardChoiceId: 'c1');
      final c = RewardClaimKey.runChoice(runId: 'run-1', rewardChoiceId: 'c2');

      expect(a, isNot(b));
      expect(a, isNot(c));
      expect(b, isNot(c));
    });
  });

  group('non-empty validation', () {
    test('empty or blank battle-session components are rejected', () {
      expect(
        () => RewardClaimKey.battleSessionGrant(
          battleSessionId: '',
          stageId: 'stage-1',
          rewardGrantId: 'first_clear',
        ),
        throwsArgumentError,
      );
      expect(
        () => RewardClaimKey.battleSessionGrant(
          battleSessionId: 'session-1',
          stageId: '   ',
          rewardGrantId: 'first_clear',
        ),
        throwsArgumentError,
      );
      expect(
        () => RewardClaimKey.battleSessionGrant(
          battleSessionId: 'session-1',
          stageId: 'stage-1',
          rewardGrantId: '',
        ),
        throwsArgumentError,
      );
    });

    test('empty run-choice components are rejected', () {
      expect(
        () => RewardClaimKey.runChoice(runId: '', rewardChoiceId: 'choice-1'),
        throwsArgumentError,
      );
      expect(
        () => RewardClaimKey.runChoice(runId: 'run-1', rewardChoiceId: ''),
        throwsArgumentError,
      );
    });

    test('components containing the separator are rejected', () {
      expect(
        () => RewardClaimKey.runChoice(
          runId: 'run|1',
          rewardChoiceId: 'choice-1',
        ),
        throwsArgumentError,
      );
    });
  });

  group('versioning', () {
    test('canonical carries the current version prefix', () {
      final key = RewardClaimKey.runChoice(runId: 'r', rewardChoiceId: 'c');
      expect(key.canonical, startsWith('v${RewardClaimKey.currentVersion}|'));
      expect(key.version, RewardClaimKey.currentVersion);
    });

    test('parse rejects foreign versions instead of accepting them', () {
      expect(
        () => RewardClaimKey.parse('v2|runChoice|run-1|choice-1'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported reward claim key version'),
          ),
        ),
      );
    });

    test('parse rejects malformed canonicals fail-closed', () {
      expect(() => RewardClaimKey.parse(''), throwsFormatException);
      expect(() => RewardClaimKey.parse('garbage'), throwsFormatException);
      expect(
        () => RewardClaimKey.parse('vX|runChoice|run-1|choice-1'),
        throwsFormatException,
      );
      expect(
        () => RewardClaimKey.parse('v1|unknownKind|run-1'),
        throwsFormatException,
      );
      expect(
        () => RewardClaimKey.parse('v1|runChoice|run-1'),
        throwsFormatException,
      );
      expect(
        () => RewardClaimKey.parse('v1|battleSessionGrant|a|b|c|d'),
        throwsFormatException,
      );
      expect(
        () => RewardClaimKey.parse('v1|runChoice||choice-1'),
        throwsFormatException,
      );
    });
  });

  group('mentorInsight kind', () {
    test('same inputs produce equal keys with the mentorInsight canonical', () {
      final a = RewardClaimKey.mentorInsight(
        stageId: 'stage_01_03',
        characterId: 42,
      );
      final b = RewardClaimKey.mentorInsight(
        stageId: 'stage_01_03',
        characterId: 42,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.canonical, 'v1|mentorInsight|stage_01_03|42');
      expect(a.stageId, 'stage_01_03');
      expect(a.characterId, 42);
    });

    test('parse round-trips mentorInsight canonicals exactly', () {
      final key = RewardClaimKey.mentorInsight(
        stageId: 'stage_01_03',
        characterId: 42,
      );

      expect(RewardClaimKey.parse(key.canonical), key);
      expect(key.version, RewardClaimKey.currentVersion);
    });

    test('distinct stages or characters never collide', () {
      final base = RewardClaimKey.mentorInsight(
        stageId: 'stage_01_03',
        characterId: 42,
      );
      final otherStage = RewardClaimKey.mentorInsight(
        stageId: 'stage_01_04',
        characterId: 42,
      );
      final otherCharacter = RewardClaimKey.mentorInsight(
        stageId: 'stage_01_03',
        characterId: 43,
      );

      expect(otherStage, isNot(base));
      expect(otherCharacter, isNot(base));
      expect(otherStage.canonical, isNot(base.canonical));
      expect(otherCharacter.canonical, isNot(base.canonical));
    });

    test('mentorInsight never collides with other kinds', () {
      final mentorKey = RewardClaimKey.mentorInsight(
        stageId: 'x',
        characterId: 1,
      );
      final runKey = RewardClaimKey.runChoice(runId: 'x', rewardChoiceId: '1');
      final battleKey = RewardClaimKey.battleSessionGrant(
        battleSessionId: 'x',
        stageId: 'y',
        rewardGrantId: '1',
      );

      expect(mentorKey, isNot(runKey));
      expect(mentorKey, isNot(battleKey));
    });

    test('blank stageId and non-positive characterId are rejected', () {
      expect(
        () => RewardClaimKey.mentorInsight(stageId: '  ', characterId: 42),
        throwsArgumentError,
      );
      expect(
        () => RewardClaimKey.mentorInsight(
          stageId: 'stage_01_03',
          characterId: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => RewardClaimKey.mentorInsight(
          stageId: 'stage_01_03',
          characterId: -1,
        ),
        throwsArgumentError,
      );
    });

    test('parse rejects malformed mentorInsight canonicals fail-closed', () {
      expect(
        () => RewardClaimKey.parse('v1|mentorInsight|stage_01_03'),
        throwsFormatException,
      );
      expect(
        () => RewardClaimKey.parse('v1|mentorInsight|stage_01_03|42|extra'),
        throwsFormatException,
      );
      expect(
        () => RewardClaimKey.parse('v1|mentorInsight||42'),
        throwsFormatException,
      );
      expect(
        () => RewardClaimKey.parse('v1|mentorInsight|stage_01_03|0'),
        throwsFormatException,
      );
      expect(
        () => RewardClaimKey.parse('v1|mentorInsight|stage_01_03|x'),
        throwsFormatException,
      );
    });
  });
}
