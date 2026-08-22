import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_win_condition.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

CombatantSnapshot makePlayer(NumbersConfig numbers) => testCombatantSnapshot(
  characterId: 1,
  name: 'survive_ticks_player',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.dengFeng,
  school: TechniqueSchool.lingQiao,
  maxHp: 20000,
  internalForce: 300,
  maxQi: 100,
  speed: 200,
  criticalRate: numbers.combat.critical.baseRate,
  evasionRate: 0,
  defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0,
  totalEquipmentAttack: 0,
  mainCultivationLayer: CultivationLayer.chuKui,
  includeProductionBasicAttack: true,
);

void main() {
  test('真实主线 stage_21_05 映射 surviveTicks 到 Phase 0A 初态', () async {
    final repo = await loadTestGameRepository();
    final stage = repo.getStage('stage_21_05');
    final mapping = Phase0aStageContentMapper.map(
      stage: stage,
      playerSnapshot: makePlayer(repo.numbers),
      numbers: repo.numbers,
    );

    expect(stage.winCondition?.type, StageWinConditionType.surviveTicks);
    expect(stage.winCondition?.surviveTicksRequired, 10);
    expect(mapping.winCondition?.type, Phase0aWinConditionType.surviveTicks);
    expect(mapping.winCondition?.surviveTicksRequired, 10);
    expect(mapping.initialState.winCondition, mapping.winCondition);
    expect(mapping.initialState.surviveTicksRemaining, 10);
  });
}
