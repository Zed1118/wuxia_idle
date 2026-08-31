import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/reward/application/reward_claim_plan.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_policy.dart';

void main() {
  test(
    'normal content first-clear is sect shared while repeat/growth are personal',
    () {
      final keys = RewardClaimPlan.forSettlement(
        contentKind: RewardContentKind.mainline,
        contentId: 'stage_01_01',
        saveDataId: 1,
        participantId: 9,
        occurrenceId: 'run-1',
        includesFirstClear: true,
      );

      expect(keys.map((key) => key.layer), RewardLayer.values);
      expect(keys.first.scope, RewardScope.sectShared);
      expect(
        keys.skip(1).every((key) => key.scope == RewardScope.personal),
        isTrue,
      );
    },
  );

  test(
    'inner demon first-clear remains personal to the actual participant',
    () {
      final keys = RewardClaimPlan.forSettlement(
        contentKind: RewardContentKind.innerDemon,
        contentId: 'stage_inner_demon_01',
        saveDataId: 1,
        participantId: 9,
        occurrenceId: 'run-1',
        includesFirstClear: true,
      );

      expect(keys.every((key) => key.scope == RewardScope.personal), isTrue);
      expect(keys.every((key) => key.participantId == 9), isTrue);
    },
  );
}
