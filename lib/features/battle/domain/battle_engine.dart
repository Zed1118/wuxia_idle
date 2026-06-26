import 'dart:math';

import '../../../data/defs/skill_def.dart';
import '../../../data/numbers_config.dart';
import 'battle_state.dart';
import 'strategy/battle_strategy.dart';
import 'strategy/default_ground_strategy.dart';

/// 战斗引擎门面(1.0 路线图 P0 抽 strategy 层重构后)。
///
/// 历史:phase1_tasks T12.1 起为单形态硬编码 static 类(467 行,
/// tick / runToEnd / requestUltimate + 7 私 helper + `_resolveAction` /
/// `_calculateInBattle` 内嵌阴柔内伤 dot + 刚猛震伤)。1.0 路线图 P0 抽 strategy
/// 层(详 `docs/handoff/p0_battle_strategy_spec.md`),本类保留为 facade,
/// 委派给注入的 [BattleStrategy] 实现(默认 [DefaultGroundStrategy])。
///
/// **向后兼容**:直接使用 `BattleEngine.tick / runToEnd / requestUltimate`
/// 等价于使用 [DefaultGroundStrategy](test/combat/* 25+ 处直调沿用,Phase 1-3
/// 实装期 0 改动);[BattleNotifier] 走 strategy 注入,轻功 / 群战等特殊战斗
/// 分别挂自己的 [BattleStrategy] 实装即可 plug-in。
class BattleEngine {
  BattleEngine._();

  static const BattleStrategy _default = DefaultGroundStrategy();

  /// 推进一个 tick(委派给默认 [DefaultGroundStrategy])。
  static BattleState tick(BattleState state, NumbersConfig n, {Random? rng}) =>
      _default.tick(state, n, rng: rng);

  /// 跑完整场战斗(委派给默认 [DefaultGroundStrategy])。
  static BattleState runToEnd(
    BattleState initial,
    NumbersConfig n, {
    int maxTicks = 1000,
    Random? rng,
  }) => _default.runToEnd(initial, n, maxTicks: maxTicks, rng: rng);

  /// 玩家手动请求大招(委派给默认 [DefaultGroundStrategy])。
  static BattleState requestUltimate(
    BattleState state,
    int characterId,
    SkillDef ultimate, {
    int? targetId,
  }) => _default.requestUltimate(
    state,
    characterId,
    ultimate,
    targetId: targetId,
  );
}
