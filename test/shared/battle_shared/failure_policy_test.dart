import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/battle_shared/failure_policy.dart';

void main() {
  group('FailurePerformanceSnapshot 输入校验', () {
    FailurePerformanceSnapshot build({
      double remainingHpRatio = 0.5,
      int heavyHitsTaken = 0,
      int unblockableHitsTaken = 0,
      int knockdownCount = 0,
      int postureBreakCount = 0,
      bool voluntarilyQuit = false,
      int contentDangerTier = 1,
    }) => FailurePerformanceSnapshot(
      remainingHpRatio: remainingHpRatio,
      heavyHitsTaken: heavyHitsTaken,
      unblockableHitsTaken: unblockableHitsTaken,
      knockdownCount: knockdownCount,
      postureBreakCount: postureBreakCount,
      voluntarilyQuit: voluntarilyQuit,
      contentDangerTier: contentDangerTier,
    );

    test('合法输入原样透出全部字段', () {
      final snapshot = build(
        remainingHpRatio: 0.05,
        heavyHitsTaken: 3,
        unblockableHitsTaken: 1,
        knockdownCount: 2,
        postureBreakCount: 1,
        voluntarilyQuit: true,
        contentDangerTier: 2,
      );

      expect(snapshot.remainingHpRatio, 0.05);
      expect(snapshot.heavyHitsTaken, 3);
      expect(snapshot.unblockableHitsTaken, 1);
      expect(snapshot.knockdownCount, 2);
      expect(snapshot.postureBreakCount, 1);
      expect(snapshot.voluntarilyQuit, isTrue);
      expect(snapshot.contentDangerTier, 2);
    });

    test('剩余生命比例越界 [0,1] 拒绝', () {
      expect(() => build(remainingHpRatio: -0.01), throwsArgumentError);
      expect(() => build(remainingHpRatio: 1.01), throwsArgumentError);
      expect(() => build(remainingHpRatio: double.nan), throwsArgumentError);
      expect(
        () => build(remainingHpRatio: double.infinity),
        throwsArgumentError,
      );
    });

    test('负计数与低于 1 的危险档拒绝', () {
      expect(() => build(heavyHitsTaken: -1), throwsArgumentError);
      expect(() => build(unblockableHitsTaken: -1), throwsArgumentError);
      expect(() => build(knockdownCount: -1), throwsArgumentError);
      expect(() => build(postureBreakCount: -1), throwsArgumentError);
      expect(() => build(contentDangerTier: 0), throwsArgumentError);
    });

    test('边界值通过：0.0 / 1.0 生命比例、零计数、危险档 1', () {
      expect(() => build(remainingHpRatio: 0.0), returnsNormally);
      expect(() => build(remainingHpRatio: 1.0), returnsNormally);
      expect(() => build(contentDangerTier: 1), returnsNormally);
    });
  });

  group('FailureClaimKey 幂等键', () {
    test('同三元组确定性、非空且含全部作用域片段', () {
      final a = FailureClaimKey(
        sessionId: 's1',
        participantId: 'p42',
        contentKind: FailureContentKind.mainline,
      );
      final b = FailureClaimKey(
        sessionId: 's1',
        participantId: 'p42',
        contentKind: FailureContentKind.mainline,
      );

      expect(a.value, b.value);
      expect(a.value, isNotEmpty);
      expect(a.value, contains('s1'));
      expect(a.value, contains('p42'));
      expect(a.value, contains(FailureContentKind.mainline.name));
    });

    test('任一作用域分量变化 → 键变化', () {
      const base = 's1|p42|mainline';

      expect(
        FailureClaimKey(
          sessionId: 's2',
          participantId: 'p42',
          contentKind: FailureContentKind.mainline,
        ).value,
        isNot(base),
      );
      expect(
        FailureClaimKey(
          sessionId: 's1',
          participantId: 'p43',
          contentKind: FailureContentKind.mainline,
        ).value,
        isNot(base),
      );
      expect(
        FailureClaimKey(
          sessionId: 's1',
          participantId: 'p42',
          contentKind: FailureContentKind.tower,
        ).value,
        isNot(base),
      );
    });

    test('键不含 failureReason（重试换原因仍是同一次索赔）', () {
      // 键由 sessionId+participantId+contentKind 三元组构成，failureReason
      // 不进入作用域：同一挑战 session 内重试只结一次伤势。
      final a = FailureClaimKey(
        sessionId: 's1',
        participantId: 'p42',
        contentKind: FailureContentKind.mainline,
      );
      final b = FailureClaimKey(
        sessionId: 's1',
        participantId: 'p42',
        contentKind: FailureContentKind.mainline,
      );
      expect(a.value, b.value);
    });

    test('trim 规范化，空白输入拒绝', () {
      expect(
        FailureClaimKey(
          sessionId: '  s1 ',
          participantId: ' p42 ',
          contentKind: FailureContentKind.mainline,
        ).value,
        's1|p42|mainline',
      );
      expect(
        () => FailureClaimKey(
          sessionId: '',
          participantId: 'p42',
          contentKind: FailureContentKind.mainline,
        ),
        throwsA(isA<InvalidFailureClaimKeyError>()),
      );
      expect(
        () => FailureClaimKey(
          sessionId: '   ',
          participantId: 'p42',
          contentKind: FailureContentKind.mainline,
        ),
        throwsA(isA<InvalidFailureClaimKeyError>()),
      );
      expect(
        () => FailureClaimKey(
          sessionId: 's1',
          participantId: '',
          contentKind: FailureContentKind.mainline,
        ),
        throwsA(isA<InvalidFailureClaimKeyError>()),
      );
      expect(
        () => FailureClaimKey(
          sessionId: 's1',
          participantId: '  ',
          contentKind: FailureContentKind.mainline,
        ),
        throwsA(isA<InvalidFailureClaimKeyError>()),
      );
      expect(
        () => FailureClaimKey(
          sessionId: 's1|p42',
          participantId: 'mainline',
          contentKind: FailureContentKind.mainline,
        ),
        throwsA(isA<InvalidFailureClaimKeyError>()),
      );
    });

    test('值相等性与 hashCode 一致', () {
      final a = FailureClaimKey(
        sessionId: 's1',
        participantId: 'p42',
        contentKind: FailureContentKind.mainline,
      );
      final b = FailureClaimKey(
        sessionId: 's1',
        participantId: 'p42',
        contentKind: FailureContentKind.mainline,
      );
      final c = FailureClaimKey(
        sessionId: 's1',
        participantId: 'p42',
        contentKind: FailureContentKind.tower,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
