import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_win_condition.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/legacy_3v3_combatant_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';

import '../../../../support/test_data.dart';

BattleCharacter makePlayer(NumbersConfig numbers) => BattleCharacter(
  characterId: 1,
  name: 'survive_ticks_player',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.dengFeng,
  school: TechniqueSchool.lingQiao,
  maxHp: 20000,
  currentHp: 20000,
  internalForce: 300,
  maxQi: 100,
  currentQi: 100,
  speed: 200,
  criticalRate: numbers.combat.critical.baseRate,
  evasionRate: 0,
  defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0,
  totalEquipmentAttack: 0,
  mainCultivationLayer: CultivationLayer.chuKui,
  availableSkills: const [],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: true,
  teamSide: 0,
  slotIndex: 0,
);

void main() {
  test('真实主线 stage_21_05 映射 surviveTicks 到 Phase 0A 初态', () async {
    final repo = await loadTestGameRepository();
    final stage = repo.getStage('stage_21_05');
    final mapping = Phase0aStageContentMapper.map(
      stage: stage,
      playerSnapshot: Legacy3v3CombatantAdapter.toSnapshot(
        makePlayer(repo.numbers),
      ),
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
