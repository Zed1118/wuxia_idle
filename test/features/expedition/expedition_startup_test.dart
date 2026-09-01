import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/reward_entry.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_startup.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/data/defs/expedition_config.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// 确定性 fake combat（同结算测体例）：全胜、成员满值上限固定。
class _FakeCombat implements ExpeditionCombat {
  final int maxHp = 1000;
  final int maxQi = 100;

  @override
  Future<Map<int, ExpeditionMemberCaps>> memberCaps(List<int> ids) async => {
    for (final id in ids) id: ExpeditionMemberCaps(maxHp: maxHp, maxQi: maxQi),
  };

  @override
  Future<ExpeditionNodeOutcome> fight({
    required ExpeditionNode node,
    required Map<int, ExpeditionMemberVital> memberStates,
    required int nodeSeed,
    required int cycleIndex,
  }) async {
    final hp = <int, int>{};
    final qi = <int, int>{};
    memberStates.forEach((id, v) {
      hp[id] = (v.hp - 100).clamp(0, maxHp);
      qi[id] = (v.qi - 10).clamp(0, maxQi);
    });
    return ExpeditionNodeOutcome(leftWin: true, survivorHp: hp, survivorQi: qi);
  }
}

ExpeditionConfig _config() => const ExpeditionConfig(
  normalNodeMinutes: 90,
  eliteNodeMinutes: 180,
  hpRecoverPctPerNode: 0.10,
  qiRecoverPctPerNode: 0.25,
  zhangshiPctPerLayer: 0.05,
);

Character _disciple() => Character()
  ..name = '弟子'
  ..realmTier = RealmTier.sanLiu
  ..realmLayer = RealmLayer.qiMeng
  ..attributes = Attributes()
  ..rarity = RarityTier.biaoZhun
  ..lineageRole = LineageRole.disciple
  ..createdAt = DateTime(2026, 7, 16)
  ..isFounder = false
  ..mainTechniqueId = 5;

void main() {
  late Directory tempDir;
  final departedAt = DateTime(2026, 7, 16, 10);

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_expedition_startup_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.38.0'
          ..createdAt = departedAt
          ..lastSavedAt = departedAt
          ..lastOnlineAt = departedAt,
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('有 active 远征：settle-on-open 按经过时长追平推进 currentNode', () async {
    final service = ExpeditionService(IsarSetup.instance);
    late int cid;
    await IsarSetup.instance.writeTxn(() async {
      cid = await IsarSetup.instance.characters.put(_disciple());
    });
    await service.dispatch(
      characterIds: [cid],
      policy: ExpeditionPolicy.yanJingCaiYao,
      now: departedAt,
    );

    // 出发 5h（300min）后：节点 1-3 各 90min（cum 270 ≤ 300），节点 4 需 360 > 300。
    final result = await settleActiveExpeditionOnOpen(
      service: service,
      combat: _FakeCombat(),
      config: _config(),
      now: departedAt.add(const Duration(hours: 5)),
    );

    expect(result.currentNode, 3);
    expect(result.caughtUp, isTrue);
    expect(result.defeated, isFalse);
    // 已持久化。
    final run = await service.activeRun();
    expect(run!.currentNode, 3);
  });

  test('离线撞到未解锁险关会自动返程并留下可恢复亲战待办', () async {
    final service = ExpeditionService(IsarSetup.instance);
    late int cid;
    await IsarSetup.instance.writeTxn(() async {
      cid = await IsarSetup.instance.characters.put(_disciple());
    });
    await service.dispatch(
      characterIds: [cid],
      policy: ExpeditionPolicy.yanJingCaiYao,
      now: departedAt,
    );
    final config = GameRepository.instance.expeditionConfig!;
    final elapsed = ExpeditionRules.cumulativeMinutesToCompleteNode(
      5,
      normalMinutes: config.normalNodeMinutes,
      eliteMinutes: config.eliteNodeMinutes,
    );

    final result = await settleActiveExpeditionOnOpen(
      service: service,
      combat: _FakeCombat(),
      config: config,
      now: departedAt.add(Duration(minutes: elapsed)),
    );

    expect(result.currentNode, 4);
    expect(result.automaticReturn?.returned, isTrue);
    expect(result.automaticReturn?.manualMilestoneGate, isNotNull);
    expect(await service.activeRun(), isNull, reason: '撞门后必须释放远征占用');
    final records = await IsarSetup.instance.expeditionMilestoneRecords
        .where()
        .findAll();
    expect(records, hasLength(1));
    expect(records.single.manualClearedAt, isNull);
    expect(records.single.sourceParticipantId, cid);
  });

  test('无 active 远征：settle-on-open no-op', () async {
    final service = ExpeditionService(IsarSetup.instance);
    final result = await settleActiveExpeditionOnOpen(
      service: service,
      combat: _FakeCombat(),
      config: _config(),
      now: departedAt.add(const Duration(hours: 5)),
    );
    expect(result.nodesSettled, 0);
    expect(result.currentNode, 0);
    expect(result.caughtUp, isTrue);
  });

  test('路线 C 历史多人远征：兑现已落库状态并一次性释放会话', () async {
    final service = ExpeditionService(IsarSetup.instance);
    late int firstId;
    late int secondId;
    await IsarSetup.instance.writeTxn(() async {
      firstId = await IsarSetup.instance.characters.put(_disciple());
      secondId = await IsarSetup.instance.characters.put(_disciple());
    });
    await service.dispatch(
      characterIds: [firstId],
      policy: ExpeditionPolicy.yanJingCaiYao,
      now: departedAt,
    );
    final active = (await service.activeRun())!;
    await IsarSetup.instance.writeTxn(() async {
      final row = (await IsarSetup.instance.expeditionRuns.get(active.id))!
        ..currentNode = 4
        ..members = [
          ...active.members,
          ActivityMemberSnapshot()
            ..characterId = secondId
            ..reservedTechniqueIds = [5]
            ..currentHp = 0
            ..currentQi = 0
            ..isDowned = true,
        ]
        ..stagedRewards = [
          RewardEntry()
            ..rewardKey = 'exp'
            ..quantity = 120,
          RewardEntry()
            ..rewardKey = 'item_yaocao'
            ..quantity = 3,
        ];
      for (final member in row.members) {
        member
          ..currentHp = 0
          ..isDowned = true;
      }
      await IsarSetup.instance.expeditionRuns.put(row);
    });
    final firstExpBefore = (await IsarSetup.instance.characters.get(
      firstId,
    ))!.experience;
    final secondExpBefore = (await IsarSetup.instance.characters.get(
      secondId,
    ))!.experience;

    expect(
      await retireLegacyMultiplayerExpeditionOnOpen(service: service),
      isTrue,
    );
    expect(await service.activeRun(), isNull);

    final first = (await IsarSetup.instance.characters.get(firstId))!;
    final second = (await IsarSetup.instance.characters.get(secondId))!;
    expect(first.experience, greaterThan(firstExpBefore));
    expect(second.experience, greaterThan(secondExpBefore));
    expect(first.injuryHoursRemaining, 0, reason: '历史清场不是战败，不应误加重伤');
    expect(second.injuryHoursRemaining, 0, reason: '历史清场不是战败，不应误加重伤');
    expect(first.lightInjuryStacks, 0, reason: '历史清场不是战败，不应误加轻伤');
    expect(second.lightInjuryStacks, 0, reason: '历史清场不是战败，不应误加轻伤');
    expect(
      (await IsarSetup.instance.inventoryItems.getByDefId(
        'item_yaocao',
      ))?.quantity,
      3,
    );

    final nextRunId = await service.dispatch(
      characterIds: [firstId],
      policy: ExpeditionPolicy.yanJingCaiYao,
      now: departedAt.add(const Duration(minutes: 1)),
    );
    expect(nextRunId, isNot(active.id), reason: '删除历史 run 后，成员占用必须释放');
    await service.recall();
    expect(
      await retireLegacyMultiplayerExpeditionOnOpen(service: service),
      isFalse,
      reason: '清场幂等',
    );
  });
}
