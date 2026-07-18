import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/data/defs/boss_gauntlet_config.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// C2.3a 单场战斗驱动生产路径 e2e（feedback_layered_bugs 守卫：pure 测过 ≠ 真落地）。
///
/// `GauntletService.fightCurrentStage` = load run → 从真角色建满血基准队
/// （`buildPlayerTeamForCharacters`）→ `stagePlayerTeam` 按快照装配 → `runStage`
/// （seed 混 currentStage）→ `advance` → **单事务原子持久化**。原子性即崩溃安全：
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

  Future<void> seedSave() async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.37.0'
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

  test('fightCurrentStage 驱动真战斗并原子持久化战末快照（生产路径）', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final runId = await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)], // maxHp=0 = 首关占位·满血基准出战
    );
    final config = GameRepository.instance.bossGauntletConfig!;
    final numbers = GameRepository.instance.numbers;

    final result = await GauntletService(
      IsarSetup.instance,
    ).fightCurrentStage(config: config, numbers: numbers);

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

  test('fightCurrentStage 拒非 inBattle（整备页）→ 抛错', () async {
    await seedSave();
    await putRun(
      phase: GauntletPhase.interlude,
      currentStage: 2,
      members: [snap(1, maxHp: 1000, currentHp: 500)],
    );
    final config = GameRepository.instance.bossGauntletConfig!;
    final numbers = GameRepository.instance.numbers;
    await expectLater(
      GauntletService(
        IsarSetup.instance,
      ).fightCurrentStage(config: config, numbers: numbers),
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
          skillIds: [],
          iconPath: '',
        ),
      ],
    },
  );

  test('fightCurrentStage Boss 胜利固化三选一候选 + 首通判定（生产 wiring）', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final runId = await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)],
    );
    final result = await GauntletService(IsarSetup.instance).fightCurrentStage(
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
    expect(
      run.isFirstClearPending,
      isTrue,
      reason: 'clearedGauntletIds 空 → 首通',
    );
  });

  test('fightCurrentStage Boss 胜利·已通关 → isFirstClearPending=false', () async {
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
    await GauntletService(IsarSetup.instance).fightCurrentStage(
      config: weakBossConfig(),
      numbers: GameRepository.instance.numbers,
    );
    final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
    expect(run.sessionPhase, GauntletPhase.awaitingRewardChoice);
    expect(run.isFirstClearPending, isFalse, reason: '已通关 → 非首通');
  });
}
