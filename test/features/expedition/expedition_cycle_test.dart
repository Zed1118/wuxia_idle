import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/reward_entry.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// 批 B 远征周目（spec 2026-08-01 拍板 #5 + 2026-08-04 深度里程碑拍板）：
/// dispatch 周目门槛硬守卫（深度里程碑折算「已通」+ 境界门槛）+
/// run.cycleIndex 落库。setup 沿 expedition_dispatch_test 体例 +
/// 真 GameRepository（门槛读 expeditionConfig 敌境界锚）。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_expedition_cycle_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.38.0'
          ..createdAt = DateTime(2026, 8, 4)
          ..lastSavedAt = DateTime(2026, 8, 4)
          ..lastOnlineAt = DateTime(2026, 8, 4),
      );
    });
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<int> putDisciple({required RealmTier tier}) async {
    late int id;
    await IsarSetup.instance.writeTxn(() async {
      final c = Character()
        ..name = '弟子'
        ..realmTier = tier
        ..realmLayer = RealmLayer.qiMeng
        ..attributes = Attributes()
        ..rarity = RarityTier.biaoZhun
        ..lineageRole = LineageRole.disciple
        ..createdAt = DateTime(2026, 8, 4)
        ..isFounder = false
        ..mainTechniqueId = 5;
      id = await IsarSetup.instance.characters.put(c);
    });
    return id;
  }

  Future<void> setMaxDepth(int depth) async {
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.baicaoMaxDepth = depth;
      await IsarSetup.instance.saveDatas.put(save);
    });
  }

  ExpeditionService svc() => ExpeditionService(IsarSetup.instance);

  test('cycle=2 深度未达首里程碑 → 抛（折算已通 0，顺序解锁拦截）', () async {
    final ra = GameRepository.instance.numbers.cycleEvolution.realmAdvance;
    final cid = await putDisciple(tier: RealmTier.wuSheng);
    await setMaxDepth(ra.expeditionDepthMilestones.first - 1);
    await expectLater(
      svc().dispatch(
        characterIds: [cid],
        policy: ExpeditionPolicy.yanJingCaiYao,
        cycleIndex: 2,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('cycle=2 深度达标但境界不够 → 抛（境界门槛）', () async {
    // 远征敌最高 sanLiu（expeditions.yaml），cycle2 推进 +3 → jueDing，
    // margin 1 → 须 ≥ yiLiu；sanLiu 不够。
    final ra = GameRepository.instance.numbers.cycleEvolution.realmAdvance;
    final cid = await putDisciple(tier: RealmTier.sanLiu);
    await setMaxDepth(ra.expeditionDepthMilestones.first);
    await expectLater(
      svc().dispatch(
        characterIds: [cid],
        policy: ExpeditionPolicy.yanJingCaiYao,
        cycleIndex: 2,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('cycle=2 深度达标且境界够 → 建 run 且 cycleIndex=2', () async {
    final ra = GameRepository.instance.numbers.cycleEvolution.realmAdvance;
    final cid = await putDisciple(tier: RealmTier.wuSheng);
    await setMaxDepth(ra.expeditionDepthMilestones.first);
    final runId = await svc().dispatch(
      characterIds: [cid],
      policy: ExpeditionPolicy.yanJingCaiYao,
      cycleIndex: 2,
    );
    final run = await IsarSetup.instance.expeditionRuns.get(runId);
    expect(run!.cycleIndex, 2);
  });

  test('cycle=1 默认路径不触任何门槛（低境界 0 深度照常可派）', () async {
    final cid = await putDisciple(tier: RealmTier.xueTu);
    final runId = await svc().dispatch(
      characterIds: [cid],
      policy: ExpeditionPolicy.yanJingCaiYao,
    );
    final run = await IsarSetup.instance.expeditionRuns.get(runId);
    expect(run!.cycleIndex, 1);
  });

  test('cycle=0 → 抛（参数非法）', () async {
    final cid = await putDisciple(tier: RealmTier.wuSheng);
    await expectLater(
      svc().dispatch(
        characterIds: [cid],
        policy: ExpeditionPolicy.yanJingCaiYao,
        cycleIndex: 0,
      ),
      throwsA(isA<StateError>()),
    );
  });

  group('周目奖励缩放（2026-08-05 拍板候选 a：整数件 ceil 反吞没、连续量 round）', () {
    RewardEntry entry(String key, int qty) => RewardEntry()
      ..rewardKey = key
      ..quantity = qty;

    test('cycle=1 恒等短路：原列表原样返回（不读全局配置的契约不破）', () {
      final rewards = [entry('item_duanhuntie', 1)];
      expect(ExpeditionService.scaleRewardsForCycle(rewards, 1), same(rewards));
    });

    test('cycle=2 整数件奖励不被 round 吞没（帖/药草 1 件必得增益）', () {
      final ra = GameRepository.instance.numbers.cycleEvolution.realmAdvance;
      expect(
        ra.rewardMultFor(2),
        greaterThan(1.0),
        reason: '前提自证：配置的周目奖励加成 >0，否则本组测试无判别力',
      );
      final scaled = ExpeditionService.scaleRewardsForCycle([
        entry('item_duanhuntie', 1),
        entry('item_yaocao', 1),
      ], 2);
      for (final r in scaled) {
        expect(
          r.quantity,
          greaterThan(1),
          reason: '${r.rewardKey} 在 cycle2 必须拿到整件增益（反吞没不变式）',
        );
      }
    });

    test('cycle=2 exp 维持按比例 round（批 B 口径、EXP 预算探针锚）', () {
      final ra = GameRepository.instance.numbers.cycleEvolution.realmAdvance;
      final mult = ra.rewardMultFor(2);
      // 17×1.25=21.25：round=21 / ceil=22，可判别两种口径。
      final scaled = ExpeditionService.scaleRewardsForCycle([
        entry('exp', 17),
      ], 2);
      expect(scaled.single.quantity, (17 * mult).round());
    });

    test('internal_force 归连续量口径（round 不 ceil）', () {
      final ra = GameRepository.instance.numbers.cycleEvolution.realmAdvance;
      final mult = ra.rewardMultFor(2);
      final scaled = ExpeditionService.scaleRewardsForCycle([
        entry('internal_force', 17),
      ], 2);
      expect(scaled.single.quantity, (17 * mult).round());
    });
  });
}
