import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/battle_shared/failure_policy.dart';
import 'package:wuxia_idle/shared/battle_shared/failure_policy_resolver.dart';

FailurePerformanceSnapshot _snapshot({
  double remainingHpRatio = 0.0,
  int contentDangerTier = 1,
  bool voluntarilyQuit = false,
}) => FailurePerformanceSnapshot(
  remainingHpRatio: remainingHpRatio,
  heavyHitsTaken: 0,
  unblockableHitsTaken: 0,
  knockdownCount: 0,
  postureBreakCount: 0,
  voluntarilyQuit: voluntarilyQuit,
  contentDangerTier: contentDangerTier,
);

FailurePolicyResolver _resolver() => FailurePolicyResolver(
  rules: {
    (
      contentKind: FailureContentKind.mainline,
      failureReason: FailureReason.defeat,
    ): FailureResolution.injury,
    (
      contentKind: FailureContentKind.tower,
      failureReason: FailureReason.defeat,
    ): FailureResolution.injury,
    (
      contentKind: FailureContentKind.innerDemon,
      failureReason: FailureReason.defeat,
    ): FailureResolution.disorder,
    (
      contentKind: FailureContentKind.mainline,
      failureReason: FailureReason.surrender,
    ): FailureResolution.partialReward,
    (
      contentKind: FailureContentKind.expedition,
      failureReason: FailureReason.aborted,
    ): FailureResolution.noPenalty,
  },
);

FailureClaimKey _key(
  String session,
  String participant, [
  FailureContentKind kind = FailureContentKind.mainline,
]) => FailureClaimKey(
  sessionId: session,
  participantId: participant,
  contentKind: kind,
);

void main() {
  group('FailurePolicyResolver 分支解析', () {
    test('规则表逐分支解析到四类决议', () {
      final resolver = _resolver();
      const branches = [
        (
          FailureContentKind.mainline,
          FailureReason.defeat,
          FailureResolution.injury,
        ),
        (
          FailureContentKind.tower,
          FailureReason.defeat,
          FailureResolution.injury,
        ),
        (
          FailureContentKind.innerDemon,
          FailureReason.defeat,
          FailureResolution.disorder,
        ),
        (
          FailureContentKind.mainline,
          FailureReason.surrender,
          FailureResolution.partialReward,
        ),
        (
          FailureContentKind.expedition,
          FailureReason.aborted,
          FailureResolution.noPenalty,
        ),
      ];

      for (final (kind, reason, expected) in branches) {
        expect(
          resolver
              .resolve(
                contentKind: kind,
                participantId: 'p1',
                sessionId: 's1',
                failureReason: reason,
                performanceSnapshot: _snapshot(),
              )
              .resolution,
          expected,
        );
      }
    });

    test('缺失规则 fail closed：诊断含分支键，不猜测惩罚', () {
      final resolver = _resolver();
      expect(
        () => resolver.resolve(
          contentKind: FailureContentKind.tower,
          participantId: 'p1',
          sessionId: 's1',
          failureReason: FailureReason.surrender,
          performanceSnapshot: _snapshot(),
        ),
        throwsA(
          isA<MissingFailurePolicyRuleError>()
              .having(
                (e) => e.contentKind,
                'contentKind',
                FailureContentKind.tower,
              )
              .having(
                (e) => e.failureReason,
                'failureReason',
                FailureReason.surrender,
              )
              .having(
                (e) => e.message,
                'message',
                allOf(contains('tower'), contains('surrender')),
              ),
        ),
      );
    });

    test('空规则表：任意分支都 fail closed', () {
      final resolver = FailurePolicyResolver(rules: const {});
      expect(
        () => resolver.resolve(
          contentKind: FailureContentKind.mainline,
          participantId: 'p1',
          sessionId: 's1',
          failureReason: FailureReason.defeat,
          performanceSnapshot: _snapshot(),
        ),
        throwsA(isA<MissingFailurePolicyRuleError>()),
      );
    });

    test('verdict 携带确定性索赔键，按三元组隔离', () {
      final resolver = _resolver();
      FailurePolicyVerdict resolve({
        required String sessionId,
        required String participantId,
        required FailureContentKind contentKind,
      }) => resolver.resolve(
        contentKind: contentKind,
        participantId: participantId,
        sessionId: sessionId,
        failureReason: FailureReason.defeat,
        performanceSnapshot: _snapshot(),
      );

      final a = resolve(
        sessionId: 's1',
        participantId: 'p1',
        contentKind: FailureContentKind.mainline,
      );
      final b = resolve(
        sessionId: 's1',
        participantId: 'p1',
        contentKind: FailureContentKind.mainline,
      );

      expect(a.claimKey, b.claimKey);
      expect(a.claimKey.value, 's1|p1|mainline');
      expect(
        resolve(
          sessionId: 's2',
          participantId: 'p1',
          contentKind: FailureContentKind.mainline,
        ).claimKey,
        isNot(a.claimKey),
      );
      expect(
        resolve(
          sessionId: 's1',
          participantId: 'p2',
          contentKind: FailureContentKind.mainline,
        ).claimKey,
        isNot(a.claimKey),
      );
      expect(
        resolve(
          sessionId: 's1',
          participantId: 'p1',
          contentKind: FailureContentKind.tower,
        ).claimKey,
        isNot(a.claimKey),
      );
    });

    test('解析不消费 performanceSnapshot（无 injury 权重）', () {
      final resolver = _resolver();
      final light = resolver.resolve(
        contentKind: FailureContentKind.mainline,
        participantId: 'p1',
        sessionId: 's1',
        failureReason: FailureReason.defeat,
        performanceSnapshot: _snapshot(
          remainingHpRatio: 0.8,
          contentDangerTier: 5,
        ),
      );
      final heavy = resolver.resolve(
        contentKind: FailureContentKind.mainline,
        participantId: 'p1',
        sessionId: 's1',
        failureReason: FailureReason.defeat,
        performanceSnapshot: _snapshot(
          remainingHpRatio: 0.0,
          contentDangerTier: 1,
        ),
      );

      expect(light.resolution, FailureResolution.injury);
      expect(heavy.resolution, FailureResolution.injury);
    });
  });

  group('FailureClaimLedger 索赔幂等', () {
    test('同键重复索赔被拒', () {
      final ledger = FailureClaimLedger();
      final k = _key('s1', 'p1');

      ledger.applySingle(
        claimKey: k,
        resolution: FailureResolution.injury,
        effect: (_) {},
      );
      expect(ledger.isClaimed(k), isTrue);
      expect(
        () => ledger.applySingle(
          claimKey: k,
          resolution: FailureResolution.injury,
          effect: (_) {},
        ),
        throwsA(
          isA<FailureClaimConflictError>().having(
            (e) => e.message,
            'message',
            contains('s1|p1|mainline'),
          ),
        ),
      );
    });

    test('效果抛错 → 不记账，重试可成功（回滚）', () {
      final ledger = FailureClaimLedger();
      final k = _key('s1', 'p1');

      expect(
        () => ledger.applySingle(
          claimKey: k,
          resolution: FailureResolution.injury,
          effect: (_) => throw StateError('apply failed'),
        ),
        throwsStateError,
      );
      expect(ledger.isClaimed(k), isFalse);

      // 失败不污染键：换正常效果重试成功。
      ledger.applySingle(
        claimKey: k,
        resolution: FailureResolution.injury,
        effect: (_) {},
      );
      expect(ledger.isClaimed(k), isTrue);
    });

    test('键隔离：不同 session / participant / kind 互不影响', () {
      final ledger = FailureClaimLedger();
      final a = _key('s1', 'p1');
      final b = _key('s1', 'p2');
      final c = _key('s2', 'p1');
      final d = _key('s1', 'p1', FailureContentKind.tower);

      ledger.applySingle(
        claimKey: a,
        resolution: FailureResolution.injury,
        effect: (_) {},
      );
      expect(ledger.isClaimed(b), isFalse);
      expect(ledger.isClaimed(c), isFalse);
      expect(ledger.isClaimed(d), isFalse);

      for (final k in [b, c, d]) {
        ledger.applySingle(
          claimKey: k,
          resolution: FailureResolution.disorder,
          effect: (_) {},
        );
      }
      expect(ledger.isClaimed(b), isTrue);
      expect(ledger.isClaimed(c), isTrue);
      expect(ledger.isClaimed(d), isTrue);
    });

    test('批量成功：全部记账且效果按序执行', () {
      final ledger = FailureClaimLedger();
      final applied = <FailureResolution>[];

      ledger.applyBatch([
        FailureBatchItem(
          claimKey: _key('s1', 'p1'),
          resolution: FailureResolution.injury,
          effect: applied.add,
        ),
        FailureBatchItem(
          claimKey: _key('s1', 'p2'),
          resolution: FailureResolution.disorder,
          effect: applied.add,
        ),
      ]);

      expect(applied, [FailureResolution.injury, FailureResolution.disorder]);
      expect(ledger.isClaimed(_key('s1', 'p1')), isTrue);
      expect(ledger.isClaimed(_key('s1', 'p2')), isTrue);
    });

    test('批量中任一效果失败 → 全部键不记账（记账原子性）', () {
      final ledger = FailureClaimLedger();
      final applied = <String>[];

      expect(
        () => ledger.applyBatch([
          FailureBatchItem(
            claimKey: _key('s1', 'p1'),
            resolution: FailureResolution.injury,
            effect: (_) => applied.add('p1'),
          ),
          FailureBatchItem(
            claimKey: _key('s1', 'p2'),
            resolution: FailureResolution.disorder,
            effect: (_) => throw StateError('boom'),
          ),
          FailureBatchItem(
            claimKey: _key('s1', 'p3'),
            resolution: FailureResolution.noPenalty,
            effect: (_) => applied.add('p3'),
          ),
        ]),
        throwsStateError,
      );

      expect(ledger.isClaimed(_key('s1', 'p1')), isFalse);
      expect(ledger.isClaimed(_key('s1', 'p2')), isFalse);
      expect(ledger.isClaimed(_key('s1', 'p3')), isFalse);

      // 记账原子性保证失败后整批可重放（效果目标事务性由调用方 outbox 负责）。
      ledger.applyBatch([
        FailureBatchItem(
          claimKey: _key('s1', 'p1'),
          resolution: FailureResolution.injury,
          effect: (_) {},
        ),
        FailureBatchItem(
          claimKey: _key('s1', 'p2'),
          resolution: FailureResolution.disorder,
          effect: (_) {},
        ),
        FailureBatchItem(
          claimKey: _key('s1', 'p3'),
          resolution: FailureResolution.noPenalty,
          effect: (_) {},
        ),
      ]);
      expect(ledger.isClaimed(_key('s1', 'p1')), isTrue);
      expect(ledger.isClaimed(_key('s1', 'p2')), isTrue);
      expect(ledger.isClaimed(_key('s1', 'p3')), isTrue);
    });

    test('批量预校验：批内重复或已结算键在效果执行前拒绝', () {
      final ledger = FailureClaimLedger();
      var effectsRan = 0;
      final alreadySettled = _key('s1', 'p1');
      ledger.applySingle(
        claimKey: alreadySettled,
        resolution: FailureResolution.injury,
        effect: (_) {},
      );

      expect(
        () => ledger.applyBatch([
          FailureBatchItem(
            claimKey: alreadySettled,
            resolution: FailureResolution.injury,
            effect: (_) => effectsRan++,
          ),
          FailureBatchItem(
            claimKey: _key('s1', 'p2'),
            resolution: FailureResolution.disorder,
            effect: (_) => effectsRan++,
          ),
        ]),
        throwsA(isA<FailureClaimConflictError>()),
      );
      expect(effectsRan, 0);

      expect(
        () => ledger.applyBatch([
          FailureBatchItem(
            claimKey: _key('s1', 'p2'),
            resolution: FailureResolution.disorder,
            effect: (_) => effectsRan++,
          ),
          FailureBatchItem(
            claimKey: _key('s1', 'p2'),
            resolution: FailureResolution.disorder,
            effect: (_) => effectsRan++,
          ),
        ]),
        throwsA(isA<FailureClaimConflictError>()),
      );
      expect(effectsRan, 0);
    });
  });
}
