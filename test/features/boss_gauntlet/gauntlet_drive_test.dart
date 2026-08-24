import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_automation_admission.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/data/defs/boss_gauntlet_config.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// C2.3a 单场战斗驱动生产路径 e2e（feedback_layered_bugs 守卫：pure 测过 ≠ 真落地）。
///
/// `GauntletService.fightCurrentStagePhase0a` = load run → 从真角色组装单角色快照
/// → Phase 0A headless 战斗 → **单事务原子持久化**。原子性即崩溃安全：
/// 战斗中崩溃（内存态·未落事务）→ 无持久化 → 重开重打当前关。`continueToNextStage`
/// = 整备页「继续闯关」（interlude→inBattle）。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_drive_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> seedSave({bool cleared = false}) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.38.0'
          ..createdAt = DateTime(2026, 7, 17)
          ..lastSavedAt = DateTime(2026, 7, 17)
          ..lastOnlineAt = DateTime(2026, 7, 17)
          ..clearedGauntletIds = cleared ? [GauntletService.gauntletId] : [],
      );
    });
  }

  Future<void> markCleared() async {
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.clearedGauntletIds = [GauntletService.gauntletId];
      await IsarSetup.instance.saveDatas.put(save);
    });
  }

  ActivityParticipationRequest automationRequest({
    int characterId = 1,
    ActivityContentKind contentKind = ActivityContentKind.gauntlet,
    String contentId = GauntletService.gauntletId,
    ActivityController controller = ActivityController.playerBot,
    ActivityClock clock = ActivityClock.headless,
    ActivityEntryKind entryKind = ActivityEntryKind.replay,
  }) => ActivityParticipationRequest(
    contentId: contentId,
    contentKind: contentKind,
    characterId: characterId,
    loadoutPlanId: 'gauntlet-plan-$characterId',
    participation: ActivityParticipationMode.direct,
    controller: controller,
    clock: clock,
    entryKind: entryKind,
  );

  Future<GauntletAutomationAdmission> admit({
    ActivityParticipationRequest? request,
  }) => GauntletAutomationAdmissionService(
    IsarSetup.instance,
  ).admit(request: request ?? automationRequest());

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

  test('fightCurrentStagePhase0a 驱动真战斗并原子持久化战末快照（生产路径）', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await markCleared();
    final runId = await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)], // maxHp=0 = 首关占位·满血基准出战
    );
    final config = GameRepository.instance.bossGauntletConfig!;
    final numbers = GameRepository.instance.numbers;

    final result = await GauntletService(IsarSetup.instance)
        .fightCurrentStagePhase0a(
          admission: await admit(),
          config: config,
          numbers: numbers,
        );

    final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
    // 战末快照真落地：maxHp 由 0（占位）→ 战斗真值，证明真建队+真战斗+真持久化。
    expect(
      run.members.single.maxHp,
      greaterThan(0),
      reason: '战末快照应捕获战斗 maxHp（生产链路真跑通）',
    );
    // 推进态与胜负自洽（不硬断胜负·避免 seed/角色战力耦合）。
    if (result.leftWin) {
      expect(run.sessionPhase, GauntletPhase.interlude);
      expect(run.currentStage, 2, reason: '胜非终关→整备+关次++');
    } else {
      expect(run.sessionPhase, GauntletPhase.inBattle);
      expect(run.currentStage, 1, reason: '败/平不推进·停当前关');
    }
  });

  test('fightCurrentStagePhase0a 拒非 inBattle（整备页）→ 抛错', () async {
    await seedSave(cleared: true);
    await putRun(
      phase: GauntletPhase.interlude,
      currentStage: 2,
      members: [snap(1, maxHp: 1000, currentHp: 500)],
    );
    final config = GameRepository.instance.bossGauntletConfig!;
    final numbers = GameRepository.instance.numbers;
    await expectLater(
      GauntletService(IsarSetup.instance).fightCurrentStagePhase0a(
        admission: await admit(),
        config: config,
        numbers: numbers,
      ),
      throwsStateError,
    );
  });

  test('continueToNextStage：interlude → inBattle（关次不变）', () async {
    await seedSave();
    final runId = await putRun(
      phase: GauntletPhase.interlude,
      currentStage: 2,
      members: [snap(1, maxHp: 1000, currentHp: 500)],
    );
    await GauntletService(IsarSetup.instance).continueToNextStage();
    final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
    expect(run.sessionPhase, GauntletPhase.inBattle);
    expect(run.currentStage, 2, reason: '续战只翻相位·关次已由上关 advance 递增');
  });

  test('continueToNextStage 拒非 interlude（inBattle）→ 抛错', () async {
    await seedSave();
    await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)],
    );
    await expectLater(
      GauntletService(IsarSetup.instance).continueToNextStage(),
      throwsStateError,
    );
  });

  // 注入测试配置：单关 boss + baseHp=1 弱敌 → seedP3 真角色必胜进 awaitingRewardChoice。
  BossGauntletConfig weakBossConfig() => const BossGauntletConfig(
    stages: [GauntletStageConfig(role: 'boss', enemyTeamId: 'weak')],
    supplyCap: 3,
    firstClearRewardSkillId: 'skill_x',
    rewardCandidateEquipmentIds: [
      'weapon_haojiahuo_qing_feng_jian',
      'armor_haojiahuo_jin_pao',
      'accessory_haojiahuo_yu_pei_lao',
    ],
    enemyTeams: {
      'weak': [
        EnemyDef(
          id: 'weak_e',
          name: '弱敌',
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          school: TechniqueSchool.gangMeng,
          baseHp: 1,
          baseAttack: 1,
          baseSpeed: 1,
          skillIds: ['skill_gangmeng_jichu_basic'],
          iconPath: '',
        ),
      ],
    },
  );

  BossGauntletConfig weakReplayConfig() => const BossGauntletConfig(
    stages: [
      GauntletStageConfig(role: 'elite', enemyTeamId: 'weak'),
      GauntletStageConfig(role: 'boss', enemyTeamId: 'weak'),
    ],
    supplyCap: 3,
    firstClearRewardSkillId: 'skill_x',
    rewardCandidateEquipmentIds: [
      'weapon_haojiahuo_qing_feng_jian',
      'armor_haojiahuo_jin_pao',
      'accessory_haojiahuo_yu_pei_lao',
    ],
    enemyTeams: {
      'weak': [
        EnemyDef(
          id: 'weak_replay_e',
          name: 'weak replay enemy',
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          school: TechniqueSchool.gangMeng,
          baseHp: 1,
          baseAttack: 1,
          baseSpeed: 1,
          skillIds: ['skill_gangmeng_jichu_basic'],
          iconPath: '',
        ),
      ],
    },
  );

  test('Phase0a replay 胜利固化三选一并停在待玩家选择态', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await markCleared();
    final runId = await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)],
    );
    final result = await GauntletService(IsarSetup.instance)
        .fightCurrentStagePhase0a(
          admission: await admit(),
          config: weakBossConfig(),
          numbers: GameRepository.instance.numbers,
        );
    expect(result.leftWin, isTrue, reason: 'baseHp=1 弱 boss 必败于真角色');
    final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
    expect(run.sessionPhase, GauntletPhase.awaitingRewardChoice);
    expect(run.rewardCandidateDefIds, [
      'weapon_haojiahuo_qing_feng_jian',
      'armor_haojiahuo_jin_pao',
      'accessory_haojiahuo_yu_pei_lao',
    ]);
    expect(run.isFirstClearPending, isFalse);
  });

  test('Phase0a Boss 胜利·已通关 → isFirstClearPending=false', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!
        ..clearedGauntletIds = [GauntletService.gauntletId];
      await IsarSetup.instance.saveDatas.put(save);
    });
    final runId = await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)],
    );
    await GauntletService(IsarSetup.instance).fightCurrentStagePhase0a(
      admission: await admit(),
      config: weakBossConfig(),
      numbers: GameRepository.instance.numbers,
    );
    final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
    expect(run.sessionPhase, GauntletPhase.awaitingRewardChoice);
    expect(run.isFirstClearPending, isFalse, reason: '已通关 → 非首通');
  });

  test(
    'public headless fight revalidates clear evidence before combat',
    () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      await markCleared();
      final runId = await putRun(
        phase: GauntletPhase.inBattle,
        currentStage: 1,
        members: [snap(1)],
      );
      final admission = await admit();
      await IsarSetup.instance.writeTxn(() async {
        final save = (await IsarSetup.instance.saveDatas.get(0))!;
        save.clearedGauntletIds = [];
        await IsarSetup.instance.saveDatas.put(save);
      });

      await expectLater(
        GauntletService(IsarSetup.instance).fightCurrentStagePhase0a(
          admission: admission,
          config: weakBossConfig(),
          numbers: GameRepository.instance.numbers,
        ),
        throwsStateError,
      );
      final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
      expect(run.sessionPhase, GauntletPhase.inBattle);
      expect(run.members.single.maxHp, 0, reason: 'rejection precedes combat');
    },
  );

  test('public headless fight rejects a stale stage admission', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await markCleared();
    final runId = await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)],
    );
    final admission = await admit();
    await IsarSetup.instance.writeTxn(() async {
      final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
      run.currentStage = 2;
      await IsarSetup.instance.bossGauntletRuns.put(run);
    });

    await expectLater(
      GauntletService(IsarSetup.instance).fightCurrentStagePhase0a(
        admission: admission,
        config: GameRepository.instance.bossGauntletConfig!,
        numbers: GameRepository.instance.numbers,
      ),
      throwsStateError,
    );
    final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
    expect(run.currentStage, 2);
    expect(run.members.single.maxHp, 0, reason: 'rejection precedes combat');
  });

  test('orchestrator rejects adversarial requests before any combat', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await markCleared();
    final runId = await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)],
    );
    final service = GauntletService(IsarSetup.instance);
    final requests = [
      automationRequest(contentKind: ActivityContentKind.mainline),
      automationRequest(contentId: 'another_gauntlet'),
      automationRequest(clock: ActivityClock.realtime),
      automationRequest(entryKind: ActivityEntryKind.firstClear),
    ];

    for (final request in requests) {
      await expectLater(
        service.driveHeadlessReplayToRewardChoice(
          request: request,
          config: weakBossConfig(),
          numbers: GameRepository.instance.numbers,
        ),
        throwsStateError,
      );
    }
    final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
    expect(run.sessionPhase, GauntletPhase.inBattle);
    expect(run.members.single.maxHp, 0);
  });

  test(
    'orchestrator reaches awaitingRewardChoice without claiming reward',
    () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      await markCleared();
      final runId = await putRun(
        phase: GauntletPhase.inBattle,
        currentStage: 1,
        members: [snap(1)],
      );
      final saveBefore = (await IsarSetup.instance.saveDatas.get(0))!;
      final clearedBefore = [...saveBefore.clearedGauntletIds];
      final inventoryBefore = await IsarSetup.instance.inventoryItems
          .where()
          .count();

      final result = await GauntletService(IsarSetup.instance)
          .driveHeadlessReplayToRewardChoice(
            request: automationRequest(),
            config: weakReplayConfig(),
            numbers: GameRepository.instance.numbers,
          );

      expect(
        result.terminal,
        GauntletAutomationDriveTerminal.awaitingRewardChoice,
      );
      expect(result.stagesCompleted, 2);
      final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
      expect(run.sessionPhase, GauntletPhase.awaitingRewardChoice);
      expect(run.rewardCandidateDefIds, hasLength(3));
      expect(
        (await IsarSetup.instance.saveDatas.get(0))!.clearedGauntletIds,
        clearedBefore,
      );
      expect(
        await IsarSetup.instance.inventoryItems.where().count(),
        inventoryBefore,
      );

      final candidates = [...run.rewardCandidateDefIds];
      final stage = run.currentStage;
      final memberState = (
        run.members.single.currentHp,
        run.members.single.currentQi,
        run.members.single.maxHp,
        run.members.single.maxQi,
      );
      final escrowLoaded = [...run.escrowLoadedQty];
      final escrowUsed = [...run.escrowUsedQty];
      final second = await GauntletService(IsarSetup.instance)
          .driveHeadlessReplayToRewardChoice(
            request: automationRequest(),
            config: weakReplayConfig(),
            numbers: GameRepository.instance.numbers,
          );
      expect(
        second.terminal,
        GauntletAutomationDriveTerminal.awaitingRewardChoice,
      );
      final unchanged = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
      expect(unchanged.rewardCandidateDefIds, candidates, reason: 'no reroll');
      expect(unchanged.sessionPhase, GauntletPhase.awaitingRewardChoice);
      expect(unchanged.currentStage, stage);
      expect((
        unchanged.members.single.currentHp,
        unchanged.members.single.currentQi,
        unchanged.members.single.maxHp,
        unchanged.members.single.maxQi,
      ), memberState);
      expect(unchanged.escrowLoadedQty, escrowLoaded);
      expect(unchanged.escrowUsedQty, escrowUsed);
      expect(
        await IsarSetup.instance.inventoryItems.where().count(),
        inventoryBefore,
      );
      expect(
        (await IsarSetup.instance.saveDatas.get(0))!.clearedGauntletIds,
        clearedBefore,
      );
    },
  );

  test('preparePhase0aStage 无存档 → 抛错', () async {
    // IsarSetup.init 自动建 SaveData id=0，须显式删除才是「无存档」。
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.delete(0);
    });
    final config = GameRepository.instance.bossGauntletConfig!;
    await expectLater(
      GauntletService(IsarSetup.instance).preparePhase0aStage(config: config),
      throwsStateError,
    );
  });

  test('preparePhase0aStage 无进行中会话 → 抛错', () async {
    await seedSave();
    final config = GameRepository.instance.bossGauntletConfig!;
    await expectLater(
      GauntletService(IsarSetup.instance).preparePhase0aStage(config: config),
      throwsStateError,
    );
  });

  test('preparePhase0aStage 关次越界（currentStage > 配置关数）→ 抛错', () async {
    await seedSave();
    await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 99, // 真配置仅 3 关
      members: [snap(1)],
    );
    final config = GameRepository.instance.bossGauntletConfig!;
    await expectLater(
      GauntletService(IsarSetup.instance).preparePhase0aStage(config: config),
      throwsStateError,
    );
  });

  test('preparePhase0aStage 敌队解析为空（配置损坏）→ 抛错', () async {
    await seedSave();
    await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)],
    );
    // enemyTeams 缺省空表 → enemyTeamId 解析为空队。
    const brokenConfig = BossGauntletConfig(
      stages: [GauntletStageConfig(role: 'elite', enemyTeamId: 'missing_team')],
      supplyCap: 3,
    );
    await expectLater(
      GauntletService(
        IsarSetup.instance,
      ).preparePhase0aStage(config: brokenConfig),
      throwsStateError,
    );
  });

  test('continueToNextStage 无存档 → 抛错', () async {
    // IsarSetup.init 自动建 SaveData id=0，须显式删除才是「无存档」。
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.delete(0);
    });
    await expectLater(
      GauntletService(IsarSetup.instance).continueToNextStage(),
      throwsStateError,
    );
  });

  test('continueToNextStage 无进行中会话 → 抛错', () async {
    await seedSave();
    await expectLater(
      GauntletService(IsarSetup.instance).continueToNextStage(),
      throwsStateError,
    );
  });
}
