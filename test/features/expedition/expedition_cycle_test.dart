import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
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
}
