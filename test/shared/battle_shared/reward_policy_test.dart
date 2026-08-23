import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_policy.dart';

RewardClaimKey battleKey(String grantId, {String stageId = 'stage-1'}) {
  return RewardClaimKey.battleSessionGrant(
    battleSessionId: 'session-1',
    stageId: stageId,
    rewardGrantId: grantId,
  );
}

void main() {
  group('RewardPolicy', () {
    test('every layer can express sect-shared or personal scope', () {
      final policy = RewardPolicy(
        scopeByLayer: {
          RewardLayer.firstClear: RewardScope.sectShared,
          RewardLayer.repeat: RewardScope.personal,
          RewardLayer.personalGrowth: RewardScope.personal,
        },
      );

      expect(policy.scopeOf(RewardLayer.firstClear), RewardScope.sectShared);
      expect(policy.scopeOf(RewardLayer.repeat), RewardScope.personal);
      expect(policy.scopeOf(RewardLayer.personalGrowth), RewardScope.personal);
    });

    test('a fully personal table is equally expressible', () {
      final policy = RewardPolicy(
        scopeByLayer: const {
          RewardLayer.firstClear: RewardScope.personal,
          RewardLayer.repeat: RewardScope.personal,
          RewardLayer.personalGrowth: RewardScope.personal,
        },
      );

      for (final layer in RewardLayer.values) {
        expect(policy.scopeOf(layer), RewardScope.personal);
      }
    });

    test('partial tables fail closed instead of defaulting', () {
      expect(
        () => RewardPolicy(
          scopeByLayer: const {RewardLayer.firstClear: RewardScope.sectShared},
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            allOf(contains('repeat'), contains('personalGrowth')),
          ),
        ),
      );
    });

    test('the scope table is immutable', () {
      final policy = RewardPolicy(
        scopeByLayer: const {
          RewardLayer.firstClear: RewardScope.sectShared,
          RewardLayer.repeat: RewardScope.personal,
          RewardLayer.personalGrowth: RewardScope.personal,
        },
      );

      expect(
        () =>
            policy.scopeByLayer[RewardLayer.firstClear] = RewardScope.personal,
        throwsUnsupportedError,
      );
    });
  });

  group('RewardGrantGuard duplicate rejection', () {
    test('a claimed key is rejected without running the callback', () {
      final guard = RewardGrantGuard();
      final key = battleKey('first_clear');
      var applyCount = 0;

      final first = guard.claim(
        key: key,
        apply: () {
          applyCount++;
          return 'granted';
        },
      );

      expect(first, 'granted');
      expect(guard.isClaimed(key), isTrue);
      expect(
        () => guard.claim(
          key: key,
          apply: () {
            applyCount++;
            return 'granted again';
          },
        ),
        throwsA(
          isA<RewardAlreadyClaimedException>().having((e) => e.key, 'key', key),
        ),
      );
      expect(applyCount, 1);
    });

    test('keys isolated by stage, grant id and kind stay claimable', () {
      final guard = RewardGrantGuard();
      guard.claim(key: battleKey('first_clear'), apply: () => null);

      final otherStage = battleKey('first_clear', stageId: 'stage-2');
      final otherGrant = battleKey('repeat');
      final runKey = RewardClaimKey.runChoice(
        runId: 'run-1',
        rewardChoiceId: 'choice-1',
      );

      expect(guard.isClaimed(otherStage), isFalse);
      expect(guard.isClaimed(otherGrant), isFalse);
      expect(guard.isClaimed(runKey), isFalse);
      expect(
        () => guard.claim(key: otherStage, apply: () => null),
        returnsNormally,
      );
      expect(
        () => guard.claim(key: otherGrant, apply: () => null),
        returnsNormally,
      );
      expect(
        () => guard.claim(key: runKey, apply: () => null),
        returnsNormally,
      );
    });

    test('separate guard instances are scope-isolated', () {
      final sectSharedGuard = RewardGrantGuard();
      final personalGuard = RewardGrantGuard();
      final key = battleKey('first_clear');

      sectSharedGuard.claim(key: key, apply: () => null);

      expect(sectSharedGuard.isClaimed(key), isTrue);
      expect(personalGuard.isClaimed(key), isFalse);
    });
  });

  group('RewardGrantGuard failure rollback', () {
    test('a throwing apply never marks the key claimed', () {
      final guard = RewardGrantGuard();
      final key = battleKey('first_clear');

      expect(
        () => guard.claim(
          key: key,
          apply: () => throw StateError('grant failed'),
        ),
        throwsStateError,
      );
      expect(guard.isClaimed(key), isFalse);

      expect(guard.claim(key: key, apply: () => 'recovered'), 'recovered');
      expect(guard.isClaimed(key), isTrue);
    });
  });

  group('RewardGrantGuard batch atomicity', () {
    test('a successful batch commits every key', () {
      final guard = RewardGrantGuard();
      final keys = [battleKey('first_clear'), battleKey('repeat')];

      final results = guard.claimBatch([
        RewardGrantEntry(key: keys[0], apply: () => 10),
        RewardGrantEntry(key: keys[1], apply: () => 20),
      ]);

      expect(results, [10, 20]);
      expect(keys.every(guard.isClaimed), isTrue);
    });

    test('a throwing callback inside the batch leaves no key claimed', () {
      final guard = RewardGrantGuard();
      final keys = [battleKey('first_clear'), battleKey('repeat')];
      final applied = <String>[];

      expect(
        () => guard.claimBatch([
          RewardGrantEntry(
            key: keys[0],
            apply: () {
              applied.add('first');
              return 1;
            },
          ),
          RewardGrantEntry<int>(
            key: keys[1],
            apply: () => throw StateError('second grant failed'),
          ),
        ]),
        throwsStateError,
      );

      expect(applied, ['first']);
      expect(guard.isClaimed(keys[0]), isFalse);
      expect(guard.isClaimed(keys[1]), isFalse);

      expect(guard.claim(key: keys[0], apply: () => 'retry-ok'), 'retry-ok');
    });

    test('a batch hitting an already-claimed key rejects everything', () {
      final guard = RewardGrantGuard();
      final claimed = battleKey('first_clear');
      guard.claim(key: claimed, apply: () => null);

      final fresh = battleKey('repeat');
      var applied = 0;

      expect(
        () => guard.claimBatch([
          RewardGrantEntry(
            key: fresh,
            apply: () {
              applied++;
              return 1;
            },
          ),
          RewardGrantEntry(
            key: claimed,
            apply: () {
              applied++;
              return 2;
            },
          ),
        ]),
        throwsA(isA<RewardAlreadyClaimedException>()),
      );

      expect(applied, 0);
      expect(guard.isClaimed(fresh), isFalse);
    });

    test('duplicate keys inside one batch reject the whole batch', () {
      final guard = RewardGrantGuard();
      final key = battleKey('first_clear');
      var applied = 0;

      expect(
        () => guard.claimBatch([
          RewardGrantEntry(
            key: key,
            apply: () {
              applied++;
              return 1;
            },
          ),
          RewardGrantEntry(
            key: key,
            apply: () {
              applied++;
              return 2;
            },
          ),
        ]),
        throwsA(isA<RewardAlreadyClaimedException>()),
      );

      expect(applied, 0);
      expect(guard.isClaimed(key), isFalse);
    });

    test('an empty batch claims nothing and returns no results', () {
      final guard = RewardGrantGuard();
      expect(guard.claimBatch<int>(const []), isEmpty);
    });
  });
}
