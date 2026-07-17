import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// #1 wiring Task 7：断魂庄奖励 / 战败 2 visual_route + seedGauntletReward。
/// route 解析（VisualRoute.values round-trip 另在 visual_route_test·此处显式钉两新 id）+
/// seedGauntletReward 造 awaitingRewardChoice 会话正确性 + 多分辨率复跑幂等（seedTeamLineup
/// 清 bossGauntletRuns·feedback_visual_capture_seed_idempotency）。
void main() {
  test('parseVisualRoute 识别 gauntlet_reward / gauntlet_defeat', () {
    expect(parseVisualRoute('gauntlet_reward'), VisualRoute.gauntletReward);
    expect(parseVisualRoute('gauntlet_defeat'), VisualRoute.gauntletDefeat);
  });

  group('seedGauntletReward', () {
    late Directory tempDir;

    setUpAll(() async {
      await initializeTestIsarCore();
      if (!GameRepository.isLoaded) {
        await loadTestGameRepository();
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'wuxia_gauntlet_rwdseed_',
      );
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      if (IsarSetup.instanceOrNull != null) {
        await IsarSetup.close();
      }
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<List<BossGauntletRun>> runs() =>
        IsarSetup.instance.bossGauntletRuns.where().findAll();

    test('造 awaitingRewardChoice 会话 + 三候选 + 首通标 + 终关', () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedGauntletReward();
      final all = await runs();
      expect(all, hasLength(1));
      final run = all.first;
      expect(run.sessionPhase, GauntletPhase.awaitingRewardChoice);
      expect(run.rewardCandidateDefIds, hasLength(3));
      expect(run.isFirstClearPending, isTrue);
      expect(run.currentStage, 3);
      expect(run.members, isNotEmpty);
      // 候选装备 def 真实存在（奖励屏解析卡 + chooseReward 不悬空）。
      for (final defId in run.rewardCandidateDefIds) {
        expect(
          GameRepository.instance.equipmentDefs.containsKey(defId),
          isTrue,
          reason: '候选 $defId 应在 GameRepository',
        );
      }
    });

    test('幂等：多分辨率复跑仍单会话', () async {
      final svc = Phase2SeedService(isar: IsarSetup.instance);
      await svc.seedGauntletReward();
      await svc.seedGauntletReward();
      expect(await runs(), hasLength(1));
    });
  });
}
