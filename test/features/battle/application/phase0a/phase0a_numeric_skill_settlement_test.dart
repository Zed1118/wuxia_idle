import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

void main() async {
  final repository = await loadTestGameRepository();
  final numbers = repository.numbers;
  const realSkill = SkillDef(
    id: 'real_numeric_skill',
    name: 'real_numeric_skill',
    description: 'test',
    type: SkillType.powerSkill,
    powerMultiplier: 100,
    qiDelta: -10,
    cooldownTurns: 1,
    requiresManualTrigger: false,
    visualEffect: '',
  );
  final player = testCombatantSnapshot(
    characterId: 1,
    name: 'settlement player',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    maxHp: 100,
    internalForce: 10,
    maxQi: 100,
    speed: 100,
    criticalRate: 0,
    evasionRate: 0,
    defenseRate: 0,
    totalEquipmentAttack: 10,
    mainCultivationLayer: CultivationLayer.chuKui,
    includeProductionBasicAttack: true,
    availableSkills: [realSkill],
  );
  final mapping = Phase0aStageContentMapper.map(
    stage: repository.getStage('stage_01_01'),
    playerSnapshot: player,
    numbers: numbers,
  );

  Phase0aArenaState finalState() => mapping.initialState;

  test('terminal state missing the mapped player actor fails closed', () {
    final state = finalState();
    final malformed = Phase0aArenaState(
      tick: state.tick,
      nextSeq: state.nextSeq,
      player: state.enemies.single,
      enemies: state.enemies,
      skillSlots: state.skillSlots,
      winCondition: state.winCondition,
    );

    expect(
      () => Phase0aSettlementAdapter.fromMapping(
        mapping: mapping,
        outcome: Phase0aBattleOutcome.victory,
        finalState: malformed,
        events: const [],
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('player actor mismatch'),
        ),
      ),
    );
  });

  test('mapping missing its player combatant fails closed', () {
    final malformed = Phase0aStageMapping(
      initialState: mapping.initialState,
      waves: mapping.waves,
      combatants: [
        for (final combatant in mapping.combatants)
          if (combatant.actorId != mapping.initialState.player.id) combatant,
      ],
      winCondition: mapping.winCondition,
      moveBindings: mapping.moveBindings,
      playerAdapter: mapping.playerAdapter,
      enemyAiAdapter: mapping.enemyAiAdapter,
      numericSkillBindings: mapping.numericSkillBindings,
      waveTransitionPolicy: mapping.waveTransitionPolicy,
    );

    expect(
      () => Phase0aSettlementAdapter.fromMapping(
        mapping: malformed,
        outcome: Phase0aBattleOutcome.victory,
        finalState: finalState(),
        events: const [],
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('exactly one mapped player actor'),
        ),
      ),
    );
  });

  test(
    'numeric skill events settle by real skill id and actor character id',
    () {
      final settlement = Phase0aSettlementAdapter.fromMapping(
        mapping: mapping,
        outcome: Phase0aBattleOutcome.victory,
        finalState: finalState(),
        events: const [
          Phase0aSkillStarted(
            seq: 1,
            tick: 7,
            actor: 'player',
            hotkey: 1,
            skillId: 'real_numeric_skill',
          ),
          Phase0aSkillApplied(
            seq: 2,
            tick: 7,
            actor: 'player',
            hotkey: 1,
            skillId: 'real_numeric_skill',
            outcomes: [
              Phase0aSkillOutcome(
                target: 'enemy',
                resolvedDamage: 42,
                isCritical: true,
                defeated: false,
                statusApplied: Phase0aSkillStatus.none,
              ),
            ],
          ),
        ],
      );

      expect(settlement.skillCasts.single.skillId, 'real_numeric_skill');
      expect(settlement.skillCasts.single.characterId, 1);
      expect(settlement.skillCasts.single.tick, 7);
      expect(settlement.totalDamage, 42);
      expect(settlement.criticalCount, 1);
      expect(settlement.damageByCharacterId[1], 42);
    },
  );

  test(
    'unavailable skill id is not recorded and hotkey is never persisted',
    () {
      final settlement = Phase0aSettlementAdapter.fromMapping(
        mapping: mapping,
        outcome: Phase0aBattleOutcome.victory,
        finalState: finalState(),
        events: const [
          Phase0aSkillStarted(
            seq: 1,
            tick: 3,
            actor: 'player',
            hotkey: 6,
            skillId: 'internal_skill6_kind',
          ),
        ],
      );

      expect(settlement.skillCasts, isEmpty);
    },
  );
}
