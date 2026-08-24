import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/boss_gauntlet_config.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_automation_admission.dart';
import 'package:wuxia_idle/shared/battle_shared/player_combatant_snapshot_assembler.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_controller.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_phase0a_gauntlet_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<int> putRun({
    required int stage,
    required List<ActivityMemberSnapshot> members,
    GauntletPhase phase = GauntletPhase.inBattle,
  }) => IsarSetup.instance.writeTxn(() async {
    return IsarSetup.instance.bossGauntletRuns.put(
      BossGauntletRun()
        ..saveDataId = 0
        ..seed = 8202
        ..currentStage = stage
        ..sessionPhase = phase
        ..members = members
        ..escrowItemDefIds = ['item_healing_pill']
        ..escrowLoadedQty = [2]
        ..escrowUsedQty = [1],
    );
  });

  ActivityMemberSnapshot member({
    int hp = 0,
    int qi = 0,
    int maxHp = 0,
    int maxQi = 0,
  }) => ActivityMemberSnapshot()
    ..characterId = 1
    ..currentHp = hp
    ..currentQi = qi
    ..maxHp = maxHp
    ..maxQi = maxQi;

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
          id: 'weak_phase0a_gauntlet',
          name: 'weak',
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

  test('单角色三连战逐关推进并保留 HP/真气、补给与阶段状态', () {
    final run = BossGauntletRun()
      ..saveDataId = 0
      ..seed = 1
      ..currentStage = 1
      ..sessionPhase = GauntletPhase.inBattle
      ..members = [member()]
      ..escrowItemDefIds = ['item_healing_pill']
      ..escrowLoadedQty = [2]
      ..escrowUsedQty = [1];

    void winStage({required int hp, required int qi, required bool boss}) {
      GauntletController.advancePhase0a(
        run: run,
        checkpoint: GauntletMemberCheckpoint(
          characterId: 1,
          currentHp: hp,
          currentQi: qi,
          maxHp: 100,
          maxQi: 80,
        ),
        leftWin: true,
        isBossStage: boss,
      );
    }

    winStage(hp: 81, qi: 52, boss: false);
    expect((run.currentStage, run.sessionPhase), (2, GauntletPhase.interlude));
    expect(
      (run.members.single.currentHp, run.members.single.currentQi),
      (81, 52),
    );
    run.sessionPhase = GauntletPhase.inBattle;

    winStage(hp: 63, qi: 41, boss: false);
    expect((run.currentStage, run.sessionPhase), (3, GauntletPhase.interlude));
    expect(
      (run.members.single.currentHp, run.members.single.currentQi),
      (63, 41),
    );
    run.sessionPhase = GauntletPhase.inBattle;

    winStage(hp: 35, qi: 24, boss: true);
    expect(run.sessionPhase, GauntletPhase.awaitingRewardChoice);
    expect(
      (run.members.single.currentHp, run.members.single.currentQi),
      (35, 24),
    );
    expect(run.escrowLoadedQty, [2]);
    expect(run.escrowUsedQty, [1]);
  });

  test('preparePhase0aStage 跨关恢复会话 HP/真气并保留补给与阶段', () async {
    final base = await PlayerCombatantSnapshotAssembler(
      isar: IsarSetup.instance,
    ).loadExactRoster([1]);
    final hp = base.single.maxHp - 7;
    final qi = base.single.maxQi - 3;
    await putRun(
      stage: 2,
      members: [
        member(
          hp: hp,
          qi: qi,
          maxHp: base.single.maxHp,
          maxQi: base.single.maxQi,
        ),
      ],
    );

    final plan = await GauntletService(
      IsarSetup.instance,
    ).preparePhase0aStage(config: GameRepository.instance.bossGauntletConfig!);
    final run = (await IsarSetup.instance.bossGauntletRuns
        .where()
        .findFirst())!;

    expect(plan.playerSnapshot.currentHp, hp);
    expect(plan.playerSnapshot.currentQi, qi);
    expect(run.currentStage, 2);
    expect(run.sessionPhase, GauntletPhase.inBattle);
    expect(run.escrowLoadedQty, [2]);
    expect(run.escrowUsedQty, [1]);
  });

  test('Phase 0A Boss 胜利原子写回检查点并进入奖励选择态', () async {
    final service = GauntletService(IsarSetup.instance);
    final base = await PlayerCombatantSnapshotAssembler(
      isar: IsarSetup.instance,
    ).loadExactRoster([1]);
    await putRun(stage: 1, members: [member()]);
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.clearedGauntletIds = [GauntletService.gauntletId];
      await IsarSetup.instance.saveDatas.put(save);
    });
    final request = ActivityParticipationRequest(
      contentId: GauntletService.gauntletId,
      contentKind: ActivityContentKind.gauntlet,
      characterId: 1,
      loadoutPlanId: 'gauntlet-plan-1',
      participation: ActivityParticipationMode.direct,
      controller: ActivityController.playerBot,
      clock: ActivityClock.headless,
      entryKind: ActivityEntryKind.replay,
    );
    final admission = await GauntletAutomationAdmissionService(
      IsarSetup.instance,
    ).admit(request: request);

    final result = await service.fightCurrentStagePhase0a(
      admission: admission,
      config: weakBossConfig(),
      numbers: GameRepository.instance.numbers,
    );
    final run = (await IsarSetup.instance.bossGauntletRuns
        .where()
        .findFirst())!;

    expect(result.leftWin, isTrue);
    expect(run.sessionPhase, GauntletPhase.awaitingRewardChoice);
    expect(run.members.single.maxHp, base.single.maxHp);
    expect(
      run.members.single.currentHp,
      inInclusiveRange(1, run.members.single.maxHp),
    );
    expect(
      run.members.single.currentQi,
      inInclusiveRange(0, run.members.single.maxQi),
    );
    expect(run.escrowLoadedQty, [2]);
    expect(run.escrowUsedQty, [1]);
    expect(run.rewardCandidateDefIds, hasLength(3));
  });

  test('Phase 0A 计划拒绝历史多人会话误入', () async {
    await putRun(stage: 1, members: [member(), member()..characterId = 2]);

    await expectLater(
      GauntletService(IsarSetup.instance).preparePhase0aStage(
        config: GameRepository.instance.bossGauntletConfig!,
      ),
      throwsStateError,
    );
  });
}
