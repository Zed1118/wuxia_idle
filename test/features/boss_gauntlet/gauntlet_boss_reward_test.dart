import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_controller.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_config.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';

/// C2.4b：Boss 胜利固化奖励候选 + 首通判定（`GauntletController.stageBossReward`）。
/// 纯层：进入 awaitingRewardChoice 时把 config 三选一候选固化进 run，选择前不可重抽；
/// 首通判定由 caller 传 [alreadyCleared]（`SaveData.clearedGauntletIds` 派生）。
void main() {
  const config = BossGauntletConfig(
    stages: [GauntletStageConfig(role: 'boss', enemyTeamId: 't')],
    supplyCap: 3,
    firstClearRewardSkillId: 'skill_x',
    rewardCandidateEquipmentIds: ['eq1', 'eq2', 'eq3'],
  );

  BossGauntletRun runAt(GauntletPhase phase) => BossGauntletRun()
    ..saveDataId = 0
    ..seed = 0
    ..currentStage = 3
    ..sessionPhase = phase;

  test('awaitingRewardChoice + 首通 → 候选固化·isFirstClearPending=true', () {
    final run = runAt(GauntletPhase.awaitingRewardChoice);
    GauntletController.stageBossReward(
      run: run,
      config: config,
      alreadyCleared: false,
    );
    expect(run.rewardCandidateDefIds, ['eq1', 'eq2', 'eq3']);
    expect(run.isFirstClearPending, true);
  });

  test('awaitingRewardChoice + 已通关 → 候选固化·isFirstClearPending=false', () {
    final run = runAt(GauntletPhase.awaitingRewardChoice);
    GauntletController.stageBossReward(
      run: run,
      config: config,
      alreadyCleared: true,
    );
    expect(run.rewardCandidateDefIds, ['eq1', 'eq2', 'eq3']);
    expect(run.isFirstClearPending, false);
  });

  test('非 awaitingRewardChoice（interlude）→ 不固化（no-op）', () {
    final run = runAt(GauntletPhase.interlude);
    GauntletController.stageBossReward(
      run: run,
      config: config,
      alreadyCleared: false,
    );
    expect(run.rewardCandidateDefIds, isEmpty);
    expect(run.isFirstClearPending, false);
  });
}
