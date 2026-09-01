import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/data/defs/expedition_config.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_seed.dart';

import '../../support/isar_test_support.dart';

/// 确定性 fake：可控哪个节点战败、成员满值上限。隔离 Isar/真实战斗/敌队构建，
/// 专测结算状态机 6 不变式。
class _FakeCombat implements ExpeditionCombat {
  _FakeCombat({this.loseAtNode});

  final int? loseAtNode;
  final int maxHp = 1000;
  final int maxQi = 100;
  final List<int> foughtNodes = [];

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
    foughtNodes.add(node.index);
    final win = loseAtNode == null || node.index != loseAtNode;
    final hp = <int, int>{};
    final qi = <int, int>{};
    memberStates.forEach((id, v) {
      hp[id] = win ? (v.hp - 100).clamp(0, maxHp) : 0;
      qi[id] = win ? (v.qi - 10).clamp(0, maxQi) : 0;
    });
    return ExpeditionNodeOutcome(leftWin: win, survivorHp: hp, survivorQi: qi);
  }
}

ExpeditionConfig _config({int baseExp = 170}) => ExpeditionConfig(
  normalNodeMinutes: 90,
  eliteNodeMinutes: 180,
  hpRecoverPctPerNode: 0.10,
  qiRecoverPctPerNode: 0.25,
  zhangshiPctPerLayer: 0.05,
  baseExpPerBattle: baseExp,
);

ExpeditionConfig _configWithManualMilestone() => ExpeditionConfig.fromYaml({
  'normal_node_minutes': 90,
  'elite_node_minutes': 180,
  'hp_recover_pct_per_node': 0.10,
  'qi_recover_pct_per_node': 0.25,
  'zhangshi_pct_per_layer': 0.05,
  'combat': {
    'depth_curve': {
      'first_node': 1,
      'base_multiplier': 1.0,
      'hp_growth_per_node': 0.0,
      'attack_growth_per_node': 0.0,
      'hp_multiplier_cap': 1.0,
      'attack_multiplier_cap': 1.0,
      'hp_value_cap': 60000,
      'attack_value_cap': 2000,
    },
    'normal_enemy_teams': [
      {
        'id': 'normal_a',
        'enemies': [
          {
            'id': 'enemy_normal_a',
            'name': '普通敌',
            'realmTier': 'sanLiu',
            'realmLayer': 'shuLian',
            'school': 'gangMeng',
            'baseHp': 100,
            'baseAttack': 10,
            'baseSpeed': 100,
            'skillIds': ['skill_gangmeng_jichu_basic'],
            'iconPath': '',
          },
        ],
      },
    ],
    'elite_enemy_teams': [
      {
        'id': 'elite_manual_a',
        'enemies': [
          {
            'id': 'enemy_elite_a',
            'name': '险关敌',
            'realmTier': 'sanLiu',
            'realmLayer': 'jingTong',
            'school': 'lingQiao',
            'baseHp': 100,
            'baseAttack': 10,
            'baseSpeed': 100,
            'skillIds': ['skill_lingqiao_jichu_basic'],
            'iconPath': '',
          },
        ],
      },
      {
        'id': 'elite_manual_b',
        'enemies': [
          {
            'id': 'enemy_elite_b',
            'name': '另一险关敌',
            'realmTier': 'sanLiu',
            'realmLayer': 'jingTong',
            'school': 'yinRou',
            'baseHp': 100,
            'baseAttack': 10,
            'baseSpeed': 100,
            'skillIds': ['skill_yinrou_jichu_basic'],
            'iconPath': '',
          },
        ],
      },
    ],
  },
});

void main() {
  late Directory tempDir;
  final departedAt = DateTime(2026, 7, 16, 10);

  setUpAll(() => initializeTestIsarCore());

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_expedition_settle_');
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

  Future<int> putDisciple({int? mainTech = 5}) async {
    late int id;
    await IsarSetup.instance.writeTxn(() async {
      final c = Character()
        ..name = '弟子'
        ..realmTier = RealmTier.sanLiu
        ..realmLayer = RealmLayer.qiMeng
        ..attributes = Attributes()
        ..rarity = RarityTier.biaoZhun
        ..lineageRole = LineageRole.disciple
        ..createdAt = departedAt
        ..isFounder = false
        ..mainTechniqueId = mainTech;
      id = await IsarSetup.instance.characters.put(c);
    });
    return id;
  }

  Future<int> dispatch(ExpeditionPolicy policy) async {
    final cid = await putDisciple();
    return ExpeditionService(
      IsarSetup.instance,
    ).dispatch(characterIds: [cid], policy: policy, now: departedAt);
  }

  Future<ExpeditionRun> readRun(int runId) async =>
      (await IsarSetup.instance.expeditionRuns.get(runId))!;

  String digest(ExpeditionRun r) => [
    'node=${r.currentNode}',
    for (final m in r.members)
      '${m.characterId}:${m.currentHp}/${m.currentQi}/${m.isDowned}',
    for (final e
        in (r.stagedRewards.toList()
          ..sort((a, b) => a.rewardKey.compareTo(b.rewardKey))))
      '${e.rewardKey}=${e.quantity}',
  ].join('|');

  Future<void> resetRun(int runId) async {
    await IsarSetup.instance.writeTxn(() async {
      final r = (await IsarSetup.instance.expeditionRuns.get(runId))!
        ..currentNode = 0
        ..lastSettledAt = null
        ..stagedRewards = [];
      for (final m in r.members) {
        m
          ..currentHp = 0
          ..currentQi = 0
          ..isDowned = false;
      }
      await IsarSetup.instance.expeditionRuns.put(r);
    });
  }

  test('按 elapsed 推进已完成节点并暂存奖励（全胜连战）', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final svc = ExpeditionService(IsarSetup.instance);
    // 前 5 节点累计 = 90×4 + 180 = 540 分（第 5 节点为险关）。
    final result = await svc.settle(
      combat: _FakeCombat(),
      config: _config(),
      now: departedAt.add(const Duration(minutes: 540)),
    );

    final run = await readRun(runId);
    expect(run.currentNode, 5);
    expect(result.nodesSettled, 5);
    expect(result.defeated, isFalse);
    expect(result.caughtUp, isTrue);
    expect(run.stagedRewards, isNotEmpty);
  });

  test('未解锁险关首次必须停在节点前且不得调用 headless 战斗', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final svc = ExpeditionService(IsarSetup.instance);
    final combat = _FakeCombat();

    final result = await svc.settle(
      combat: combat,
      config: _configWithManualMilestone(),
      now: departedAt.add(const Duration(minutes: 540)),
    );

    expect(result.currentNode, 4);
    expect((await readRun(runId)).currentNode, 4);
    expect(combat.foughtNodes, isNot(contains(5)));
  });

  test('同 route+milestone 已亲战通过后才允许后续 headless 越门', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final run = await readRun(runId);
    final config = _configWithManualMilestone();
    final nodeSeed = ExpeditionSeed.forNode(
      saveId: run.saveDataId,
      runSerial: run.seed,
      node: 5,
    );
    final milestoneId = config.teamForNode(nodeSeed: nodeSeed, elite: true).id;
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.expeditionMilestoneRecords.put(
        ExpeditionMilestoneRecord()
          ..recordKey = ExpeditionMilestoneRecord.canonicalKey(
            saveDataId: 1,
            routeId: ExpeditionService.contentId,
            milestoneId: milestoneId,
          )
          ..saveDataId = 1
          ..routeId = ExpeditionService.contentId
          ..milestoneId = milestoneId
          ..nodeIndex = 5
          ..nodeSeed = nodeSeed
          ..cycleIndex = 1
          ..sourceRunId = run.id
          ..sourceParticipantId = run.members.single.characterId
          ..discoveredAt = departedAt
          ..manualClearedAt = departedAt,
      );
    });
    final combat = _FakeCombat();

    final result = await ExpeditionService(IsarSetup.instance).settle(
      combat: combat,
      config: config,
      now: departedAt.add(const Duration(minutes: 540)),
    );

    expect(result.currentNode, 5);
    expect(combat.foughtNodes, contains(5));
  });

  test('已通过一种险关模板不能越过另一种首次模板', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final run = await readRun(runId);
    final config = _configWithManualMilestone();
    final firstSeed = ExpeditionSeed.forNode(
      saveId: run.saveDataId,
      runSerial: run.seed,
      node: 5,
    );
    final firstMilestone = config
        .teamForNode(nodeSeed: firstSeed, elite: true)
        .id;
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.expeditionMilestoneRecords.put(
        ExpeditionMilestoneRecord()
          ..recordKey = ExpeditionMilestoneRecord.canonicalKey(
            saveDataId: 1,
            routeId: ExpeditionService.contentId,
            milestoneId: firstMilestone,
          )
          ..saveDataId = 1
          ..routeId = ExpeditionService.contentId
          ..milestoneId = firstMilestone
          ..nodeIndex = 5
          ..nodeSeed = firstSeed
          ..cycleIndex = 1
          ..sourceRunId = run.id
          ..sourceParticipantId = run.members.single.characterId
          ..discoveredAt = departedAt
          ..manualClearedAt = departedAt,
      );
    });
    final expectedOtherNode = [for (var node = 10; node <= 100; node += 5) node]
        .firstWhere(
          (node) =>
              config
                  .teamForNode(
                    nodeSeed: ExpeditionSeed.forNode(
                      saveId: run.saveDataId,
                      runSerial: run.seed,
                      node: node,
                    ),
                    elite: true,
                  )
                  .id !=
              firstMilestone,
        );
    final combat = _FakeCombat();

    final result = await ExpeditionService(IsarSetup.instance).settle(
      combat: combat,
      config: config,
      now: departedAt.add(
        Duration(
          minutes: ExpeditionRules.cumulativeMinutesToCompleteNode(
            expectedOtherNode,
            normalMinutes: config.normalNodeMinutes,
            eliteMinutes: config.eliteNodeMinutes,
          ),
        ),
      ),
      maxNodesPerBatch: expectedOtherNode,
    );

    expect(result.manualMilestoneGate?.nodeIndex, expectedOtherNode);
    expect(result.manualMilestoneGate?.milestoneId, isNot(firstMilestone));
    expect(result.currentNode, expectedOtherNode - 1);
    expect(combat.foughtNodes, isNot(contains(expectedOtherNode)));
  });

  test('结算 exp 奖励随 config.baseExpPerBattle 缩放（batch3 wire）', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final svc = ExpeditionService(IsarSetup.instance);
    int expOf(ExpeditionRun r) => r.stagedRewards
        .where((e) => e.rewardKey == 'exp')
        .fold(0, (s, e) => s + e.quantity);
    final now = departedAt.add(const Duration(minutes: 540));

    await svc.settle(
      combat: _FakeCombat(),
      config: _config(baseExp: 100),
      now: now,
    );
    final lowExp = expOf(await readRun(runId));

    await resetRun(runId);
    await svc.settle(
      combat: _FakeCombat(),
      config: _config(baseExp: 300),
      now: now,
    );
    final highExp = expOf(await readRun(runId));

    expect(lowExp, greaterThan(0));
    expect(
      highExp,
      greaterThan(lowExp),
      reason: 'settle exp 未随 config.baseExpPerBattle 缩放 → wire 未接',
    );
  });

  test('单批上限：一次 settle 最多 maxNodesPerBatch 个节点，余下留下批', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final svc = ExpeditionService(IsarSetup.instance);
    // 10 节点累计 = 90×8 + 180×2 = 1080 分（第 5、10 为险关）。
    final result = await svc.settle(
      combat: _FakeCombat(),
      config: _config(),
      now: departedAt.add(const Duration(minutes: 1080)),
      maxNodesPerBatch: 3,
    );

    expect(result.nodesSettled, 3);
    expect(result.caughtUp, isFalse);
    final run = await readRun(runId);
    expect(run.currentNode, 3);
  });

  test('战败即停：败于险关5 → 停在节点4、defeated、不续打后续节点', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final svc = ExpeditionService(IsarSetup.instance);
    final combat = _FakeCombat(loseAtNode: 5);
    // 给足 10 节点时间，但应停在节点 4（第 5 险关战败）。
    final result = await svc.settle(
      combat: combat,
      config: _config(),
      now: departedAt.add(const Duration(minutes: 1080)),
    );

    expect(result.defeated, isTrue);
    expect(result.caughtUp, isTrue);
    expect(result.currentNode, 4);
    final run = await readRun(runId);
    expect(run.currentNode, 4);
    // 打过第 5 节点（失败），未继续打 6 及以后。
    expect(combat.foughtNodes.contains(5), isTrue);
    expect(combat.foughtNodes.where((n) => n > 5), isEmpty);
  });

  test('战败持久化：defeated 落库，再 settle 不推进不重战（P1-5.2）', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final svc = ExpeditionService(IsarSetup.instance);
    final combat = _FakeCombat(loseAtNode: 5);
    final r1 = await svc.settle(
      combat: combat,
      config: _config(),
      now: departedAt.add(const Duration(minutes: 1080)),
    );
    expect(r1.defeated, isTrue);
    expect((await readRun(runId)).defeated, isTrue, reason: '战败态须落库（跨启动不丢）');
    final foughtAfterDefeat = combat.foughtNodes.length;

    // 模拟重启后再开（更晚 now）：不再推进、不重打失败节点，直接报战败态。
    final r2 = await svc.settle(
      combat: combat,
      config: _config(),
      now: departedAt.add(const Duration(minutes: 1080 * 3)),
    );
    expect(r2.defeated, isTrue);
    expect(r2.nodesSettled, 0);
    expect(r2.caughtUp, isTrue);
    expect(r2.currentNode, 4);
    expect(
      combat.foughtNodes.length,
      foughtAfterDefeat,
      reason: '已战败 run 不得重战任何节点',
    );
    expect((await readRun(runId)).currentNode, 4);
  });

  test('cursor 守卫：提交前 run 被并发推进 → 本批弃写不覆盖', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final svc = ExpeditionService(IsarSetup.instance);
    final marker = departedAt.add(const Duration(hours: 99));

    final result = await svc.settle(
      combat: _FakeCombat(),
      config: _config(),
      now: departedAt.add(const Duration(minutes: 540)), // 目标 5 节点
      beforeCommitForTest: () async {
        // 模拟并发结算：主 settle 提交前，run 已被推进 + 打标记。
        await IsarSetup.instance.writeTxn(() async {
          final r = await IsarSetup.instance.expeditionRuns.get(runId);
          r!
            ..currentNode = 5
            ..lastSettledAt = marker;
          await IsarSetup.instance.expeditionRuns.put(r);
        });
      },
    );

    expect(result.nodesSettled, 0); // 本批弃写
    expect(result.caughtUp, isFalse); // 未追平，交外层重试
    final run = await readRun(runId);
    expect(run.currentNode, 5); // 并发值保留
    expect(run.lastSettledAt, marker); // 未被主 settle 覆盖
  });

  test('在线分段 == 一次性离线：分批推进与一次结算得同一最终状态', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final svc = ExpeditionService(IsarSetup.instance);
    final combat = _FakeCombat();

    Future<void> settleTo(DateTime now) async {
      for (var guard = 0; guard < 1000; guard++) {
        final r = await svc.settle(
          combat: combat,
          config: _config(),
          now: now,
          maxNodesPerBatch: 2, // 强制多批，跨批边界
        );
        if (r.caughtUp) return;
      }
      fail('settleTo 未追平（疑死循环）');
    }

    // A：在线分段（多个时间点各自追平）；节点累计 n2=180 n4=360 n5=540 n8=810。
    for (final m in [200, 400, 600, 810]) {
      await settleTo(departedAt.add(Duration(minutes: m)));
    }
    final digestA = digest(await readRun(runId));

    await resetRun(runId);

    // B：一次性离线到最终时间点。
    await settleTo(departedAt.add(const Duration(minutes: 810)));
    final digestB = digest(await readRun(runId));

    expect(digestA, digestB);
    expect((await readRun(runId)).currentNode, 8);
  });

  test('幂等 + 时间回拨：重复结算不重复发奖、回拨不产生负进度', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final svc = ExpeditionService(IsarSetup.instance);
    final combat = _FakeCombat();
    final at540 = departedAt.add(const Duration(minutes: 540));

    final r1 = await svc.settle(combat: combat, config: _config(), now: at540);
    expect(r1.nodesSettled, 5);
    final d1 = digest(await readRun(runId));

    // 幂等：同 now 再结算 → 0 节点、状态不变。
    final r2 = await svc.settle(combat: combat, config: _config(), now: at540);
    expect(r2.nodesSettled, 0);
    expect(digest(await readRun(runId)), d1);

    // 时间回拨：now 早于已结算 → 不倒退、不重复发奖。
    final r3 = await svc.settle(
      combat: combat,
      config: _config(),
      now: departedAt.add(const Duration(minutes: 100)),
    );
    expect(r3.nodesSettled, 0);
    expect(digest(await readRun(runId)), d1);
  });

  test('settleToNow：多批循环追平到 now（catch-up 累计）', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final svc = ExpeditionService(IsarSetup.instance);
    // 810 分 → 8 节点；maxNodesPerBatch=2 强制 4 批循环。
    final result = await svc.settleToNow(
      combat: _FakeCombat(),
      config: _config(),
      now: departedAt.add(const Duration(minutes: 810)),
      maxNodesPerBatch: 2,
    );

    expect(result.caughtUp, isTrue);
    expect(result.nodesSettled, 8); // 跨多批累计
    expect((await readRun(runId)).currentNode, 8);
  });

  test('settleToNow：战败即停不空转', () async {
    final runId = await dispatch(ExpeditionPolicy.yiZhanLiXing);
    final svc = ExpeditionService(IsarSetup.instance);
    final result = await svc.settleToNow(
      combat: _FakeCombat(loseAtNode: 5),
      config: _config(),
      now: departedAt.add(const Duration(minutes: 1080)),
      maxNodesPerBatch: 2,
    );

    expect(result.defeated, isTrue);
    expect(result.caughtUp, isTrue);
    expect((await readRun(runId)).currentNode, 4);
  });

  test('settle 省略 now：按系统时钟结算（出发即结算 → 0 节点追平）', () async {
    final cid = await putDisciple();
    final svc = ExpeditionService(IsarSetup.instance);
    await svc.dispatch(
      characterIds: [cid],
      policy: ExpeditionPolicy.yiZhanLiXing,
      now: DateTime.now(), // 出发时刻锚真实时钟
    );
    // 不传 now → 走 `?? DateTime.now()` 分支；elapsed≈0 → 无可结算节点。
    final result = await svc.settle(combat: _FakeCombat(), config: _config());
    expect(result.nodesSettled, 0);
    expect(result.caughtUp, isTrue);
  });
}
