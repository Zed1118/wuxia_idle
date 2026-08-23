import 'dart:math' as math;

import 'arena_vector.dart';
import 'combat_geometry.dart';

/// 四向输入的移动方向归一化:对角输入归一到单位长度,
/// 单轴输入保持原长,反向按键互相抵消。y 轴向下为正。
ArenaVector normalizeMovementInput({
  required bool left,
  required bool right,
  required bool up,
  required bool down,
}) {
  var vector = ArenaVector(
    (right ? 1 : 0) - (left ? 1 : 0),
    (down ? 1 : 0) - (up ? 1 : 0),
  );
  if (vector.lengthSquared > 1) vector = vector.normalized();
  return vector;
}

/// 目标是否同时满足距离与朝向扇区。
///
/// 单目标生产选择的几何后端是 C02 [ForwardFanScope]。零长度朝向仍
/// 按 Phase 0A 既有语义映射为默认向右 (1, 0)；其余非法参数由 scope
/// fail closed。与原点重合的目标与距离/角度边界均保持闭区间语义。
bool isTargetInsideStrikeArc({
  required ArenaVector origin,
  required ArenaVector aimDirection,
  required ArenaVector target,
  required double range,
  required double halfArcRadians,
}) {
  final direction = aimDirection.lengthSquared == 0
      ? const ArenaVector(1, 0)
      : aimDirection;
  final accepted = ForwardFanScope(
    origin: origin,
    direction: direction,
    maxDistance: range,
    halfAngleRadians: halfArcRadians,
    maxTargets: 1,
  ).hitTargets([CombatGeometryTarget('_strike_target', target)]).isNotEmpty;
  if (!accepted) return false;

  // ForwardFanScope gives shared C02 validation/geometry, then this thin
  // compatibility refinement retains the former Phase 0A strict arc edge.
  // C02's generic epsilon is intentionally not allowed to widen production
  // attacks just outside their configured closed boundary.
  final delta = target - origin;
  if (delta.lengthSquared == 0) return true;
  final dot = direction.normalized().dot(delta.normalized()).clamp(-1.0, 1.0);
  return math.acos(dot) <= halfArcRadians;
}

/// 聚怪目标点:环外敌人沿来向投影到以玩家为中心的可读环上,
/// 已在环内(含恰好落环)者保持原位不被推走。
ArenaVector gatherRingDestination({
  required ArenaVector playerCenter,
  required ArenaVector enemyPosition,
  required double ringRadius,
}) {
  final delta = enemyPosition - playerCenter;
  if (delta.lengthSquared <= ringRadius * ringRadius) return enemyPosition;
  return playerCenter + delta.normalized() * ringRadius;
}

/// 精英破招窗口:仅蓄力预告的末段可破——剩余时间大于零且
/// 不超过窗口长度(闭区间)。窗口秒数由调用方显式传入。
bool isEliteBreakWindowOpen({
  required double telegraphRemainingSeconds,
  required double breakWindowSeconds,
}) =>
    telegraphRemainingSeconds > 0 &&
    telegraphRemainingSeconds <= breakWindowSeconds;
