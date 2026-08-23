import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/domain/mentor_insight_policy.dart';

import '../../../support/dart_source_contract.dart';

void main() {
  group('MENTOR-INSIGHT-CORE-01 首通可随行 0-1 名门人', () {
    test('随行选择允许 0 名（不随行）与 1 名门人', () {
      final none = MentorInsightChoice(stageId: 'stage_01_03');
      expect(none.menteeCharacterId, isNull);
      expect(none.hasCompanion, isFalse);

      final one = MentorInsightChoice(
        stageId: 'stage_01_03',
        menteeCharacterId: 42,
      );
      expect(one.menteeCharacterId, 42);
      expect(one.hasCompanion, isTrue);
    });

    test('stageId 必填非空且 trim 规范化', () {
      expect(() => MentorInsightChoice(stageId: '   '), throwsArgumentError);
      final choice = MentorInsightChoice(stageId: '  stage_01_03  ');
      expect(choice.stageId, 'stage_01_03');
    });

    test('非空门人 id 与已成立随行门人 id 均要求 > 0', () {
      expect(
        () => MentorInsightChoice(stageId: 'stage_01_03', menteeCharacterId: 0),
        throwsArgumentError,
      );
      expect(
        () =>
            MentorInsightChoice(stageId: 'stage_01_03', menteeCharacterId: -1),
        throwsArgumentError,
      );
      expect(
        () => MentorInsightCompanion(stageId: 'stage_01_03', characterId: 0),
        throwsArgumentError,
      );
      expect(
        () => MentorInsightCompanion(stageId: 'stage_01_03', characterId: -1),
        throwsArgumentError,
      );
    });

    test('固定保证：0-1 名、不入战、不受伤、不分掉落、不重复发放', () {
      expect(MentorInsightPolicy.maxCompanions, 1);
      expect(MentorInsightPolicy.noCombatParticipation, isTrue);
      expect(MentorInsightPolicy.noInjury, isTrue);
      expect(MentorInsightPolicy.noDropShare, isTrue);
      expect(MentorInsightPolicy.firstClearOnly, isTrue);
    });

    test('已成立随行门人绑定单关 stageId 与一名门人 id', () {
      final companion = MentorInsightCompanion(
        stageId: 'stage_01_03',
        characterId: 42,
      );
      expect(companion.stageId, 'stage_01_03');
      expect(companion.characterId, 42);
      expect(
        () => MentorInsightCompanion(stageId: '  ', characterId: 42),
        throwsArgumentError,
      );
    });
  });

  group('MENTOR-INSIGHT-RATE-01 成长对象仅主修招式熟练度', () {
    test('成长对象枚举只有主修招式熟练度一个取值', () {
      expect(MentorInsightGrowthTarget.values, [
        MentorInsightGrowthTarget.mainTechniqueProficiency,
      ]);
    });

    test('政策声明成长对象即主修招式熟练度', () {
      expect(
        MentorInsightPolicy.growthTarget,
        MentorInsightGrowthTarget.mainTechniqueProficiency,
      );
    });

    test('合同面无比例 / 每关 cap / 其它成长目标成员', () async {
      final contract = DartSourceContract.parse(
        await File(
          'lib/features/mainline/domain/mentor_insight_policy.dart',
        ).readAsString(),
        path: 'lib/features/mainline/domain/mentor_insight_policy.dart',
      );
      expect(contract.memberAccessCount('rate'), 0);
      expect(contract.memberAccessCount('cap'), 0);
      expect(contract.memberAccessCount('amount'), 0);
      expect(contract.memberAccessCount('pct'), 0);
      expect(contract.memberAccessCount('percent'), 0);
    });
  });

  group('MENTOR-INSIGHT-OCCUPANCY-01 单关占用与四类活动互斥', () {
    test('占用粒度固定单关，不存在整段 Run 占用路径', () {
      expect(MentorInsightOccupancyScope.values, [
        MentorInsightOccupancyScope.singleStage,
      ]);
      expect(
        MentorInsightPolicy.occupancyScope,
        MentorInsightOccupancyScope.singleStage,
      );
    });

    test('四种结算全部释放单关占用，无遗漏无扩展', () {
      expect(MentorInsightPolicy.releaseReasons, {
        MentorInsightReleaseReason.successSettlement,
        MentorInsightReleaseReason.failureSettlement,
        MentorInsightReleaseReason.explicitExit,
        MentorInsightReleaseReason.idempotentRecoverySettlement,
      });
      expect(MentorInsightReleaseReason.values, hasLength(4));
    });

    test('与闭关 / 远征 / 断魂庄 / 疗伤四类既有活动互斥，无扩展', () {
      expect(MentorInsightPolicy.mutuallyExclusiveActivities, {
        MentorInsightBlockingActivity.retreat,
        MentorInsightBlockingActivity.expedition,
        MentorInsightBlockingActivity.bossGauntlet,
        MentorInsightBlockingActivity.healing,
      });
      expect(MentorInsightBlockingActivity.values, hasLength(4));
    });

    test('任一互斥活动占用即不可随行', () {
      expect(
        MentorInsightPolicy.canAccompany(
          const MentorInsightBlockingStatus(inRetreat: true),
        ),
        isFalse,
      );
      expect(
        MentorInsightPolicy.canAccompany(
          const MentorInsightBlockingStatus(inExpedition: true),
        ),
        isFalse,
      );
      expect(
        MentorInsightPolicy.canAccompany(
          const MentorInsightBlockingStatus(inBossGauntlet: true),
        ),
        isFalse,
      );
      expect(
        MentorInsightPolicy.canAccompany(
          const MentorInsightBlockingStatus(inHealingRecovery: true),
        ),
        isFalse,
      );
    });

    test('四类均空闲才可随行（默认快照全部 false）', () {
      expect(
        MentorInsightPolicy.canAccompany(const MentorInsightBlockingStatus()),
        isTrue,
      );
    });
  });

  group('纯合同边界：无存储、无生产接线', () {
    test('domain 合同文件不依赖 Isar / 存储 / schema', () async {
      final source = await File(
        'lib/features/mainline/domain/mentor_insight_policy.dart',
      ).readAsString();
      expect(source, isNot(contains('package:isar')));
      expect(source, isNot(contains('@collection')));
      expect(source, isNot(contains('SaveData')));
      expect(source, isNot(contains('saveDataId')));
      expect(source, isNot(contains('Isar')));
    });
  });
}
