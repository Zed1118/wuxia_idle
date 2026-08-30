import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

final class _HitResolver implements Phase0aDamageResolver {
  const _HitResolver();

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1.0,
  }) => const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 1);
}

void main() {
  late GameRepository repository;

  setUpAll(() async => repository = await loadTestGameRepository());
  tearDownAll(GameRepository.resetForTest);

  test('单段远程普攻与 held movement 同拍兼容且不附加攻击位移', () {
    final mapping = Phase0aStageContentMapper.map(
      stage: repository.getStage('stage_01_02'),
      playerSnapshot: testCombatantSnapshot(
        name: 'movement arbitration',
        includeProductionBasicAttack: true,
      ),
      numbers: repository.numbers,
    );
    final deltaSeconds = repository.numbers.phase0aArena.fixedDeltaSeconds;
    final initial = Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: mapping.initialState.player.copyWith(position: ArenaVector.zero),
      enemies: const [],
      skillSlots: mapping.initialState.skillSlots,
    );
    const heldMoveAndAttack = Phase0aPlayerCommand(
      right: true,
      attack: true,
      attackAimDirection: ArenaVector(1, 0),
    );

    final attackTick = reducePhase0aTick(
      state: initial,
      intents: mapping.playerAdapter.intentsFor(
        state: initial,
        command: heldMoveAndAttack,
      ),
      deltaSeconds: deltaSeconds,
      damageResolver: const _HitResolver(),
    );
    final ordinaryStep = initial.player.moveSpeed * deltaSeconds;

    expect(ordinaryStep, 21);
    expect(
      attackTick.state.player.position.x,
      ordinaryStep,
      reason: '远程普攻不得附加位移，同拍只保留正常移动的 21',
    );
    expect(attackTick.state.player.basicAttackSegmentIndex, 0);

    const heldMoveOnly = Phase0aPlayerCommand(right: true);
    final resumedTick = reducePhase0aTick(
      state: attackTick.state,
      intents: mapping.playerAdapter.intentsFor(
        state: attackTick.state,
        command: heldMoveOnly,
      ),
      deltaSeconds: deltaSeconds,
      damageResolver: const _HitResolver(),
    );

    expect(
      resumedTick.state.player.position.x,
      ordinaryStep * 2,
      reason: '远程普攻不得清除 held movement，下一拍应继续普通移动',
    );
  });
}
