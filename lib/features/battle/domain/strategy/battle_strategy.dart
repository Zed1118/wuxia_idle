import 'dart:math';

import '../../../../data/defs/skill_def.dart';
import '../../../../data/numbers_config.dart';
import '../battle_state.dart';

/// 战斗形态策略抽象基类(1.0 路线图 P0 抽 strategy 层重构)。
///
/// Demo 阶段唯一实装是 [DefaultGroundStrategy](地面 3v3 半横版,actionPoint 累
/// 1000 行动制 + 阴柔内伤 dot + 刚猛震伤)。P3 §12.3 三战斗形态扩展时直接挂
/// 自己的实装:
/// - LightFootStrategy(轻功对决,水面/屋脊/竹林地形修正)
/// - MassBattleStrategy(群战守城,5v5+ 阵型)
/// - PvpStrategy(异步快照对战,Supabase 接入)
///
/// 粗粒度 3 method(memory `feedback_avoid_over_engineer_abstraction`):Demo
/// 1 实装,P3 三形态真痛点在主循环,粗粒度足够;遇真痛点(选招 / 选目标
/// 跨形态差异)再加 hook。
///
/// **DefaultGroundStrategy 实现无 mutable state**:所有 method 接 [BattleState]
/// 入参输出新 state,与原 `BattleEngine.*` static 行为完全一致
/// (memory `feedback_layered_bugs` R3 风险条对策)。
abstract class BattleStrategy {
  const BattleStrategy();

  /// 推进一个 tick(对应原 `BattleEngine.tick`)。
  ///
  /// [rng] 用于伤害计算中的闪避 / 暴击 roll;测试传 `Random(seed)` 复现。
  BattleState tick(
    BattleState state,
    NumbersConfig n, {
    Random? rng,
  });

  /// 半手动战斗 P0 步骤3b:推进「最小一步」——tick 边界(填 actor 队列 +
  /// 推进 AP/CD,不结算)或结算队列中一个 actor。
  ///
  /// **默认实现退化为整 [tick]**(非地面形态/半手动 P0 范围外不细分 actor);
  /// [DefaultGroundStrategy] override 为真·逐 actor 单步,`tick()` 在其内重构
  /// 为「边界 stepOne + 循环 drain」,使 stepOne 成唯一 actor 结算真相源。
  ///
  /// [rng] 同 [tick]:仅在真正结算 actor 那一步消费;边界步不消费。
  BattleState stepOne(
    BattleState state,
    NumbersConfig n, {
    Random? rng,
  }) =>
      tick(state, n, rng: rng);

  /// 跑完整场战斗(对应原 `BattleEngine.runToEnd`)。
  ///
  /// [maxTicks] 兜底防死循环(境界差太大双方都基本免疫时触发上限 →
  /// [BattleResult.draw])。
  BattleState runToEnd(
    BattleState initial,
    NumbersConfig n, {
    int maxTicks = 1000,
    Random? rng,
  });

  /// 玩家手动请求大招(对应原 `BattleEngine.requestUltimate`)。
  ///
  /// 标记 pending;该角色下次行动时 BattleAI 优先消费。若内力 / CD 不满足,
  /// 引擎会跳过并从 pendingUltimates 移除(一次机会,不留到下次)。
  ///
  /// [targetId] 半手动 P0 步骤3a:玩家指定目标 charId;null = 走 AI 默认选目标。
  BattleState requestUltimate(
    BattleState state,
    int characterId,
    SkillDef ultimate, {
    int? targetId,
  });
}
