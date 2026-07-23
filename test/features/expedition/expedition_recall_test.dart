import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/reward_entry.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// B2.3 召回/战败返程单事务（§4.6/§9.1）。
void main() {
  late Directory tempDir;
  final departedAt = DateTime(2026, 7, 16, 10);

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_expedition_recall_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<int> dispatchSeeded() async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await IsarSetup.instance.writeTxn(() async {
      final c = (await IsarSetup.instance.characters.get(1))!
        ..isFounder = false
        ..lineageRole = LineageRole.disciple
        ..currentRetreatSessionId = null;
      await IsarSetup.instance.characters.put(c);
    });
    return ExpeditionService(IsarSetup.instance).dispatch(
      characterIds: [1],
      policy: ExpeditionPolicy.yiZhanLiXing,
      now: departedAt,
    );
  }

  /// 手动写入已完成节点态：暂存奖励 + currentNode + 成员倒下状态。
  Future<void> stageRun(
    int runId, {
    required int currentNode,
    required List<RewardEntry> rewards,
    bool downed = false,
    bool defeated = false,
  }) async {
    await IsarSetup.instance.writeTxn(() async {
      final r = (await IsarSetup.instance.expeditionRuns.get(runId))!
        ..currentNode = currentNode
        ..stagedRewards = rewards
        ..defeated = defeated;
      for (final m in r.members) {
        m
          ..currentHp = downed ? 0 : 500
          ..isDowned = downed;
      }
      await IsarSetup.instance.expeditionRuns.put(r);
    });
  }

  RewardEntry rw(String key, int qty) => RewardEntry()
    ..rewardKey = key
    ..quantity = qty;

  test('主动召回：发完成节点奖励(经验+物品)、删 run、无伤势、占用释放', () async {
    final runId = await dispatchSeeded();
    await stageRun(
      runId,
      currentNode: 4,
      rewards: [rw('exp', 120), rw('item_yaocao', 3)],
    );
    final before = (await IsarSetup.instance.characters.get(1))!.experience;

    final svc = ExpeditionService(IsarSetup.instance);
    final result = await svc.recall(defeated: false);

    expect(result.returned, isTrue);
    expect(result.deepestNode, 4);
    expect(result.defeated, isFalse);

    // 会话关闭：run 删除。
    expect(await IsarSetup.instance.expeditionRuns.get(runId), isNull);

    // 经验发放（全员含倒下者）。
    final ch = (await IsarSetup.instance.characters.get(1))!;
    expect(ch.experience, greaterThan(before));
    // 召回不附伤势。
    expect(ch.injuryHoursRemaining, 0);
    expect(ch.lightInjuryStacks, 0);

    // 物品入库。
    final item = await IsarSetup.instance.inventoryItems.getByDefId(
      'item_yaocao',
    );
    expect(item, isNotNull);
    expect(item!.quantity, 3);

    // 占用释放：可再次派遣。
    final runId2 = await svc.dispatch(
      characterIds: [1],
      policy: ExpeditionPolicy.yanJingCaiYao,
      now: departedAt,
    );
    expect(runId2, isNot(runId));
  });

  test('战败返程：倒下者重伤、仍发已完成奖励、删 run', () async {
    final runId = await dispatchSeeded();
    await stageRun(
      runId,
      currentNode: 6,
      rewards: [rw('exp', 60), rw('item_silver', 50)],
      downed: true,
    );

    final svc = ExpeditionService(IsarSetup.instance);
    final result = await svc.recall(defeated: true);

    expect(result.returned, isTrue);
    expect(result.defeated, isTrue);
    expect(result.downedCount, 1);

    final ch = (await IsarSetup.instance.characters.get(1))!;
    expect(ch.injuryHoursRemaining, greaterThan(0)); // 倒下 → 重伤

    // 奖励仍发（保留此前完成节点）。
    final item = await IsarSetup.instance.inventoryItems.getByDefId(
      'item_silver',
    );
    expect(item!.quantity, 50);
    expect(await IsarSetup.instance.expeditionRuns.get(runId), isNull);
  });

  test('战败返程：未倒下成员结轻伤（§4.6 倒下者重伤·其余轻伤）', () async {
    final runId = await dispatchSeeded();
    await stageRun(
      runId,
      currentNode: 6,
      rewards: [rw('exp', 60)],
      downed: false, // 战末仍存活
    );

    final svc = ExpeditionService(IsarSetup.instance);
    final result = await svc.recall(defeated: true);

    expect(result.downedCount, 0);
    final ch = (await IsarSetup.instance.characters.get(1))!;
    expect(ch.lightInjuryStacks, greaterThan(0), reason: '存活者轻伤');
    expect(ch.injuryHoursRemaining, 0, reason: '非倒下者不进重伤');
  });

  test('战败持久化：recall 不传参仍按落库 defeated 兑现伤势（P1-5.2）', () async {
    final runId = await dispatchSeeded();
    // 模拟跨启动：settle 已把 defeated 落库，但本次调用方无战败上下文。
    await stageRun(
      runId,
      currentNode: 6,
      rewards: [rw('exp', 60)],
      downed: true,
      defeated: true,
    );

    final svc = ExpeditionService(IsarSetup.instance);
    final result = await svc.recall(); // 故意不传 defeated

    expect(result.returned, isTrue);
    expect(result.defeated, isTrue, reason: '落库战败态须生效');
    final ch = (await IsarSetup.instance.characters.get(1))!;
    expect(ch.injuryHoursRemaining, greaterThan(0), reason: '倒下者重伤须兑现');
  });

  test('召回发奖：物品已有库存行 → 数量累加并刷新获得时间（不新建行）', () async {
    final runId = await dispatchSeeded();
    await stageRun(runId, currentNode: 4, rewards: [rw('item_yaocao', 3)]);
    final at = DateTime(2026, 7, 17, 9);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = 'item_yaocao'
          ..itemType = ItemType.miscMaterial
          ..quantity = 5
          ..firstObtainedAt = DateTime(2026, 7, 16)
          ..lastObtainedAt = DateTime(2026, 7, 16),
      );
    });

    final svc = ExpeditionService(IsarSetup.instance);
    await svc.recall(now: at);

    final item = await IsarSetup.instance.inventoryItems.getByDefId(
      'item_yaocao',
    );
    expect(item, isNotNull);
    expect(item!.quantity, 8, reason: '既有行 5 + 暂存 3 累加');
    expect(item.lastObtainedAt, at, reason: '刷新 lastObtainedAt');
  });

  test('召回经验跨层：经层锁门禁判定后升层（有主线进度行·发布上限内）', () async {
    final runId = await dispatchSeeded();
    // 经验调到当前层阈值-1：暂存 100 经验 → 结算时跨层触发 isLayerLocked 判定。
    final repo = GameRepository.instance;
    final before = (await IsarSetup.instance.characters.get(1))!;
    final threshold = repo
        .getRealm(before.realmTier, before.realmLayer)
        .experienceToNext;
    await IsarSetup.instance.writeTxn(() async {
      final ch = (await IsarSetup.instance.characters.get(1))!
        ..experience = threshold - 1;
      await IsarSetup.instance.characters.put(ch);
      await IsarSetup.instance.mainlineProgress.put(
        MainlineProgress()
          ..saveDataId = IsarSetup.currentSlotId
          ..clearedStageIds = ['stage_01_01'],
      );
    });
    await stageRun(runId, currentNode: 4, rewards: [rw('exp', 100)]);

    final svc = ExpeditionService(IsarSetup.instance);
    await svc.recall();

    final after = (await IsarSetup.instance.characters.get(1))!;
    final next = CharacterAdvancementService.nextLayer(
      before.realmTier,
      before.realmLayer,
    )!;
    expect(after.realmTier, next.tier);
    expect(after.realmLayer, next.layer, reason: '发布上限内不被拦·升一层');
    expect(after.experience, 99, reason: 'threshold-1 + 100 - threshold');
  });

  test('并发守卫：事务前 run 被并发召回删除 → 放弃发奖不重复发放（P1-5.4）', () async {
    final runId = await dispatchSeeded();
    await stageRun(runId, currentNode: 4, rewards: [rw('exp', 100)]);
    final expBefore = (await IsarSetup.instance.characters.get(1))!.experience;

    final svc = ExpeditionService(IsarSetup.instance);
    final result = await svc.recall(
      beforeCommitForTest: () async {
        // 模拟并发召回抢先删除 run。
        await IsarSetup.instance.writeTxn(
          () => IsarSetup.instance.expeditionRuns.delete(runId),
        );
      },
    );

    expect(result.returned, isFalse, reason: '并发冲突 → 放弃，调用方可重试');
    final ch = (await IsarSetup.instance.characters.get(1))!;
    expect(ch.experience, expBefore, reason: '零副作用：不重复发经验');
  });

  test('并发守卫：事务前 run 被并发 settle 推进 → 放弃发奖保留新暂存（P1-5.4）', () async {
    final runId = await dispatchSeeded();
    await stageRun(runId, currentNode: 4, rewards: [rw('exp', 100)]);
    final expBefore = (await IsarSetup.instance.characters.get(1))!.experience;

    final svc = ExpeditionService(IsarSetup.instance);
    final result = await svc.recall(
      beforeCommitForTest: () async {
        // 模拟并发 settle 推进 cursor 并暂存新奖励。
        await IsarSetup.instance.writeTxn(() async {
          final r = (await IsarSetup.instance.expeditionRuns.get(runId))!
            ..currentNode = 5
            ..stagedRewards = [rw('exp', 100), rw('item_yaocao', 2)];
          await IsarSetup.instance.expeditionRuns.put(r);
        });
      },
    );

    expect(result.returned, isFalse);
    final ch = (await IsarSetup.instance.characters.get(1))!;
    expect(ch.experience, expBefore, reason: '按过期快照发奖被拦');
    final run = (await IsarSetup.instance.expeditionRuns.get(runId))!;
    expect(run.currentNode, 5, reason: '并发推进结果不被覆盖');
    expect(run.stagedRewards.quantityOf('item_yaocao'), 2, reason: '新暂存不丢');
  });

  test('召回写百草岭历史最深节点：max 单调不回退（P1-5.7）', () async {
    final runId = await dispatchSeeded();
    await stageRun(runId, currentNode: 4, rewards: [rw('exp', 10)]);

    final svc = ExpeditionService(IsarSetup.instance);
    await svc.recall();

    var save = (await IsarSetup.instance.saveDatas.get(0))!;
    expect(save.baicaoMaxDepth, 4, reason: '返程最深节点落永久进度');

    // 既有更深记录不被更低返程覆盖。
    await IsarSetup.instance.writeTxn(() async {
      final s = (await IsarSetup.instance.saveDatas.get(0))!
        ..baicaoMaxDepth = 12;
      await IsarSetup.instance.saveDatas.put(s);
    });
    final runId2 = await svc.dispatch(
      characterIds: [1],
      policy: ExpeditionPolicy.yanJingCaiYao,
      now: departedAt,
    );
    await stageRun(runId2, currentNode: 2, rewards: [rw('exp', 10)]);
    await svc.recall();

    save = (await IsarSetup.instance.saveDatas.get(0))!;
    expect(save.baicaoMaxDepth, 12, reason: 'max 单调，浅返程不回退');
  });
}
