import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/reward/application/reward_claim_plan.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_policy.dart';

void main() {
  test(
    'normal content first-clear is sect shared while repeat/growth are personal',
    () {
      final plan = RewardClaimPlan.forSettlement(
        contentKind: RewardContentKind.mainline,
        contentId: 'stage_01_01',
        saveDataId: 1,
        participantId: 9,
        occurrenceId: 'run-1',
        includesFirstClear: true,
      );

      expect(plan.firstClearKeys.map((key) => key.layer), [
        RewardLayer.firstClear,
      ]);
      expect(plan.recurringKeys.map((key) => key.layer), [
        RewardLayer.repeat,
        RewardLayer.personalGrowth,
      ]);
      expect(plan.firstClearKeys.single.scope, RewardScope.sectShared);
      expect(
        plan.recurringKeys.every((key) => key.scope == RewardScope.personal),
        isTrue,
      );
    },
  );

  test(
    'inner demon first-clear remains personal to the actual participant',
    () {
      final plan = RewardClaimPlan.forSettlement(
        contentKind: RewardContentKind.innerDemon,
        contentId: 'stage_inner_demon_01',
        saveDataId: 1,
        participantId: 9,
        occurrenceId: 'run-1',
        includesFirstClear: true,
      );

      final keys = [...plan.firstClearKeys, ...plan.recurringKeys];
      expect(keys.every((key) => key.scope == RewardScope.personal), isTrue);
      expect(keys.every((key) => key.participantId == 9), isTrue);
    },
  );
  test('combined participants deduplicate only their shared first clear', () {
    final plan = RewardClaimPlan.combine([
      for (final participantId in [9, 10, 9])
        RewardClaimPlan.forSettlement(
          contentKind: RewardContentKind.gauntlet,
          contentId: 'duanhun_v1',
          saveDataId: 1,
          participantId: participantId,
          occurrenceId: 'run-1',
          includesFirstClear: true,
        ),
    ]);
    expect(plan.firstClearKeys, hasLength(1));
    expect(plan.recurringKeys, hasLength(4));
    expect(plan.recurringKeys.map((key) => key.participantId).toSet(), {9, 10});
  });
}
