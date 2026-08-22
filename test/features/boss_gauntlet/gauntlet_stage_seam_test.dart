import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_controller.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/phase0a_gauntlet_stage_runner.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// Phase 0A 断魂庄 seam：事务外准备单角色战斗计划，战末只把引擎中立检查点
/// 交给事务层，live 与 headless 路径共用同一结算入口。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_seam_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> seedSave() async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.38.0'
          ..createdAt = DateTime(2026, 7, 17)
          ..lastSavedAt = DateTime(2026, 7, 17)
          ..lastOnlineAt = DateTime(2026, 7, 17),
      );
    });
  }

  ActivityMemberSnapshot snap(int id, {int maxHp = 0, int currentHp = 0}) =>
      ActivityMemberSnapshot()
        ..characterId = id
        ..maxHp = maxHp
        ..currentHp = currentHp
        ..isDowned = false;

  Future<int> putRun({
    required GauntletPhase phase,
    required int currentStage,
    required List<ActivityMemberSnapshot> members,
  }) async {
    late int id;
    await IsarSetup.instance.writeTxn(() async {
      id = await IsarSetup.instance.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 0
          ..currentStage = currentStage
          ..sessionPhase = phase
          ..members = members,
      );
    });
    return id;
  }

  test('preparePhase0aStage：事务外建当前关出战计划（角色+敌+seed+isBoss）', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)], // maxHp=0 = 首关满血基准
    );
    final config = GameRepository.instance.bossGauntletConfig!;

    final plan = await GauntletService(
      IsarSetup.instance,
    ).preparePhase0aStage(config: config);

    expect(plan.playerSnapshot.characterId, 1, reason: '真单角色快照');
    expect(plan.enemyDefs, isNotEmpty, reason: '关次敌队非空');
    expect(
      plan.seed,
      0 * 31 + 1,
      reason: 'seed 混 currentStage（run.seed*31+stage）',
    );
    expect(plan.isBoss, config.stages[0].role == 'boss');
  });

  test('preparePhase0aStage 拒非 inBattle（整备页）→ 抛错', () async {
    await seedSave();
    await putRun(
      phase: GauntletPhase.interlude,
      currentStage: 2,
      members: [snap(1, maxHp: 1000, currentHp: 500)],
    );
    final config = GameRepository.instance.bossGauntletConfig!;
    await expectLater(
      GauntletService(IsarSetup.instance).preparePhase0aStage(config: config),
      throwsStateError,
    );
  });

  test('prepare + Phase0a run + settle == 原子推进战末快照', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final runId = await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)],
    );
    final config = GameRepository.instance.bossGauntletConfig!;
    final numbers = GameRepository.instance.numbers;
    final service = GauntletService(IsarSetup.instance);

    final plan = await service.preparePhase0aStage(config: config);
    final result = await Phase0aGauntletStageRunner.run(
      contentId: 'gauntlet_${plan.stage}',
      playerSnapshot: plan.playerSnapshot,
      enemyTeam: plan.enemyDefs,
      numbers: numbers,
      seed: plan.seed,
      cycleIndex: plan.cycleIndex,
    );
    await service.settlePhase0aStageResult(
      result: result.settlement,
      config: config,
    );

    final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
    expect(run.members.single.maxHp, greaterThan(0), reason: '战末快照真落地');
    if (result.leftWin) {
      expect(run.sessionPhase, GauntletPhase.interlude);
      expect(run.currentStage, 2);
    } else {
      expect(run.sessionPhase, GauntletPhase.inBattle);
      expect(run.currentStage, 1);
    }
  });

  test('settlePhase0aStageResult 会话已关闭 → 防御 no-op（不抛）', () async {
    await seedSave();
    // 无 active run → fresh 为 null → settlement 内防御返回。
    final config = GameRepository.instance.bossGauntletConfig!;
    await GauntletService(IsarSetup.instance).settlePhase0aStageResult(
      result: const GauntletStageSettlement(
        leftWin: false,
        checkpoint: GauntletMemberCheckpoint(
          characterId: 1,
          currentHp: 0,
          currentQi: 0,
          maxHp: 1,
          maxQi: 1,
        ),
      ),
      config: config,
    );
    // 不抛即通过。
    expect(true, isTrue);
  });
}
