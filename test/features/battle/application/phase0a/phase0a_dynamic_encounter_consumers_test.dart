import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';

Phase0aActor _actor(String id, Phase0aSide side) => Phase0aActor(
  id: id,
  side: side,
  position: side == Phase0aSide.player
      ? ArenaVector.zero
      : const ArenaVector(50, 0),
  facing: const ArenaVector(1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

final class _NoDamage implements Phase0aDamageResolver {
  const _NoDamage();

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderCharging = false,
    required double defenderWardMult,
  }) => const Phase0aResolvedHit(isHit: false, isCritical: false, damage: 0);
}

final class _Built {
  _Built(this.flow, this.playerAdapter);

  final Phase0aEncounterFlow flow;
  final Phase0aPlayerInputAdapter playerAdapter;
}

_Built _buildFlow() {
  final director = SpawnDirector(
    config: SpawnDirectorConfig(
      activeLimit: 1,
      reinforcementThreshold: 0,
      entryWarningTicks: 0,
      attackGraceTicks: 1,
    ),
    entries: [SpawnEntry(entryId: 'entry_blade', enemyId: 'wave1_blade')],
  );
  final roster = Phase0aEncounterRoster(
    director: director,
    playerId: 'player',
    bindings: [
      Phase0aEncounterRosterBinding(
        entryId: 'entry_blade',
        actor: _actor('wave1_blade', Phase0aSide.enemy),
      ),
    ],
  );
  const playerAdapter = Phase0aPlayerInputAdapter(
    playerId: 'player',
    attackRange: 100,
    attackHalfArcRadians: 3.14,
    attackCooldownSeconds: 0,
    attackQiDelta: 0,
    gatherSlot: 'gather',
    gatherRingRadius: 1,
    gatherEffectRadius: 1,
    gatherQiCost: 0,
    gatherCooldownSeconds: 0,
    clearSlot: 'clear',
    clearEffectRadius: 1,
    clearQiCost: 0,
    clearCooldownSeconds: 0,
  );
  final session = Phase0aCombatSession(
    initialState: Phase0aArenaState(
      tick: 0,
      nextSeq: 0,
      player: _actor('player', Phase0aSide.player),
      enemies: const [],
      skillSlots: const [],
    ),
    playerAdapter: playerAdapter,
    enemyAiAdapter: const Phase0aEnemyAiAdapter(
      attackRange: 100,
      attackHalfArcRadians: 3.14,
      attackCooldownSeconds: 0,
    ),
    damageResolver: const _NoDamage(),
  );
  return _Built(
    Phase0aEncounterFlow.runtime(
      session: session,
      director: director,
      roster: roster,
    ),
    playerAdapter,
  );
}

void main() {
  test('headless 同 seed/同 command 的同步与异步消费完全一致', () async {
    final sync = _buildFlow();
    final asyncFlow = _buildFlow();
    final syncResult = Phase0aHeadlessRunner.runToEnd(
      flow: sync.flow,
      bot: Phase0aPlayerBotAdapter(playerAdapter: sync.playerAdapter),
      deltaSeconds: 1,
      maxTicks: 3,
    );
    final asyncResult = await Phase0aHeadlessRunner.runToEndAsync(
      flow: asyncFlow.flow,
      bot: Phase0aPlayerBotAdapter(playerAdapter: asyncFlow.playerAdapter),
      deltaSeconds: 1,
      maxTicks: 3,
      yieldEveryTicks: 1,
    );
    expect(asyncResult.outcome, syncResult.outcome);
    expect(asyncResult.ticks, syncResult.ticks);
    expect(asyncResult.finalState, syncResult.finalState);
    expect(asyncResult.events, syncResult.events);
    expect(asyncResult.eventRecords, syncResult.eventRecords);
  });

  test('controller 只消费 runtime flow，不复制 reducer/session', () {
    final built = _buildFlow();
    final controller = Phase0aBattleController(
      flow: built.flow,
      roster: Phase0aVisualRoster.debugBattle(),
      fixedDeltaSeconds: 1,
    );
    final events = controller.step();
    expect(events, isNotEmpty);
    expect(controller.state, built.flow.state);
    expect(controller.lastEventRecords, built.flow.lastOrderedEventRecords);
    expect(controller.feedback, isNotNull);
  });
}
