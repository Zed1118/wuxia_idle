import 'dart:math' as math;

/// Phase 0A 竞技场二维坐标/方向值对象。
///
/// 纯 Dart(不依赖 dart:ui / Flutter / Flame)、不可变;y 轴向下为正,
/// 与已验证策略的屏幕坐标口径一致。零向量归一化安全返回零向量。
final class ArenaVector {
  const ArenaVector(this.x, this.y);

  static const ArenaVector zero = ArenaVector(0, 0);

  final double x;
  final double y;

  double get lengthSquared => x * x + y * y;

  double get length => math.sqrt(lengthSquared);

  ArenaVector operator +(ArenaVector other) =>
      ArenaVector(x + other.x, y + other.y);

  ArenaVector operator -(ArenaVector other) =>
      ArenaVector(x - other.x, y - other.y);

  ArenaVector operator *(double scale) => ArenaVector(x * scale, y * scale);

  double dot(ArenaVector other) => x * other.x + y * other.y;

  ArenaVector normalized() {
    final magnitude = length;
    if (magnitude == 0) return ArenaVector.zero;
    return ArenaVector(x / magnitude, y / magnitude);
  }

  @override
  bool operator ==(Object other) =>
      other is ArenaVector && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'ArenaVector($x, $y)';
}
