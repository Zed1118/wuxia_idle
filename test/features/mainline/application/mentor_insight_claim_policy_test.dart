import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/application/mentor_insight_claim_policy.dart';
import 'package:wuxia_idle/features/mainline/domain/mentor_insight_policy.dart';

import '../../../support/dart_source_contract.dart';

MentorInsightClaimKey key({
  String stageId = 'stage_01_03',
  int characterId = 42,
}) => MentorInsightClaimKey(stageId: stageId, characterId: characterId);

void main() {
  group('MentorInsightClaimKey 幂等键', () {
    test('同 (stageId, characterId) 恒同键且规范串确定', () {
      final a = key();
      final b = key();
      expect(a.canonical, 'v1|mentorInsight|stage_01_03|42');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), a.canonical);
    });

    test('不同门人或不同关是不同键', () {
      expect(key(characterId: 43), isNot(key()));
      expect(key(stageId: 'stage_01_04'), isNot(key()));
    });

    test('规范串 round-trip 解析', () {
      final parsed = MentorInsightClaimKey.parse(key().canonical);
      expect(parsed, key());
    });

    test('组件校验：空 stageId / 分隔符 / 非正角色 id 拒绝', () {
      expect(() => key(stageId: '  '), throwsArgumentError);
      expect(() => key(stageId: 'a|b'), throwsArgumentError);
      expect(() => key(characterId: 0), throwsArgumentError);
      expect(() => key(characterId: -1), throwsArgumentError);
    });

    test('未知版本 / 畸形 / 错误 kind / 组件数 fail closed', () {
      expect(
        () => MentorInsightClaimKey.parse('v2|mentorInsight|s|1'),
        throwsFormatException,
      );
      expect(
        () => MentorInsightClaimKey.parse('noprefix|s|1'),
        throwsFormatException,
      );
      expect(
        () => MentorInsightClaimKey.parse('v1|other|s|1'),
        throwsFormatException,
      );
      expect(
        () => MentorInsightClaimKey.parse('v1|mentorInsight|s'),
        throwsFormatException,
      );
      expect(
        () => MentorInsightClaimKey.parse('v1|mentorInsight|s|1|extra'),
        throwsFormatException,
      );
      expect(
        () => MentorInsightClaimKey.parse('v1|mentorInsight||1'),
        throwsFormatException,
      );
      expect(
        () => MentorInsightClaimKey.parse('v1|mentorInsight|s|0'),
        throwsFormatException,
      );
      expect(
        () => MentorInsightClaimKey.parse('v1|mentorInsight|s|x'),
        throwsFormatException,
      );
    });
  });

  group('MentorInsightClaimPolicy 声明', () {
    test('成长对象仅主修招式熟练度（RATE-01）', () {
      expect(
        MentorInsightClaimPolicy.growthTarget,
        MentorInsightGrowthTarget.mainTechniqueProficiency,
      );
    });

    test('个人作用域 + 仅首通（CORE-01 不重复发放）', () {
      expect(MentorInsightClaimPolicy.personalScope, isTrue);
      expect(MentorInsightClaimPolicy.firstClearOnly, isTrue);
    });

    test('非首通 fail closed，不猜测重打 / 扫荡发放', () {
      expect(
        () => MentorInsightClaimPolicy.enforceFirstClear(false),
        throwsA(isA<MentorInsightNotFirstClearException>()),
      );
      expect(
        () => MentorInsightClaimPolicy.enforceFirstClear(true),
        returnsNormally,
      );
    });
  });

  group('MentorInsightClaimLedger 首通幂等发放', () {
    test('首通发放一次并记账', () {
      final ledger = MentorInsightClaimLedger();
      final granted = <MentorInsightGrowthTarget>[];
      ledger.claimFirstClear(
        key: key(),
        isFirstClear: true,
        grant: (target) => granted.add(target),
      );
      expect(granted, [MentorInsightGrowthTarget.mainTechniqueProficiency]);
      expect(ledger.isClaimed(key()), isTrue);
    });

    test('同键重复发放被拒，不重复执行 grant（不重复发放）', () {
      final ledger = MentorInsightClaimLedger();
      var grants = 0;
      ledger.claimFirstClear(
        key: key(),
        isFirstClear: true,
        grant: (_) => grants++,
      );
      expect(
        () => ledger.claimFirstClear(
          key: key(),
          isFirstClear: true,
          grant: (_) => grants++,
        ),
        throwsA(isA<MentorInsightClaimConflictException>()),
      );
      expect(grants, 1);
    });

    test('重打 / 扫荡（非首通）一律拒绝，不记账', () {
      final ledger = MentorInsightClaimLedger();
      var grants = 0;
      expect(
        () => ledger.claimFirstClear(
          key: key(),
          isFirstClear: false,
          grant: (_) => grants++,
        ),
        throwsA(isA<MentorInsightNotFirstClearException>()),
      );
      expect(grants, 0);
      expect(ledger.isClaimed(key()), isFalse);
    });

    test('grant 回调抛错不记账，可重试', () {
      final ledger = MentorInsightClaimLedger();
      expect(
        () => ledger.claimFirstClear(
          key: key(),
          isFirstClear: true,
          grant: (_) => throw StateError('grant failed'),
        ),
        throwsStateError,
      );
      expect(ledger.isClaimed(key()), isFalse);
      ledger.claimFirstClear(key: key(), isFirstClear: true, grant: (_) {});
      expect(ledger.isClaimed(key()), isTrue);
    });

    test('幂等恢复结算：已发放则 no-op，未发放才发放', () {
      final ledger = MentorInsightClaimLedger();
      var grants = 0;
      expect(
        ledger.settleIdempotently(
          key: key(),
          isFirstClear: true,
          grant: (_) => grants++,
        ),
        isTrue,
      );
      expect(grants, 1);
      expect(
        ledger.settleIdempotently(
          key: key(),
          isFirstClear: true,
          grant: (_) => grants++,
        ),
        isFalse,
      );
      expect(grants, 1);
    });

    test('幂等恢复结算同样受首通闸门约束', () {
      final ledger = MentorInsightClaimLedger();
      expect(
        () => ledger.settleIdempotently(
          key: key(),
          isFirstClear: false,
          grant: (_) {},
        ),
        throwsA(isA<MentorInsightNotFirstClearException>()),
      );
      expect(ledger.isClaimed(key()), isFalse);
    });

    test('不同 (关, 门人) 键互不干扰', () {
      final ledger = MentorInsightClaimLedger();
      ledger.claimFirstClear(key: key(), isFirstClear: true, grant: (_) {});
      expect(
        ledger.settleIdempotently(
          key: key(characterId: 43),
          isFirstClear: true,
          grant: (_) {},
        ),
        isTrue,
      );
      expect(
        ledger.settleIdempotently(
          key: key(stageId: 'stage_01_04'),
          isFirstClear: true,
          grant: (_) {},
        ),
        isTrue,
      );
    });
  });

  group('纯合同边界：claim 合同无生产发放 / 存储', () {
    test('claim 合同文件不依赖 Isar / 存储 / schema', () async {
      final source = await File(
        'lib/features/mainline/application/mentor_insight_claim_policy.dart',
      ).readAsString();
      expect(source, isNot(contains('package:isar')));
      expect(source, isNot(contains('@collection')));
      expect(source, isNot(contains('SaveData')));
      expect(source, isNot(contains('saveDataId')));
      expect(source, isNot(contains('Isar')));
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
