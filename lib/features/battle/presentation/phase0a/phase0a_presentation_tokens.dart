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

  // ── 技能印(skill_seals 切片):Q/R 两枚等宽等高水墨印章 ──

  /// 单枚印章边长(正方形,两枚同尺寸)。
  static const double skillSealSize = 96;

  /// 两枚印章之间的横向间距。
  static const double skillSealSpacing = 16;

  /// 印章内边距(题字与印边的留白)。
  static const double skillSealPadding = 8;

  /// 印章墨边宽度。
  static const double skillSealBorderWidth = 1.5;

  /// 印章圆角。
  static const double skillSealRadius = 6;

  /// 印章主 glyph(聚/清)字号。
  static const double skillSealGlyphFontSize = 28;

  /// 键位角标(Q/R)字号。
  static const double skillSealKeyFontSize = 12;

  /// 状态行(CD 秒数 / 真气 / 禁用原因)字号。
  static const double skillSealStatusFontSize = 11;
}
