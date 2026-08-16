import '../../domain/phase0a/arena_vector.dart';

/// Phase 0A 表现层 token 集中地:布局 / 阈值 / 池上限唯一定义处。
///
/// 本切片不产生动画时长 token;后续切片如需 Duration 字面量,
/// 一律新增在本文件,其余文件禁止写 `const Duration(...)`。
abstract final class Phase0aPresentationTokens {
  /// 世界可活动范围(脚底锚点语义坐标,y 向下为正)。
  static const ArenaVector worldMin = ArenaVector(-400, 0);
  static const ArenaVector worldMax = ArenaVector(400, 240);

  /// safeRect 相对视口的四向内边距(像素)。
  static const double safeMarginHorizontal = 32;
  static const double safeMarginVertical = 24;

  /// 世界四角映射时距 safeRect 右/下边界的内缩像素,
  /// 保证角点落在 Rect.contains 的半开区间内。
  static const double screenEdgeInset = 1;

  /// 纵深缩放范围:worldMin.y 处取 [depthScaleMin],
  /// worldMax.y 处取 [depthScaleMax],中间线性插值。
  static const double depthScaleMin = 0.75;
  static const double depthScaleMax = 1.25;

  /// 玩家普攻命中距离达到该值(世界单位)才产生掌风轨迹。
  static const double palmTrailMinDistance = 120;

  /// 单次 consume 伤害飘字 entry 上限。
  static const int maxDamagePopups = 48;

  /// 单次 consume 全部 VFX entry 上限。
  static const int maxEntries = 160;
}
