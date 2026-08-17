import '../../domain/phase0a/arena_vector.dart';

/// Phase 0A 表现层 token 集中地:布局 / 阈值 / 池上限唯一定义处。
///
/// 动画/反馈时长同样集中在本文件,表现层不得另写散落常量。
abstract final class Phase0aPresentationTokens {
  /// 世界可活动范围(脚底锚点语义坐标,y 向下为正)。
  static const ArenaVector worldMin = ArenaVector(-640, -260);
  static const ArenaVector worldMax = ArenaVector(640, 260);

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

  /// 命中后角色闪白持续时间。
  static const double hitFlashSeconds = 0.12;

  /// 命中后血条强调持续时间。
  static const double hpEmphasisSeconds = 1.4;

  /// 命中闪白覆盖强度。
  static const double hitFlashOpacity = 0.76;

  /// 血条强调墨边宽度。
  static const double hpEmphasisBorderWidth = 2;

  static const double hpEmphasisFillOpacity = 0.16;
  static const double hpEmphasisGlowOpacity = 0.42;
  static const double hpEmphasisGlowBlur = 8;
  static const double hpEmphasisRadius = 4;

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

  static const double actorWidth = 112;
  static const double actorHeight = 158;
  static const double actorImageHeight = 118;
  static const double actorHpWidth = 104;
  static const double actorHpHeight = 14;
  static const double actorNameFontSize = 13;
  static const double actorLabelGap = 3;
  static const double hudWidth = 310;
  static const double hudInset = 24;
  static const double hudGap = 8;
  static const double hudBarHeight = 18;
  static const double hudPaperOpacity = 0.88;
  static const double hudPadding = 14;
  static const double hudBorderWidth = 1;
  static const double skillHudRight = 28;
  static const double skillHudBottom = 24;
  static const double stageShadeOpacity = 0.22;
  static const double vfxCenterSize = 250;
  static const double vfxMeleeSize = 148;
  static const double vfxEliteDefeatSize = 292;
  static const double gatherPullPadding = 24;
  static const double gatherPullStrokeWidth = 3.5;
  static const double gatherPullEchoStrokeWidth = 2;
  static const double gatherPullCurveBend = 30;
  static const double gatherPullEchoBend = 14;
  static const double gatherPullRibbonStartWidth = 10;
  static const double gatherPullRibbonEndWidth = 2;
  static const double gatherPullTargetDotRadius = 4;
  static const double gatherPullDropletRadius = 3;
  static const double gatherPullSourceSplashRadius = 6;
  static const double vfxStrokeWidth = 4;
  static const double vfxThinStrokeWidth = 2;
  static const double vfxPopupGap = 38;
  static const double vfxPopupFontSize = 32;
  static const double vfxBannerTop = 62;
  static const double vfxBannerWidth = 240;
  static const double vfxBannerHeight = 54;
  static const double vfxOutcomeSize = 168;
  static const double vfxOutcomeFontSize = 30;
  static const double retryButtonTopGap = 28;
  static const double retryButtonPaddingH = 34;
  static const double retryButtonPaddingV = 10;
  static const double retryButtonFontSize = 20;
  static const double depthShadowOpacity = 0.32;
  static const double depthShadowHeight = 18;
  static const double depthShadowWidth = 82;
  static const int vfxSpokeCount = 12;
  static const int maxCatchUpTicksPerFrame = 5;
  static const double feedbackHoldSeconds = 0.65;

  /// debug 动态验收路由单拍冻结后的 VFX 保持时间;不用于正式可玩战斗。
  /// 须大于截图管线 READY 检测轮询 + focus/resize 的固有开销(实测约 5-8s),
  /// 否则截图落在保持窗口外只能拍到过期帧。
  static const double visualRouteFeedbackHoldSeconds = 20;
}
