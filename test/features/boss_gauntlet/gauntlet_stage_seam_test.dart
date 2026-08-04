import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_battle_runner.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// C2 组末环 wiring · Task 1：把 `fightCurrentStage` 拆出 `prepareStage`（事务外纯
/// 建队）+ `settleStageResult`（单事务落 advance）的 seam，供 live BattleScreen 路复用。
/// 拆分须 behavior-preserving：drive 测（fightCurrentStage）继续绿。
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

  test('prepareStage：事务外建当前关出战计划（队+敌+seed+isBoss）', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)], // maxHp=0 = 首关满血基准
    );
    final config = GameRepository.instance.bossGauntletConfig!;

    final plan = await GauntletService(
      IsarSetup.instance,
    ).prepareStage(config: config);

    expect(plan.playerTeam, isNotEmpty, reason: '真建队（含祖师/相生/伤势）');
    expect(plan.enemyDefs, isNotEmpty, reason: '关次敌队非空');
    expect(
      plan.seed,
      0 * 31 + 1,
      reason: 'seed 混 currentStage（run.seed*31+stage）',
    );
    expect(plan.isBoss, config.stages[0].role == 'boss');
  });

  test('prepareStage 拒非 inBattle（整备页）→ 抛错', () async {
    await seedSave();
    await putRun(
      phase: GauntletPhase.interlude,
      currentStage: 2,
      members: [snap(1, maxHp: 1000, currentHp: 500)],
    );
    final config = GameRepository.instance.bossGauntletConfig!;
    await expectLater(
      GauntletService(IsarSetup.instance).prepareStage(config: config),
      throwsStateError,
    );
  });

  test('prepareStage + runStage + settleStageResult == 原子推进战末快照', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final runId = await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)],
    );
    final config = GameRepository.instance.bossGauntletConfig!;
    final numbers = GameRepository.instance.numbers;
    final service = GauntletService(IsarSetup.instance);

    final plan = await service.prepareStage(config: config);
    final result = GauntletBattleRunner.runStage(
      playerTeam: plan.playerTeam,
      enemyDefs: plan.enemyDefs,
      numbers: numbers,
      seed: plan.seed,
    );
    await service.settleStageResult(
      finalState: result.finalState,
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

  test('settleStageResult 会话已关闭 → 防御 no-op（不抛）', () async {
    await seedSave();
    // 无 active run → fresh 为 null → settleStageResult 内防御返回。
    final config = GameRepository.instance.bossGauntletConfig!;
    final empty = BattleState.initial(leftTeam: const [], rightTeam: const []);
    await GauntletService(
      IsarSetup.instance,
    ).settleStageResult(finalState: empty, config: config);
    // 不抛即通过。
    expect(true, isTrue);
  });
}
