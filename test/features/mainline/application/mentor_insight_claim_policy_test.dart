import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/application/mentor_insight_claim_policy.dart';
import 'package:wuxia_idle/features/mainline/domain/mentor_insight_policy.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_policy.dart';

import '../../../support/dart_source_contract.dart';

void main() {
  group('MentorInsightClaimPolicy 决策表（调用方事实 → grant/skip/fail-closed）', () {
    test('首通且 durable 未 claim → grant', () {
      expect(
        MentorInsightClaimPolicy.decide(
          isFirstClear: true,
          externallyDurablyClaimed: false,
        ),
        MentorInsightClaimOutcome.grant,
      );
    });

    test('首通但 durable 已 claim → skip（不重复发放）', () {
      expect(
        MentorInsightClaimPolicy.decide(
          isFirstClear: true,
          externallyDurablyClaimed: true,
        ),
        MentorInsightClaimOutcome.skip,
      );
    });

    test('非首通一律 fail closed，不猜测重打 / 扫荡发放', () {
      expect(
        MentorInsightClaimPolicy.decide(
          isFirstClear: false,
          externallyDurablyClaimed: false,
        ),
        MentorInsightClaimOutcome.failClosed,
      );
      expect(
        MentorInsightClaimPolicy.decide(
          isFirstClear: false,
          externallyDurablyClaimed: true,
        ),
        MentorInsightClaimOutcome.failClosed,
      );
    });

    test('decide 为纯函数：同输入恒同输出，无副作用', () {
      const inputs = [
        (isFirstClear: true, claimed: false),
        (isFirstClear: true, claimed: true),
        (isFirstClear: false, claimed: false),
        (isFirstClear: false, claimed: true),
      ];
      for (final input in inputs) {
        final a = MentorInsightClaimPolicy.decide(
          isFirstClear: input.isFirstClear,
          externallyDurablyClaimed: input.claimed,
        );
        final b = MentorInsightClaimPolicy.decide(
          isFirstClear: input.isFirstClear,
          externallyDurablyClaimed: input.claimed,
        );
        expect(a, b);
      }
    });

    test('决策面不消费 release reason：释放与成长解耦，失败/退出不自动成长', () {
      // 合同层面 decide 输入只有 isFirstClear + externallyDurablyClaimed，
      // 不接收 release reason —— 四种结算一律释放占用，与 grant eligibility
      // 完全解耦；失败 / 主动退出不会自动触发成长（宿主不会以非首通调 grant）。
      expect(
        MentorInsightClaimPolicy.decide(
          isFirstClear: false,
          externallyDurablyClaimed: false,
        ),
        MentorInsightClaimOutcome.failClosed,
      );
    });

    test('声明：成长对象仅主修招式熟练度（RATE-01）', () {
      expect(
        MentorInsightClaimPolicy.growthTarget,
        MentorInsightGrowthTarget.mainTechniqueProficiency,
      );
    });

    test('声明：个人作用域 + 仅首通（CORE-01 不重复发放）', () {
      expect(MentorInsightClaimPolicy.personalScope, isTrue);
      expect(MentorInsightClaimPolicy.firstClearOnly, isTrue);
    });
  });

  group('共享 RewardClaimKey mentorInsight 键（复用 shared canonical/parser）', () {
    test('claim 键由 shared 构造与解析，键形 stageId + characterId', () {
      final key = RewardClaimKey.mentorInsight(
        stageId: 'stage_01_03',
        characterId: 42,
      );
      expect(key.canonical, 'v1|mentorInsight|stage_01_03|42');
      expect(RewardClaimKey.parse(key.canonical), key);
      expect(key.stageId, 'stage_01_03');
      expect(key.characterId, 42);
    });
  });

  group('shared RewardGrantGuard 重复拒绝纪律演示', () {
    test('进程内 guard 拒绝同键重复（不重复发放纪律）', () {
      final guard = RewardGrantGuard();
      final key = RewardClaimKey.mentorInsight(
        stageId: 'stage_01_03',
        characterId: 42,
      );

      expect(guard.claim(key: key, apply: () => 'granted'), 'granted');
      expect(guard.isClaimed(key), isTrue);
      expect(
        () => guard.claim(key: key, apply: () => 'granted again'),
        throwsA(isA<RewardAlreadyClaimedException>()),
      );
    });

    test('RewardGrantGuard 仅内存态，不代表 durable storage', () {
      final guardA = RewardGrantGuard();
      final guardB = RewardGrantGuard();
      final key = RewardClaimKey.mentorInsight(
        stageId: 'stage_01_03',
        characterId: 42,
      );

      guardA.claim(key: key, apply: () => null);

      // 新实例不继承任何 claim 状态：guard 只是进程内重复拒绝纪律演示，
      // 生产 exactly-once 必须依赖宿主 durable claim 层，本合同不拥有 ledger、
      // 不声称持久化。
      expect(guardB.isClaimed(key), isFalse);
    });
  });

  group('纯合同边界：无生产发放 / 存储 / 第二套 codec', () {
    test('claim 合同文件无 Isar / 存储 / schema / UI 依赖', () async {
      final source = await File(
        'lib/features/mainline/application/mentor_insight_claim_policy.dart',
      ).readAsString();
      expect(source, isNot(contains('package:isar')));
      expect(source, isNot(contains('@collection')));
      expect(source, isNot(contains('SaveData')));
      expect(source, isNot(contains('saveDataId')));
      expect(source, isNot(contains('Isar')));
    });

    test('claim 合同无第二套 codec：不自造键 / parser / ledger', () async {
      final source = await File(
        'lib/features/mainline/application/mentor_insight_claim_policy.dart',
      ).readAsString();
      expect(source, isNot(contains('MentorInsightClaimKey')));
      expect(source, isNot(contains('Ledger')));
      expect(source, isNot(contains('parse(')));
      expect(source, isNot(contains('componentSeparator')));
      expect(source, isNot(contains('versionPrefix')));
    });

    test('claim 合同无比例 / 每关 cap / 金额成员', () async {
      final contract = DartSourceContract.parse(
        await File(
          'lib/features/mainline/application/mentor_insight_claim_policy.dart',
        ).readAsString(),
        path:
            'lib/features/mainline/application/mentor_insight_claim_policy.dart',
      );
      expect(contract.memberAccessCount('rate'), 0);
      expect(contract.memberAccessCount('cap'), 0);
      expect(contract.memberAccessCount('amount'), 0);
      expect(contract.memberAccessCount('pct'), 0);
      expect(contract.memberAccessCount('percent'), 0);
    });
  });
}
