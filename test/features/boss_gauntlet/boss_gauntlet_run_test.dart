import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';

void main() {
  test('BossGauntletRun 默认停在第一关·战斗态，托管三列表平行', () {
    final run = BossGauntletRun()
      ..saveDataId = 1
      ..seed = 999
      ..escrowItemDefIds = ['item_liaoshangdan', 'item_xingnang_buji']
      ..escrowLoadedQty = [2, 1]
      ..escrowUsedQty = [0, 0];
    expect(run.currentStage, 1);
    expect(run.sessionPhase, GauntletPhase.inBattle);
    expect(run.isFirstClearPending, isFalse);
    expect(run.rewardCandidateDefIds, isEmpty);
    // 托管三列表等长（不变式，Phase C2 消费）
    expect(run.escrowLoadedQty.length, run.escrowItemDefIds.length);
    expect(run.escrowUsedQty.length, run.escrowItemDefIds.length);
  });

  test('会话阶段枚举含 awaitingRewardChoice（Q4 崩溃恢复锚点）', () {
    expect(GauntletPhase.values, contains(GauntletPhase.awaitingRewardChoice));
  });
}
