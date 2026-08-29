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

  test('进步斩出手拍不叠加普通移动且下一拍恢复 held movement 语义', () {
    final mapping = Phase0aStageContentMapper.map(
      stage: repository.getStage('stage_01_02'),
      playerSnapshot: testCombatantSnapshot(
        name: 'movement arbitration',
        includeProductionBasicAttack: true,
      ),
      numbers: repository.numbers,
    );
    final deltaSeconds = repository.numbers.phase0aArena.fixedDeltaSeconds;
    final advancing = repository.numbers.phase0aArena.basicAttackChain
        .tuningForSegmentId('sword_advancing_slash');
    final initial = Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: mapping.initialState.player.copyWith(
        position: ArenaVector.zero,
        basicAttackSegmentIndex: 2,
      ),
      enemies: const [],
      skillSlots: mapping.initialState.skillSlots,
    );
    const heldMoveAndAttack = Phase0aPlayerCommand(
      right: true,
      attack: true,
      attackAimDirection: ArenaVector(1, 0),
    );

    final advancingTick = reducePhase0aTick(
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
    expect(advancing.advanceDistance, 120);
    expect(
      advancingTick.state.player.position.x,
      advancing.advanceDistance,
      reason: '进步斩拍只能贡献 120，不能与普通移动叠成 21 + 120',
    );

    const heldMoveOnly = Phase0aPlayerCommand(right: true);
    final resumedTick = reducePhase0aTick(
      state: advancingTick.state,
      intents: mapping.playerAdapter.intentsFor(
        state: advancingTick.state,
        command: heldMoveOnly,
      ),
      deltaSeconds: deltaSeconds,
      damageResolver: const _HitResolver(),
    );

    expect(
      resumedTick.state.player.position.x,
      advancing.advanceDistance + ordinaryStep,
      reason: '进步斩不得清除 held movement，下一拍应继续普通移动',
    );
  });
}
