import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/domain/phase0a/posture.dart';

void main() {
  group('PostureConfig', () {
    test(
      'rejects non-positive capacity and invalid vulnerability duration',
      () {
        expect(
          () => PostureConfig(
            capacity: 0,
            vulnerabilityTicks: 2,
            recoveryPolicy: PostureRecoveryPolicy.reset,
            postVulnerabilityAccumulated: 0,
          ),
          throwsArgumentError,
        );
        expect(
          () => PostureConfig(
            capacity: 10,
            vulnerabilityTicks: 0,
            recoveryPolicy: PostureRecoveryPolicy.reset,
            postVulnerabilityAccumulated: 0,
          ),
          throwsArgumentError,
        );
      },
    );

    test('rejects recovery target outside capacity', () {
      expect(
        () => PostureConfig(
          capacity: 10,
          vulnerabilityTicks: 2,
          recoveryPolicy: PostureRecoveryPolicy.recover,
          postVulnerabilityAccumulated: 11,
        ),
        throwsArgumentError,
      );
    });
  });

  group('PostureStateMachine', () {
    final resetConfig = PostureConfig(
      capacity: 10,
      vulnerabilityTicks: 2,
      recoveryPolicy: PostureRecoveryPolicy.reset,
      postVulnerabilityAccumulated: 0,
    );

    test(
      'accumulates from zero and enters vulnerability at the exact boundary',
      () {
        final first = PostureState.initial(resetConfig).apply(4);
        final second = first.state.apply(6);

        expect(first.state.accumulated, 4);
        expect(first.state.isVulnerable, isFalse);
        expect(second.state.accumulated, 10);
        expect(second.state.isVulnerable, isTrue);
        expect(
          second.events.map((event) => event.type),
          contains(PostureEventType.vulnerabilityEntered),
        );
      },
    );

    test('clips over-capacity damage and emits the overflow event', () {
      final transition = PostureState.initial(resetConfig).apply(13);

      expect(transition.state.accumulated, 10);
      expect(
        transition.events
            .singleWhere(
              (event) => event.type == PostureEventType.postureDamageApplied,
            )
            .amount,
        10,
      );
      expect(
        transition.events
            .singleWhere(
              (event) => event.type == PostureEventType.postureDamageOverflow,
            )
            .amount,
        3,
      );
    });

    test(
      'poise still accumulates posture but ignores a light-hit interruption',
      () {
        final transition = PostureState.initial(
          resetConfig,
        ).apply(3, hitKind: PostureHitKind.light, hasPoise: true);

        expect(transition.state.accumulated, 3);
        expect(
          transition.events,
          contains(const PostureEvent(PostureEventType.lightHitIgnoredByPoise)),
        );
      },
    );

    test('damage during vulnerability cannot retrigger it', () {
      final exposed = PostureState.initial(resetConfig).apply(10).state;
      final transition = exposed.apply(9);

      expect(transition.state, exposed);
      expect(
        transition.events,
        contains(
          const PostureEvent(
            PostureEventType.postureDamageSuppressedDuringVulnerability,
          ),
        ),
      );
      expect(
        transition.events.where(
          (event) => event.type == PostureEventType.vulnerabilityEntered,
        ),
        isEmpty,
      );
    });

    test('ends vulnerability and resets according to injected policy', () {
      final exposed = PostureState.initial(resetConfig).apply(10).state;
      final transition = exposed.advance(2);

      expect(transition.state.isVulnerable, isFalse);
      expect(transition.state.accumulated, 0);
      expect(
        transition.events.map((event) => event.type),
        containsAll(<PostureEventType>[
          PostureEventType.vulnerabilityEnded,
          PostureEventType.postureReset,
        ]),
      );
    });

    test('ends vulnerability at the configured recovered posture', () {
      final config = PostureConfig(
        capacity: 12,
        vulnerabilityTicks: 3,
        recoveryPolicy: PostureRecoveryPolicy.recover,
        postVulnerabilityAccumulated: 5,
      );
      final transition = PostureState.initial(
        config,
      ).apply(12).state.advance(3);

      expect(transition.state.accumulated, 5);
      expect(transition.state.isVulnerable, isFalse);
      expect(
        transition.events,
        contains(
          const PostureEvent(PostureEventType.postureRecovered, amount: 5),
        ),
      );
    });
  });

  test(
    'converts Boss control strength to posture damage as a pure function',
    () {
      expect(bossControlToPostureDamage(7, conversionFactor: 0.25), 1.75);
      expect(
        () => bossControlToPostureDamage(-1, conversionFactor: 0.25),
        throwsArgumentError,
      );
    },
  );

  test('same state and input produce equal deterministic transitions', () {
    final config = PostureConfig(
      capacity: 17,
      vulnerabilityTicks: 4,
      recoveryPolicy: PostureRecoveryPolicy.reset,
      postVulnerabilityAccumulated: 0,
    );
    final state = PostureState.initial(config);

    expect(state.apply(6), state.apply(6));
  });
}
