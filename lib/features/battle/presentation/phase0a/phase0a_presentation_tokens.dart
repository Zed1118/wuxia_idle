import '../../domain/phase0a/arena_vector.dart';

/// Phase 0A 表现层 token 集中地:布局 / 阈值 / 池上限唯一定义处。
///
/// 动画/反馈时长同样集中在本文件,表现层不得另写散落常量。
abstract final class Phase0aPresentationTokens {
  /// 世界可活动范围(脚底锚点语义坐标,y 向下为正)。
  static const ArenaVector worldMin = ArenaVector(-640, -260);
  static const ArenaVector worldMax = ArenaVector(640, 260);

  /// 玩家跟随 camera 的世界跨度占完整 arena 的比例。
  /// 仅影响表现投影，不写回领域位置或战斗结算。
  static const double cameraWorldFraction = 0.75;

  /// Static scene art is oversized and translated against camera motion so
  /// the center-follow band never loses all visible movement references.
  static const double backgroundParallaxScale = 1.3;
  static const double backgroundParallaxFactor = 0.24;

  /// safeRect 相对视口的四向内边距(像素)。
  static const double safeMarginHorizontal = 32;
  static const double safeMarginVertical = 24;

  /// 世界四角映射时距 safeRect 右/下边界的内缩像素,
  /// 保证角点落在 Rect.contains 的半开区间内。
  static const double screenEdgeInset = 1;

  /// 屏外关键威胁提示：最多三方向，内缩后沿视口边缘排布。
  static const int maxOffscreenIndicatorDirections = 3;
  static const int offscreenDirectionSectors = 8;
  static const double offscreenIndicatorEdgeInset = 52;
  static const double offscreenIndicatorLength = 38;
  static const double offscreenIndicatorHalfWidth = 18;
  static const double offscreenIndicatorStrokeWidth = 2.4;
  static const double offscreenIndicatorInnerStrokeWidth = 2;
  static const double offscreenIndicatorNearRatio = 0.65;
  static const double offscreenIndicatorMediumRatio = 1.0;
  static const double offscreenIndicatorNearOpacity = 0.92;
  static const double offscreenIndicatorMediumOpacity = 0.72;
  static const double offscreenIndicatorFarOpacity = 0.54;
  static const double offscreenIndicatorPulseRadiansPerFrame = 0.12;
  static const double offscreenIndicatorPulseOpacity = 0.08;

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

  /// 仅表现层的受击压缩 / 出手前倾；不写回领域坐标。
  static const double actorMotionTweenSeconds = 0.08;

  /// Sword advancing-slash render travel; domain displacement remains atomic.
  static const double basicAttackAdvanceRenderSeconds = 0.18;

  /// 角色脚底在该屏幕像素带内交叉时保持既有绘制顺序，避免近身缠斗抖层。
  static const double actorLayerHysteresisPixels = 10;
  static const double actorStrideSwayPixels = 4;
  static const double actorActionPulseSeconds = 0.16;
  static const double actorHitScale = 0.94;
  static const double actorActionScale = 1.035;
  static const double actorHitSlideFraction = 0.018;
  static const double actorActionSlideFraction = 0.024;
  static const double defenseFeedbackSeconds = 0.72;
  static const double postureUnbalancedTurns = -0.012;
  static const double postureUnbalancedWashOpacity = 0.24;

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

  /// 同屏伤害数字居民池；只裁表现，不裁 controller 事件历史。
  static const int maxResidentDamagePopups = 8;
  static const int maxResidentDamagePopupsPerTarget = 3;

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

  /// 数字技能印略小于 Q/R 战术印，六枚在 1152px 验收视口内保持单行。
  static const double numericSkillSealSize = 78;
  static const double numericSkillSealSpacing = 8;
  static const double numericSkillSealPadding = 4;

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
  static const double skillCastVfxSize = 176;
  static const double skillImpactVfxSize = 208;
  static const double skillUltimateVfxScale = 1.18;
  static const double postureBreakVfxSize = 220;
  static const double postureBarWidth = 104;
  static const double postureBarHeight = 16;
  static const double postureBarBorderWidth = 1.4;
  static const double postureBarLabelFontSize = 10.5;
  static const double postureBarTrackOpacity = 0.84;
  static const double postureBarFillOpacity = 0.72;
  static const double palmTrailPadding = 20;
  static const double palmTrailHeight = 84;
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
  static const double vfxPopupLift = 42;
  static const double vfxPopupFontSize = 32;
  static const double damagePopupSeconds = 0.42;
  static const double meleeVfxSeconds = 0.18;
  static const double palmTrailSeconds = 0.24;
  static const double skillCastVfxSeconds = 0.34;
  static const double skillImpactVfxSeconds = 0.42;
  static const double gatherVfxSeconds = 0.36;
  static const double clearVfxSeconds = 0.30;
  static const double defeatVfxSeconds = 0.45;

  /// 普攻/击杀/清场 painter 的固定墨滴绘制上限。
  static const int vfxInkSplatCount = 6;
  static const int vfxResidualStrokeCount = 2;
  static const int vfxNormalDefeatSplatCount = 12;
  static const int vfxEliteDefeatSplatCount = 24;
  static const double vfxInkSplatRadius = 3.5;
  static const double vfxInkSplatTravelFraction = 0.22;
  static const double vfxInkWashMaxOpacity = 0.18;
  static const double vfxResidualStrokeOpacity = 0.34;
  static const double vfxBannerTop = 62;
  static const double vfxBannerWidth = 240;
  static const double vfxBannerHeight = 54;
  static const double vfxOutcomeSize = 168;
  static const double vfxOutcomeFontSize = 30;
  static const double bossStatusFontSize = 12;
  static const double bossStatusPaddingH = 8;
  static const double bossStatusPaddingV = 3;
  static const double bossStatusGap = 4;
  static const double bossStatusBorderWidth = 1.4;
  static const double bossStatusRadius = 3;
  static const double bossChargeFeedbackSeconds = 1.1;
  static const double bossInterruptFeedbackSeconds = 0.9;
  static const double postureBreakFeedbackSeconds = 0.9;
  static const double guardMechanicFeedbackSeconds = 1.0;
  static const double bossMechanicBannerTopGap = 12;
  static const double guardianWardRingStrokeWidth = 2.4;
  static const double guardianWardRingInset = 8;

  /// 护法贴近 Boss 时，姓名/血条左右错列的屏幕像素间距。
  static const double guardianLabelLaneOffset = 112;

  /// Boss 视觉验收路由在破招前保留蓄力态，供截图与人工观察。
  static const double bossFixtureChargeHoldSeconds = 8;
  static const double bossFixtureGuardedHoldSeconds = 8;

  /// 键盘焦点金边环宽(PlaqueButton 同体例:桌面键盘导航可见落点)。
  static const double focusRingWidth = 2;
  static const double retryButtonTopGap = 28;
  static const double retryButtonPaddingH = 34;
  static const double retryButtonPaddingV = 10;
  static const double retryButtonFontSize = 20;
  static const double depthShadowOpacity = 0.32;
  static const double depthShadowHeight = 18;
  static const double depthShadowWidth = 82;
  static const double groundMarkWidth = 94;
  static const double groundMarkEliteWidth = 104;
  static const double groundMarkHeight = 22;
  static const double groundMarkFillOpacity = 0.10;
  static const double groundMarkBorderOpacity = 0.58;
  static const double groundMarkBorderWidth = 1.3;
  static const double enemyLabelIdleFillOpacity = 0.40;
  static const double enemyLabelIdleBorderOpacity = 0.38;
  static const int vfxSpokeCount = 12;
  static const int maxCatchUpTicksPerFrame = 5;
  static const double feedbackHoldSeconds = 0.65;

  /// debug 动态验收路由单拍冻结后的 VFX 保持时间;不用于正式可玩战斗。
  /// 须大于截图管线 READY 检测轮询 + focus/resize 的固有开销(实测约 5-8s),
  /// 否则截图落在保持窗口外只能拍到过期帧。
  static const double visualRouteFeedbackHoldSeconds = 20;

  /// Painter 的帧参数集中计算，便于行为测试直接观察 0/中间/末段差异。
  static double vfxReveal(double progress) => progress.clamp(0.0, 1.0);

  static double vfxFade(double progress) => (1.0 - progress).clamp(0.0, 1.0);

  /// 主笔锋、清场辐射线与精英环的统一淡出 alpha。
  /// 几何 reveal 仍由 painter 单独控制，避免末帧突然消失。
  static double vfxStrokeAlpha(double progress) =>
      (1.0 - progress).clamp(0.0, 1.0);
}
