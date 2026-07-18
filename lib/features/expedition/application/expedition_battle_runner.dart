import 'dart:math';

import '../../../data/numbers_config.dart';
import '../../battle/domain/battle_state.dart';
import '../../battle/domain/strategy/default_ground_strategy.dart';

/// headless 节点战斗结果（供离线结算 B2.2 消费）。
///
/// **设计：runner 只做「跑战斗 + 读存活」纯驱动**，不在内部调
/// `BattleResolutionService.resolve`——远征奖励走 `ExpeditionRules.rewardsForNode`
/// （非 resolve 掉落）；resolve 的修炼/伤势副作用需 Isar 载入的
/// Character/Equipment/Technique + DropService，归 B2.2 结算事务在 [finalState]
/// 上按需调用（保持本 runner 纯函数 + 确定性可测）。
class ExpeditionNodeBattleResult {
  const ExpeditionNodeBattleResult({
    required this.leftWin,
    required this.survivorHp,
    required this.survivorQi,
    required this.finalState,
  });

  /// 玩家方是否取胜（`BattleResult.leftWin`）；平局/战败均 false → 结算侧「战败即停」。
  final bool leftWin;

  /// characterId → 战后当前生命（含倒下者，倒下者为 0）。
  final Map<int, int> survivorHp;

  /// characterId → 战后当前真气。
  final Map<int, int> survivorQi;

  /// 终局战斗态；结算侧据此调 `BattleResolutionService.resolve`（修炼/伤势）。
  final BattleState finalState;
}

/// 百草岭节点 headless 自动战斗驱动（§4.5）。
///
/// 复用 `defaultGroundStrategy.runToEnd`（地面 3v3 逐 tick 制），确定性由
/// `Random(nodeSeed)` 保证；**不复用会自动跑完所有波次的群战策略**（§8.1）。
class ExpeditionBattleRunner {
  const ExpeditionBattleRunner._();

  /// 用已构建的出发队伍快照（含当前远征 HP/qi）+ 敌队 + 稳定 seed 跑一场自动战斗。
  ///
  /// [playerTeam]/[enemyTeam] 由结算侧从 `ExpeditionRun.members` 快照 +
  /// 节点敌队配置构建（`BattleCharacter.fromCharacter` 注入当前 HP/qi）。
  static ExpeditionNodeBattleResult runNodeBattle({
    required List<BattleCharacter> playerTeam,
    required List<BattleCharacter> enemyTeam,
    required NumbersConfig numbers,
    required int nodeSeed,
    int maxTicks = 240,
  }) {
    final initial = BattleState.initial(
      leftTeam: playerTeam,
      rightTeam: enemyTeam,
    );
    final terminal = defaultGroundStrategy.runToEnd(
      initial,
      numbers,
      maxTicks: maxTicks,
      rng: Random(nodeSeed),
    );
    final survivorHp = <int, int>{};
    final survivorQi = <int, int>{};
    for (final c in terminal.leftTeam) {
      survivorHp[c.characterId] = c.currentHp;
      survivorQi[c.characterId] = c.currentQi;
    }
    return ExpeditionNodeBattleResult(
      leftWin: terminal.result == BattleResult.leftWin,
      survivorHp: survivorHp,
      survivorQi: survivorQi,
      finalState: terminal,
    );
  }
}
