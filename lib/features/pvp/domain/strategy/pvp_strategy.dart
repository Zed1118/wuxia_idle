import 'dart:math';

import '../../../../data/defs/skill_def.dart';
import '../../../../data/numbers_config.dart';
import '../../../battle/domain/battle_state.dart';
import '../../../battle/domain/strategy/battle_strategy.dart';
import '../../../battle/domain/strategy/default_ground_strategy.dart';

/// PVP 异步快照对决策略(1.0 P3.3 §12.3,spec p3_3_pvp_spec_2026-05-24)。
///
/// **组合委派架构**(memory `feedback_avoid_over_engineer_abstraction`,沿
/// [LightFootStrategy] 体例):内部持 `const DefaultGroundStrategy _delegate`,
/// zero 代码重复;tick/requestUltimate 直接委派,runToEnd 入口把 [opponentTeam]
/// 装到 rightTeam,再委派 _delegate.runToEnd。
///
/// **数值红线**:0 引入 `attackPowerMultiplier`(§5.4 反 ELO 段位 buff 越权,
/// R3.6 测族兜底)。ELO 仅 UI 段位词,不进 BattleEngine。
///
/// **immutable**:opponentTeam ctor 注入,runToEnd 入口 hydrate 1 次 idempotent;
/// 不持任何 mutable instance state(沿 DefaultGroundStrategy / LightFootStrategy
/// 体例)。
class PvpStrategy extends BattleStrategy {
  /// 对手阵容(NoopPvpSync 本地 mirror 生成 / Phase 5 SupabasePvpSync 从快照解码)。
  final List<BattleCharacter> opponentTeam;

  /// 内部委派 strategy(沿 DefaultGroundStrategy tick 主循环)。
  static const _delegate = DefaultGroundStrategy();

  const PvpStrategy({required this.opponentTeam});

  /// 跑完整场战斗。入口把 opponentTeam 注入 rightTeam,然后委派 _delegate.runToEnd。
  ///
  /// 双方对等不烘焙额外 stat(对比 LightFootStrategy 烘焙 terrain modifier);
  /// PVP 形态唯一变化点 = 对手阵容来自异步快照而非 stages.yaml,无地形/阵型修饰。
  @override
  BattleState runToEnd(
    BattleState initial,
    NumbersConfig n, {
    int maxTicks = 1000,
    Random? rng,
  }) {
    final hydrated = initial.copyWith(
      rightTeam: List.unmodifiable(opponentTeam),
    );
    return _delegate.runToEnd(hydrated, n, maxTicks: maxTicks, rng: rng);
  }

  @override
  BattleState tick(
    BattleState state,
    NumbersConfig n, {
    Random? rng,
  }) =>
      _delegate.tick(state, n, rng: rng);

  @override
  BattleState requestUltimate(
    BattleState state,
    int characterId,
    SkillDef ultimate, {
    int? targetId,
  }) =>
      _delegate.requestUltimate(state, characterId, ultimate,
          targetId: targetId);
}
