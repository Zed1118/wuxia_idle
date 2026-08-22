import '../../../data/defs/stage_def.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/battle_shared/enemy_combatant_snapshot_assembler.dart';
import '../../battle/application/legacy_3v3_combatant_adapter.dart';
import '../../battle/domain/battle_state.dart';
import '../../expedition/application/expedition_battle_runner.dart';

/// 断魂庄单关 headless 战斗结果（C1.3.3）。
class GauntletStageResult {
  const GauntletStageResult({required this.leftWin, required this.finalState});

  /// 玩家方是否取胜（`BattleResult.leftWin`）；平/败均 false。
  final bool leftWin;

  /// 终局战斗态；关次边界快照（`GauntletController.snapshotAfterStage`）与结算据此推进。
  final BattleState finalState;
}

/// 断魂庄单关战斗驱动（design §5.2-5.5）。
///
/// = 敌队合成（[EnemyCombatantSnapshotAssembler]）+ [ExpeditionBattleRunner.runNodeBattle]
/// （沿 Phase B 同 wiring · `Random(seed)` 逐 tick 确定性）。敌队机制（vulnerability
/// 窗口 / guardianWard 结界 / bossPhases 三阶段）由 `buildEnemyTeam` 从 [EnemyDef] 灌入
/// `BattleCharacter`（`vulnerabilityMult`/`guardianWardMult`/`bossPhases`），qi_drain 由
/// `default_ground_strategy` 消费（C1.3.1）——**runner 不额外注入任何机制**。
///
/// 玩家队伍（含当前 HP/qi/技能冷却）由 caller 从会话快照建好传入；Isar 载入 + 满血
/// 基准队注入归 C2.1 service（`PlayerCombatantSnapshotAssembler` 同远征路径），
/// 保持本 runner 纯 + 确定性可测。
class GauntletBattleRunner {
  const GauntletBattleRunner._();

  static GauntletStageResult runStage({
    required List<BattleCharacter> playerTeam,
    required List<EnemyDef> enemyDefs,
    required NumbersConfig numbers,
    required int seed,
    int cycleIndex = 1,
    int maxTicks = 240,
  }) {
    // 批 B：断魂庄属境界段推进入口（spec 拍板 #5），cycle≥2 敌境界整体抬升。
    final enemySnapshots = EnemyCombatantSnapshotAssembler.assembleAll(
      enemyDefs,
      cycleIndex: cycleIndex,
      advanceRealmPerCycle: true,
    );
    final enemies = Legacy3v3CombatantAdapter.enemyTeam(enemySnapshots);
    final result = ExpeditionBattleRunner.runNodeBattle(
      playerTeam: playerTeam,
      enemyTeam: enemies,
      numbers: numbers,
      nodeSeed: seed,
      maxTicks: maxTicks,
    );
    return GauntletStageResult(
      leftWin: result.leftWin,
      finalState: result.finalState,
    );
  }
}
