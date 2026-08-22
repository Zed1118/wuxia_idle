import '../../../data/defs/stage_def.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/utils/math_random.dart';
import '../../battle/application/phase0a/phase0a_headless_runner.dart';
import '../../battle/application/phase0a/phase0a_player_bot_adapter.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../../battle/domain/phase0a/phase0a_combat_model.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import 'gauntlet_controller.dart';

final class Phase0aGauntletStageResult {
  const Phase0aGauntletStageResult({
    required this.outcome,
    required this.finalState,
    required this.mapping,
  });

  final Phase0aBattleOutcome outcome;
  final Phase0aArenaState finalState;
  final Phase0aStageMapping mapping;

  bool get leftWin => outcome == Phase0aBattleOutcome.victory;

  GauntletMemberCheckpoint get checkpoint {
    final snapshot = mapping.combatants
        .singleWhere((entry) => entry.actorId == mapping.initialState.player.id)
        .snapshot;
    return GauntletMemberCheckpoint(
      characterId: snapshot.characterId,
      currentHp: finalState.player.currentHealth,
      currentQi: finalState.player.qiCurrent,
      maxHp: finalState.player.maxHealth,
      maxQi: finalState.player.qiMax,
    );
  }
}

/// 断魂庄 Phase 0A 单关 headless runner；会话与奖励事务仍归 GauntletService。
final class Phase0aGauntletStageRunner {
  const Phase0aGauntletStageRunner._();

  static const int _uiYieldEveryTicks = 32;

  static Future<Phase0aGauntletStageResult> run({
    required String contentId,
    required CombatantSnapshot playerSnapshot,
    required List<EnemyDef> enemyTeam,
    required NumbersConfig numbers,
    required int seed,
    required int cycleIndex,
  }) async {
    final mapping = Phase0aStageContentMapper.mapExpedition(
      contentId: contentId,
      enemyTeam: enemyTeam,
      playerSnapshot: playerSnapshot,
      numbers: numbers,
      cycleIndex: cycleIndex,
    );
    final flow = Phase0aProductionFlowAssembler.assemble(
      initialState: mapping.initialState,
      waves: mapping.waves,
      combatants: mapping.combatants,
      moveBindings: mapping.moveBindings,
      numbers: numbers,
      rng: newMathRandom(seed: seed),
      playerAdapter: mapping.playerAdapter,
      enemyAiAdapter: mapping.enemyAiAdapter,
    );
    final result = await Phase0aHeadlessRunner.runToEndAsync(
      flow: flow,
      bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
      deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
      maxTicks: numbers.phase0aArena.maxSimulationTicks,
      yieldEveryTicks: _uiYieldEveryTicks,
    );
    return Phase0aGauntletStageResult(
      outcome: result.outcome,
      finalState: result.finalState,
      mapping: mapping,
    );
  }
}
