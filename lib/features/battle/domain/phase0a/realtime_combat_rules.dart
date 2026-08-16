import 'dart:math' as math;

import 'arena_vector.dart';

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
/// 零长度朝向按默认向右 (1, 0) 处理;与原点重合的目标视为恒在范围内;
/// 扇区角按闭区间判定。
bool isTargetInsideStrikeArc({
  required ArenaVector origin,
  required ArenaVector aimDirection,
  required ArenaVector target,
  required double range,
  required double halfArcRadians,
}) {
  final delta = target - origin;
  if (delta.lengthSquared > range * range) return false;
  if (delta.lengthSquared == 0) return true;
  final aim = aimDirection.lengthSquared == 0
      ? ArenaVector(1, 0)
      : aimDirection.normalized();
  final direction = delta.normalized();
  final dot = aim.dot(direction).clamp(-1.0, 1.0);
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
