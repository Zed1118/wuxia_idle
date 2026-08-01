import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/battle_state.dart';
import '../domain/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import 'avatar_status_tags.dart';
import 'battle_charge_seal.dart';
import 'battle_layout_tokens.dart';
import 'battle_stage_geometry.dart';
import 'battle_standee_fusion.dart';
import 'battle_typography_tokens.dart';
import 'guardian_ward_presentation.dart';
import 'hp_bar.dart';
import '../../../shared/widgets/asset_fallback.dart';
import '../../../shared/widgets/wuxia_image.dart';

enum CharacterDisplayMode { avatar, stageStandee }

/// 战斗人物素材在生产链路中的明确角色。
///
/// [sourcePortrait] 只允许用于头像/档案来源，不能直接铺到战场；
/// [stageStandee] 是透明全身图；缺专用站姿时使用 [identitySilhouette]，
/// 以保留身份而不把带背景肖像伪装成全身立绘。
enum BattleCharacterAssetRole {
  sourcePortrait,
  stageStandee,
  identitySilhouette,
}

@immutable
class BattleStandeeAssetResolution {
  const BattleStandeeAssetResolution({
    required this.sourcePath,
    required this.sourceRole,
    required this.displayPath,
    required this.displayRole,
  });

  final String? sourcePath;
  final BattleCharacterAssetRole? sourceRole;
  final String? displayPath;
  final BattleCharacterAssetRole displayRole;

  bool get usesPortraitAsStandee =>
      displayRole == BattleCharacterAssetRole.sourcePortrait;
}

const battleStandeeGroundingOpacity = 0.22;
const battleStandeeGroundingCoreOpacity = 0.36;
const battleStandeeGroundingWashOpacity = 0.16;

/// 战斗角色头像（phase1_tasks.md T14 §784;M4 Stage 3 2026-05-21 美术接入)。
///
/// 主入口:[BattleCharacter.iconPath] 非空且非空串时,走 [Image.asset] + ClipOval
/// (圆形遮罩 + 流派色 4px 边框)。无图或 errorBuilder 触发时降级到
/// [_FirstGlyphAvatar](首字 + 流派色边框 CircleAvatar)。
///
/// **widget test 不加载 pubspec assets**(memory feedback_image_asset_error_builder),
/// 所有 Image.asset 必须挂 errorBuilder 守 1172 test 不破。
///
/// `character.isAlive == false` 时整体 opacity 0.45 + grayscale ColorFilter（§794 死亡变灰验收 · P0-2 放大后灰化更明显）。
class CharacterAvatar extends StatelessWidget {
  final BattleCharacter character;
  final double avatarSize;
  final double barWidth;
  final CharacterDisplayMode displayMode;
  final double standeeWidth;
  final double standeeHeight;
  final bool inkMirror;
  final bool showStageStatusOverlay;

  /// Boss/敌人蓄力满值（`numbers.combat.bossCharge.defaultChargeTicks`）。
  /// 保留在公开构造器上兼容战场调用链；新的蓄势小印只显示剩余拍数。
  final int chargeMaxTicks;

  /// 读秒环节拍（本拍内 0→1，供蓄力/破绽环平滑插值）。
  /// null（测试/静态路径）时回落 [AlwaysStoppedAnimation]（0）冻结显整数。
  final Animation<double>? beat;

  /// 破绽窗口时长（破绽读秒环分母，`numbers.combat.defenseBreak.windowTicks`）。
  final int staggerWindowTicks;

  /// floor30 护法结界(Task 6):完整战场快照,供判定 [character] 是否处于
  /// 护法结界庇护中(需查同队护法存活状态,单个 character 字段不足以判定)。
  /// null(测试/无结界场景)→ 跳过判定,不展示结界标签(零回归)。
  final BattleState? battleState;

  /// 立绘大气融合档(B3 方案 B):由所在场景背景的合成明度决定强度。
  /// 缺省 [BattleStandeeFusion.baseline] = 自适应前的既有观感,保证未接线的
  /// 调用点(debug route / widget 测)零回归。
  final BattleStandeeFusion standeeFusion;

  const CharacterAvatar({
    super.key,
    required this.character,
    this.avatarSize = 110,
    this.barWidth = 160,
    this.displayMode = CharacterDisplayMode.avatar,
    this.standeeWidth = 160,
    this.standeeHeight = 230,
    this.inkMirror = false,
    this.showStageStatusOverlay = true,
    this.chargeMaxTicks = 3,
    this.beat,
    this.staggerWindowTicks = 3,
    this.battleState,
    this.standeeFusion = BattleStandeeFusion.baseline,
  });

  @override
  Widget build(BuildContext context) {
    if (displayMode == CharacterDisplayMode.stageStandee) {
      return _StageCharacterStandee(
        character: character,
        battleState: battleState,
        beat: beat ?? const AlwaysStoppedAnimation<double>(0),
        staggerWindowTicks: staggerWindowTicks,
        width: standeeWidth,
        height: standeeHeight,
        inkMirror: inkMirror,
        showStatusOverlay: showStageStatusOverlay,
        fusion: standeeFusion,
      );
    }

    final color = WuxiaColors.schoolColor(character.school);
    final borderColor = character.isBoss ? WuxiaColors.bossFrame : color;
    final borderWidth = character.isBoss ? 6.0 : 4.0;
    final firstGlyph = character.name.characters.isEmpty
        ? '?'
        : character.name.characters.first;
    final hasIcon =
        character.iconPath != null && character.iconPath!.isNotEmpty;

    final Widget avatarCore = hasIcon
        ? Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: borderWidth),
              color: WuxiaColors.avatarFill,
            ),
            child: ClipOval(
              child: WuxiaImage(
                character.iconPath!,
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
                errorBuilder: wuxiaAssetErrorBuilder(
                  () => _FirstGlyphAvatar(
                    avatarSize: avatarSize,
                    color: borderColor,
                    borderWidth: borderWidth,
                    firstGlyph: firstGlyph,
                  ),
                ),
              ),
            ),
          )
        : _FirstGlyphAvatar(
            avatarSize: avatarSize,
            color: borderColor,
            borderWidth: borderWidth,
            firstGlyph: firstGlyph,
          );
    final avatar = character.isBoss
        ? _BossAvatarFrame(avatarSize: avatarSize, child: avatarCore)
        : avatarCore;

    // 读秒环节拍：null 路径回落 AlwaysStoppedAnimation(0) → 环冻结显整数。
    final effBeat = beat ?? const AlwaysStoppedAnimation<double>(0.0);
    // floor30 护法结界(Task 6):battleState 未传(测试/无结界场景) → false。
    final wardActive =
        battleState != null && isGuardianWardActive(character, battleState!);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        avatar,
        // 固定状态行高度，避免同队头像因内伤/破绽环显隐产生独立缩放。
        SizedBox(
          width: barWidth,
          height: 38,
          child: Center(
            child: AvatarStatusTags(
              character: character,
              beat: effBeat,
              staggerWindowTicks: staggerWindowTicks,
              wardActive: wardActive,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          character.name,
          style: const TextStyle(
            fontSize: 14,
            color: WuxiaColors.textPrimary,
            fontWeight: FontWeight.w600,
            // 角色名浮在水墨战景上，加描影兜底浅雾区对比(scrim)。
            shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
          ),
        ),
        Text(
          EnumL10n.realm(character.realmTier, character.realmLayer),
          style: const TextStyle(
            fontSize: 11,
            color: WuxiaColors.textSecondary,
            // 境界副标浅灰压浅雾景低对比，加描影提可读。
            shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: barWidth,
          child: HpBar(
            current: character.currentHp,
            max: character.maxHp,
            height: 14,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: barWidth,
          child: HpBar(
            current: character.currentQi,
            max: character.maxQi,
            height: 12,
            isInternalForce: true,
            labelPrefix: UiStrings.internalForceShortLabel,
          ),
        ),
        // 固定蓄势印行高度，避免蓄势态单槽挤压相邻头像。
        const SizedBox(height: 4),
        SizedBox(
          width: barWidth,
          height: 34,
          child: Center(
            child: character.chargingSkill == null
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BattleChargeSeal(character: character, size: 24),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.flash_on,
                        size: 14,
                        color: WuxiaColors.lingQiao,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );

    final dimmed = Opacity(
      opacity: character.isAlive ? 1.0 : 0.45,
      child: content,
    );
    if (character.isAlive) return dimmed;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: dimmed,
    );
  }
}

/// 战场全人物站姿。透明战斗立绘保持完整头脚；未登记的档案肖像只会降级为
/// 无背景身份墨影，不会再把矩形/半身原画铺进战场人物位。
class _StageCharacterStandee extends StatelessWidget {
  const _StageCharacterStandee({
    required this.character,
    required this.battleState,
    required this.beat,
    required this.staggerWindowTicks,
    required this.width,
    required this.height,
    required this.inkMirror,
    required this.showStatusOverlay,
    required this.fusion,
  });

  final BattleCharacter character;
  final BattleState? battleState;
  final Animation<double> beat;
  final int staggerWindowTicks;
  final double width;
  final double height;
  final bool inkMirror;
  final bool showStatusOverlay;
  final BattleStandeeFusion fusion;

  @override
  Widget build(BuildContext context) {
    final schoolColor = WuxiaColors.schoolColor(character.school);
    final borderColor = character.isBoss ? WuxiaColors.bossFrame : schoolColor;
    final portraitHeight = height * 0.91;
    final firstGlyph = character.name.characters.isEmpty
        ? '?'
        : character.name.characters.first;
    final asset = resolveBattleStandeeAsset(
      sourcePath: character.iconPath,
      teamSide: character.teamSide,
      slotIndex: character.slotIndex,
    );
    final resolvedIconPath = asset.displayPath;
    final sourceFootFraction = battleStandeeFootFraction(resolvedIconPath);
    final footY = portraitHeight * _stageStandeeAnchorFootFraction;
    final groundingHeight = height * 0.055;
    final wardActive =
        battleState != null && isGuardianWardActive(character, battleState!);

    final Widget image;
    if (asset.displayRole == BattleCharacterAssetRole.stageStandee &&
        resolvedIconPath != null) {
      image = WuxiaImage(
        resolvedIconPath,
        width: width,
        height: portraitHeight,
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
        errorBuilder: wuxiaAssetErrorBuilder(
          () => _FirstGlyphStandee(
            width: width,
            height: portraitHeight,
            color: borderColor,
            firstGlyph: firstGlyph,
          ),
        ),
      );
    } else if (asset.displayRole ==
            BattleCharacterAssetRole.identitySilhouette &&
        resolvedIconPath != null) {
      image = _InkIdentityStandee(
        shapePath: resolvedIconPath,
        width: width,
        height: portraitHeight,
        accent: borderColor,
        firstGlyph: firstGlyph,
      );
    } else {
      image = _FirstGlyphStandee(
        width: width,
        height: portraitHeight,
        color: borderColor,
        firstGlyph: firstGlyph,
      );
    }

    Widget portraitImage = image;
    portraitImage = ImageFiltered(
      key: const ValueKey('battle.stageStandeeEdgeSoftening'),
      imageFilter: ui.ImageFilter.blur(
        sigmaX: battleStandeeEdgeSofteningSigma,
        sigmaY: battleStandeeEdgeSofteningSigma,
        tileMode: ui.TileMode.decal,
      ),
      child: ColorFiltered(
        key: const ValueKey('battle.stageStandeeFusionGrade'),
        colorFilter: ColorFilter.matrix(fusion.matrix),
        child: Opacity(
          key: const ValueKey('battle.stageStandeeFusionOpacity'),
          opacity: fusion.opacity,
          child: portraitImage,
        ),
      ),
    );
    if (inkMirror) {
      portraitImage = ColorFiltered(
        key: const ValueKey('battle.innerDemonInkMirror'),
        colorFilter: const ColorFilter.matrix(<double>[
          0.42,
          0.36,
          0.22,
          0,
          8,
          0.22,
          0.34,
          0.24,
          0,
          0,
          0.36,
          0.28,
          0.48,
          0,
          18,
          0,
          0,
          0,
          0.92,
          0,
        ]),
        child: portraitImage,
      );
    }

    // 立绘生成时的透明画布留白不一致。绕实际脚底缩放，使成对角色的
    // 有效人物高度接近；水平修正 alpha 重心，垂直将脚底对齐公共基准线。
    final opticalProfile = _stageStandeeOpticalProfile(resolvedIconPath);
    final sampleAspect = _stageStandeeSampleAspect(resolvedIconPath);
    portraitImage = Transform.translate(
      key: const ValueKey('battle.stageStandeeOpticalShift'),
      offset: Offset(
        width * opticalProfile.horizontalShiftFraction,
        portraitHeight * (_stageStandeeAnchorFootFraction - sourceFootFraction),
      ),
      child: Transform.scale(
        key: const ValueKey('battle.stageStandeeOpticalScale'),
        scale: opticalProfile.scale,
        alignment: Alignment(0, sourceFootFraction * 2 - 1),
        child: Transform(
          key: const ValueKey('battle.stageStandeeSampleAspect'),
          alignment: Alignment(0, sourceFootFraction * 2 - 1),
          transform: Matrix4.diagonal3Values(
            sampleAspect.horizontalScale,
            sampleAspect.verticalScale,
            1,
          ),
          child: portraitImage,
        ),
      ),
    );

    Widget portrait = Container(
      width: width,
      height: portraitHeight,
      decoration: BoxDecoration(
        boxShadow: inkMirror
            ? [
                BoxShadow(
                  color: WuxiaColors.yinRou.withValues(alpha: 0.28),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: portraitImage,
    );
    if (character.isBoss) {
      // Boss 的旧金色 BoxShadow 画在矩形 Container 外轮廓上，会在浅色水墨
      // 场景里形成明显黄底方块。Boss 已由放大尺度、Boss HUD 金框与战场墨云
      // 建立层级，此处只保留稳定验收 key，不再给透明立绘垫矩形光晕。
      portrait = KeyedSubtree(
        key: const ValueKey<String>('battle.bossAvatarFrame'),
        child: portrait,
      );
    }

    final content = SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            key: const ValueKey('battle.stageStandeeGrounding'),
            left: width * 0.22,
            right: width * 0.22,
            top: (footY - groundingHeight * 0.50).clamp(
              0.0,
              height - groundingHeight,
            ),
            height: groundingHeight,
            child: const IgnorePointer(
              child: CustomPaint(painter: _StandeeGroundingPainter()),
            ),
          ),
          if (character.isBoss &&
              resolvedIconPath != WuxiaUi.battleSampleHiddenElderStandee)
            Positioned(
              left: width * 0.03,
              right: width * 0.03,
              top: height * 0.04,
              bottom: height * 0.10,
              child: const IgnorePointer(
                child: CustomPaint(
                  key: ValueKey('battle.stageBossInkAura'),
                  painter: _BossInkAuraPainter(),
                ),
              ),
            ),
          portrait,
          Positioned(
            top: 4,
            left: 4,
            right: 4,
            child: Center(
              child: AvatarStatusTags(
                character: character,
                beat: beat,
                staggerWindowTicks: staggerWindowTicks,
                wardActive: wardActive,
              ),
            ),
          ),
          if (showStatusOverlay)
            StageCharacterStatusOverlay(
              character: character,
              battleState: battleState,
              width: width,
              height: height,
            ),
        ],
      ),
    );

    if (character.isAlive) return content;
    return Transform.translate(
      key: const ValueKey('battle.stageStandeeDefeatedSink'),
      offset: Offset(0, height * 0.018),
      child: ColorFiltered(
        colorFilter: _grayscaleFilter,
        child: Opacity(
          key: const ValueKey('battle.stageStandeeDefeatedFade'),
          opacity: 0.45,
          child: content,
        ),
      ),
    );
  }
}

/// 全人物舞台的名字与双状态条。战场主路径会把它从人物槽中拆出，
/// 在所有按景深排序的立绘绘制完成后统一叠加，避免前景人物遮挡邻位血条。
class StageCharacterStatusOverlay extends StatelessWidget {
  const StageCharacterStatusOverlay({
    super.key,
    required this.character,
    required this.battleState,
    required this.width,
    required this.height,
    this.teamSize = 1,
  });

  final BattleCharacter character;
  final BattleState? battleState;
  final double width;
  final double height;
  final int teamSize;

  @override
  Widget build(BuildContext context) {
    final insetFraction = switch ((character.isBoss, character.slotIndex)) {
      (true, _) => 0.32,
      (false, 0) => 0.25,
      (false, 2) => 0.19,
      _ => 0.22,
    };
    return Positioned(
      left: width * insetFraction,
      right: width * insetFraction,
      top:
          (height *
                  battleStageStatusVerticalFraction(
                    character.teamSide,
                    character.slotIndex,
                    teamSize,
                  ))
              .clamp(0.0, height - 34),
      child: Opacity(
        opacity: character.isAlive ? 1 : 0.45,
        child: Container(
          key: const ValueKey('battle.stageStatusInkRubbing'),
          padding: const EdgeInsets.fromLTRB(4, 1, 4, 2),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: ValueKey('battle.stageStatusInkWash'),
                    painter: _StageStatusInkWashPainter(),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          character.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: WuxiaUi.paper,
                            fontSize: BattleTypography.t4,
                            fontWeight: FontWeight.w600,
                            height: 1,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 1),
                            ],
                          ),
                        ),
                      ),
                      if (character.isBoss && character.teamSide == 1) ...[
                        const SizedBox(width: 3),
                        Container(
                          key: const ValueKey('battle.stageBossMomentumSeal'),
                          width: 14,
                          height: 14,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: WuxiaUi.jiang,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            UiStrings.battleMomentumSeal,
                            style: TextStyle(
                              color: WuxiaUi.paper,
                              fontFamily: BattleTypography.displayFamily,
                              fontFamilyFallback:
                                  BattleTypography.displayFallback,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                      if (character.chargingSkill != null) ...[
                        const SizedBox(width: 3),
                        BattleChargeSeal(character: character),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  HpBar(
                    current: character.currentHp,
                    max: character.maxHp,
                    height: BattleLayoutTokens.stageStatusHpHeight,
                    fillColorOverride: WuxiaUi.jiang,
                    trackColorOverride: WuxiaUi.battleStatusTrack,
                    labelFontSize: 10,
                    tightLabel: true,
                  ),
                  const SizedBox(height: 1),
                  HpBar(
                    current: character.currentQi,
                    max: character.maxQi,
                    height: BattleLayoutTokens.stageStatusQiHeight,
                    isInternalForce: true,
                    fillColorOverride: WuxiaUi.qing,
                    trackColorOverride: WuxiaUi.battleStatusTrack,
                    labelFontSize: 10,
                    tightLabel: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Boss 背后的金墨气韵。只画细线与局部雾化弧，不铺矩形光晕；
/// 既承接样板中隐世老者的游丝金气，也避免浅色战景出现一整块黄色底板。
class _BossInkAuraPainter extends CustomPainter {
  const _BossInkAuraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = WuxiaUi.gold.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.12,
        size.width * 0.76,
        size.height * 0.76,
      ),
      -2.55,
      4.75,
      false,
      glow,
    );

    final strand = Paint()
      ..color = const Color(0xFFC5A86B).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.45);
    final faintStrand = Paint()
      ..color = const Color(0xFFD2BA84).withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    void drawStrand({
      required Offset start,
      required Offset control1,
      required Offset control2,
      required Offset end,
      bool faint = false,
    }) {
      final path = Path()
        ..moveTo(start.dx * size.width, start.dy * size.height)
        ..cubicTo(
          control1.dx * size.width,
          control1.dy * size.height,
          control2.dx * size.width,
          control2.dy * size.height,
          end.dx * size.width,
          end.dy * size.height,
        );
      canvas.drawPath(path, faint ? faintStrand : strand);
    }

    drawStrand(
      start: const Offset(0.44, 0.82),
      control1: const Offset(0.03, 0.65),
      control2: const Offset(0.10, 0.29),
      end: const Offset(0.30, 0.17),
    );
    drawStrand(
      start: const Offset(0.42, 0.75),
      control1: const Offset(0.12, 0.55),
      control2: const Offset(0.30, 0.15),
      end: const Offset(0.46, 0.08),
      faint: true,
    );
    drawStrand(
      start: const Offset(0.53, 0.80),
      control1: const Offset(0.88, 0.64),
      control2: const Offset(0.91, 0.28),
      end: const Offset(0.69, 0.15),
    );
    drawStrand(
      start: const Offset(0.58, 0.72),
      control1: const Offset(0.94, 0.52),
      control2: const Offset(0.75, 0.21),
      end: const Offset(0.60, 0.10),
      faint: true,
    );
    drawStrand(
      start: const Offset(0.30, 0.65),
      control1: const Offset(0.05, 0.48),
      control2: const Offset(0.14, 0.21),
      end: const Offset(0.38, 0.30),
      faint: true,
    );
    drawStrand(
      start: const Offset(0.69, 0.63),
      control1: const Offset(0.94, 0.43),
      control2: const Offset(0.81, 0.18),
      end: const Offset(0.58, 0.27),
      faint: true,
    );
  }

  @override
  bool shouldRepaint(covariant _BossInkAuraPainter oldDelegate) => false;
}

/// 人物脚下状态条的柔和墨染。透明渐隐与断续墨毫替代矩形实底和硬边，
/// 数值条仍保持原宽度与对比，不改变人物站位或点击区域。
class _StageStatusInkWashPainter extends CustomPainter {
  const _StageStatusInkWashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x00221E19),
            Color(0x6B2C2721),
            Color(0x75221E19),
            Color(0x00221E19),
          ],
          stops: [0, 0.13, 0.86, 1],
        ).createShader(bounds),
    );

    final wash = Paint()
      ..color = const Color(0xFF191612).withValues(alpha: 0.16)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6);
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.16 + i * 0.18);
      canvas.drawLine(
        Offset(size.width * (0.08 + (i % 2) * 0.05), y),
        Offset(size.width * (0.90 - (i % 3) * 0.04), y + (i.isEven ? 1 : -1)),
        wash..strokeWidth = 2.8 + (i % 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StageStatusInkWashPainter oldDelegate) => false;
}

/// 透明立绘的接触影与脚底墨晕。影子贴在人物层内，会跟随冲锋、
/// 受击和缩放一起移动，不改战场点击区与角色实际站位。
class _StandeeGroundingPainter extends CustomPainter {
  const _StandeeGroundingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.56);
    final contact = Paint()
      ..color = const Color(
        0xFF2B251E,
      ).withValues(alpha: battleStandeeGroundingOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.2);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.78,
        height: size.height * 0.42,
      ),
      contact,
    );

    final contactCore = Paint()
      ..color = const Color(
        0xFF241F1A,
      ).withValues(alpha: battleStandeeGroundingCoreOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.54),
        width: size.width * 0.44,
        height: size.height * 0.18,
      ),
      contactCore,
    );

    final wash = Paint()
      ..color = const Color(
        0xFF4A4034,
      ).withValues(alpha: battleStandeeGroundingWashOpacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.1);
    final leftWash = Path()
      ..moveTo(size.width * 0.08, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.36,
        size.width * 0.53,
        size.height * 0.67,
      );
    final rightWash = Path()
      ..moveTo(size.width * 0.42, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.42,
        size.width * 0.94,
        size.height * 0.70,
      );
    canvas.drawPath(leftWash, wash);
    canvas.drawPath(rightWash, wash..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant _StandeeGroundingPainter oldDelegate) => false;
}

/// 将头像来源解析为战场专用显示素材。未登记的 portrait 永远不直接显示，
/// 而是进入透明身份剪影；由此正式战斗不会再出现方形/半身照片式人物。
BattleStandeeAssetResolution resolveBattleStandeeAsset({
  required String? sourcePath,
  required int teamSide,
  required int slotIndex,
}) {
  final normalizedSource = sourcePath == null || sourcePath.isEmpty
      ? null
      : sourcePath;
  if (normalizedSource != null) {
    final registeredStandee = _battleStandeeOverrides[normalizedSource];
    if (registeredStandee != null) {
      final isIdentityStandee = registeredStandee == normalizedSource;
      return BattleStandeeAssetResolution(
        sourcePath: normalizedSource,
        sourceRole: isIdentityStandee
            ? BattleCharacterAssetRole.stageStandee
            : BattleCharacterAssetRole.sourcePortrait,
        displayPath: registeredStandee,
        displayRole: BattleCharacterAssetRole.stageStandee,
      );
    }
    if (_hasBattleStandeePathConvention(normalizedSource)) {
      return BattleStandeeAssetResolution(
        sourcePath: normalizedSource,
        sourceRole: BattleCharacterAssetRole.stageStandee,
        displayPath: normalizedSource,
        displayRole: BattleCharacterAssetRole.stageStandee,
      );
    }
    return BattleStandeeAssetResolution(
      sourcePath: normalizedSource,
      sourceRole: BattleCharacterAssetRole.sourcePortrait,
      displayPath: _playerFallbackStandee(teamSide, slotIndex),
      displayRole: BattleCharacterAssetRole.identitySilhouette,
    );
  }
  final playerFallback = _playerFallbackStandee(teamSide, slotIndex);
  return BattleStandeeAssetResolution(
    sourcePath: null,
    sourceRole: null,
    displayPath: playerFallback,
    displayRole: playerFallback == null
        ? BattleCharacterAssetRole.identitySilhouette
        : BattleCharacterAssetRole.stageStandee,
  );
}

String? _playerFallbackStandee(int teamSide, int slotIndex) {
  if (teamSide != 0 || slotIndex < 0) return null;
  return switch (slotIndex % 3) {
    0 => WuxiaUi.battleFounderFallback,
    1 => WuxiaUi.battleFirstDiscipleFallback,
    2 => WuxiaUi.battleSecondDiscipleFallback,
    _ => null,
  };
}

bool _hasBattleStandeePathConvention(String path) =>
    path.startsWith('assets/characters/battle_') ||
    path.startsWith('assets/enemies/battle_');

/// 资产门禁读取的已登记 source/output，不允许调用方修改内部注册表。
Set<String> get registeredBattleStandeeSourcePaths =>
    Set<String>.unmodifiable(_battleStandeeOverrides.keys);

Set<String> get registeredBattleStandeeDisplayPaths =>
    Set<String>.unmodifiable({
      WuxiaUi.battleFounderFallback,
      WuxiaUi.battleFirstDiscipleFallback,
      WuxiaUi.battleSecondDiscipleFallback,
      ..._battleStandeeOverrides.values,
    });

const _battleStandeeOverrides = <String, String>{
  'assets/characters/founder.png': WuxiaUi.battleFounderFallback,
  'assets/characters/first_disciple.png': WuxiaUi.battleFirstDiscipleFallback,
  'assets/characters/second_disciple.png': WuxiaUi.battleSecondDiscipleFallback,
  'assets/enemies/thug_a.png': WuxiaUi.battleThugStandee,
  'assets/enemies/thug_b.png': WuxiaUi.battleYoungRuffianStandee,
  'assets/enemies/thug_c.png': WuxiaUi.battleGauntCutpurseStandee,
  'assets/enemies/ruffian_a.png': WuxiaUi.battleVillageRuffianStandee,
  'assets/enemies/bandit_b.png': WuxiaUi.battleLowRankSaberFighterStandee,
  'assets/enemies/bandit_c.png': WuxiaUi.battleBlackWindUnderlingStandee,
  'assets/enemies/bandit_head.png': WuxiaUi.battleBanditHeadStandee,
  'assets/enemies/qingshan.png': WuxiaUi.battleQingshanStandee,
  'assets/enemies/qingshan_main.png': WuxiaUi.battleHiddenElderStandee,
  'assets/enemies/elder_grey.png': WuxiaUi.battleGreyElderStandee,
  'assets/enemies/shaonian.png': WuxiaUi.battleSpringHallYouthStandee,
  'assets/enemies/guntou.png': WuxiaUi.battleBaldStaffFighterStandee,
  'assets/enemies/guntou_zhu.png': WuxiaUi.battleArenaChampionStandee,
  'assets/enemies/seng_huiyi.png': WuxiaUi.battleGreyMonkStandee,
  'assets/enemies/balian.png': WuxiaUi.battleScarredBossStandee,
  'assets/enemies/huiyi.png': WuxiaUi.battleGreySwordsmanStandee,
  'assets/enemies/lightfoot_shuikou_a.png': WuxiaUi.battleFerryBanditStandee,
  'assets/enemies/lightfoot_shuikou_b.png': WuxiaUi.battleFerryBoatmanStandee,
  'assets/enemies/lightfoot_shuikou_c.png': WuxiaUi.battleFerrySaberStandee,
  'assets/enemies/lightfoot_yexun_a.png': WuxiaUi.battleNightPatrolStandee,
  'assets/enemies/lightfoot_yexun_b.png': WuxiaUi.battleRooftopConstableStandee,
  'assets/enemies/lightfoot_yexun_c.png': WuxiaUi.battleRooftopAssassinStandee,
  'assets/enemies/lightfoot_zhuke_a.png':
      WuxiaUi.battleJiangnanSwordsmanStandee,
  'assets/enemies/lightfoot_zhuke_b.png': WuxiaUi.battleBambooSaberStandee,
  'assets/enemies/lightfoot_zhuke_c.png': WuxiaUi.battleBambooWandererStandee,
  'assets/enemies/lightfoot_pubu_a.png':
      WuxiaUi.battleMountainStreamSwordStandee,
  'assets/enemies/lightfoot_pubu_b.png': WuxiaUi.battleWaterfallSaberStandee,
  'assets/enemies/lightfoot_pubu_c.png': WuxiaUi.battleCliffWandererStandee,
  'assets/enemies/lightfoot_changfeng_a.png':
      WuxiaUi.battleGateCommanderStandee,
  'assets/enemies/lightfoot_changfeng_b.png':
      WuxiaUi.battleLongWindSwordStandee,
  'assets/enemies/lightfoot_changfeng_c.png':
      WuxiaUi.battleLongRoadSaberStandee,
  'assets/enemies/massbattle_cunfei_a.png':
      WuxiaUi.battleVillageBanditLeaderStandee,
  'assets/enemies/massbattle_cunfei_b.png':
      WuxiaUi.battleVillageBanditArcherStandee,
  'assets/enemies/massbattle_cunfei_c.png':
      WuxiaUi.battleVillageBanditSaberStandee,
  'assets/enemies/massbattle_zhenkou_a.png':
      WuxiaUi.battleTownBanditLeaderStandee,
  'assets/enemies/massbattle_zhenkou_b.png':
      WuxiaUi.battleTownBanditWandererStandee,
  'assets/enemies/massbattle_zhenkou_c.png':
      WuxiaUi.battleTownBanditAssassinStandee,
  'assets/enemies/massbattle_xianjie_a.png':
      WuxiaUi.battleRivalSectMasterStandee,
  'assets/enemies/massbattle_xianjie_b.png':
      WuxiaUi.battleRivalSectProtectorStandee,
  'assets/enemies/massbattle_xianjie_c.png':
      WuxiaUi.battleRivalSectDiscipleStandee,
  'assets/enemies/massbattle_guanqi_a.png':
      WuxiaUi.battleFrontierCommanderStandee,
  'assets/enemies/massbattle_guanqi_b.png':
      WuxiaUi.battleFrontierOutriderStandee,
  'assets/enemies/massbattle_guanqi_c.png':
      WuxiaUi.battleFrontierIronGuardStandee,
  'assets/enemies/massbattle_canbu_a.png':
      WuxiaUi.battleWesternRemnantGeneralStandee,
  'assets/enemies/massbattle_canbu_b.png':
      WuxiaUi.battleWesternFrenziedRiderStandee,
  'assets/enemies/massbattle_canbu_c.png':
      WuxiaUi.battleWesternRemnantAssassinStandee,
  'assets/enemies/black_killer.png': WuxiaUi.battleBlackKillerStandee,
  'assets/enemies/killer_a.png': WuxiaUi.battleBanditBladeStandee,
  'assets/enemies/killer_b.png': WuxiaUi.battleBanditArcherStandee,
  'assets/enemies/umbrella.png': WuxiaUi.battleUmbrellaStandee,
  'assets/enemies/tower_boss_05.png': WuxiaUi.battleSwordStoneElderStandee,
  'assets/enemies/tower_boss_10.png': WuxiaUi.battleBlackWindChiefStandee,
  'assets/enemies/tower_boss_15.png': WuxiaUi.battleNightPavilionMasterStandee,
  'assets/enemies/tower_boss_20.png': WuxiaUi.battleTowerBoss20Standee,
  'assets/enemies/tower_boss_25.png': WuxiaUi.battleSummitSwordDemonStandee,
  'assets/enemies/zuo_hufa.png': WuxiaUi.battleLeftGuardianStandee,
  'assets/enemies/you_hufa.png': WuxiaUi.battleRightGuardianStandee,
  'assets/enemies/tower_boss_30.png': WuxiaUi.battleTowerBoss30Standee,
  'assets/enemies/jianghu_qianbei.png': WuxiaUi.battleJianghuSeniorStandee,
  'assets/enemies/jianghu_a.png': WuxiaUi.battleWanderingPalmFighterStandee,
  'assets/enemies/jianghu_b.png': WuxiaUi.battleIndependentWandererStandee,
  'assets/enemies/wulin_bazhu.png': WuxiaUi.battleWulinOverlordStandee,
  'assets/enemies/mingmen_a.png': WuxiaUi.battleEstablishedSectDiscipleStandee,
  'assets/enemies/liukou_a.png': WuxiaUi.battleRaiderLeaderStandee,
  'assets/enemies/guard_a.png': WuxiaUi.battleYumenGarrisonOfficerStandee,
  'assets/enemies/shafei_a.png': WuxiaUi.battleDesertBanditLeaderStandee,
  'assets/enemies/xiliangboss.png': WuxiaUi.battleWesternMartialSeniorStandee,
  'assets/enemies/xiliangbazhu.png': WuxiaUi.battleWesternOverlordStandee,
  'assets/enemies/tongguan_shoujiang.png':
      WuxiaUi.battleTongguanDefenderStandee,
  'assets/enemies/songshan_daozong_dizi.png':
      WuxiaUi.battleSongshanDaoistDiscipleStandee,
  'assets/enemies/caobang_duozhu.png': WuxiaUi.battleCanalGangHelmsmanStandee,
  'assets/enemies/zhongzhou_lunjian_xianfeng.png':
      WuxiaUi.battleCentralPlainsVanguardStandee,
  'assets/enemies/xiliang_sandizi.png':
      WuxiaUi.battleWesternThirdDiscipleStandee,
  'assets/enemies/lunjian_sanchang_xunluo.png':
      WuxiaUi.battleArenaPatrolStandee,
  'assets/enemies/songshan_shouguan.png':
      WuxiaUi.battleSongshanGatekeeperStandee,
  'assets/enemies/huanghe_yuantou_yufu.png':
      WuxiaUi.battleYellowRiverFisherStandee,
  'assets/enemies/kunlun_waimen_shouguan.png':
      WuxiaUi.battleKunlunGateGuardianStandee,
  'assets/enemies/xiliang_bazhu.png': WuxiaUi.battleWesternOverlordSaintStandee,
  'assets/enemies/anye.png': WuxiaUi.battleNightSwordsmanStandee,
  'assets/enemies/shiye.png': WuxiaUi.battleAdviserStandee,
  'assets/enemies/fu_zhaizhu.png': WuxiaUi.battleFuChiefStandee,
  // Ch7/Ch8 立绘本身已是透明全身图；identity override 让直用资产与旧敌
  // 共用同一套透明识别、脚底锚点和光学校准入口。
  'assets/enemies/monan_mazei.png': 'assets/enemies/monan_mazei.png',
  'assets/enemies/hanhai_shadao.png': 'assets/enemies/hanhai_shadao.png',
  'assets/enemies/gucheng_shuwei.png': 'assets/enemies/gucheng_shuwei.png',
  'assets/enemies/beidi_shuzu.png': 'assets/enemies/beidi_shuzu.png',
  'assets/enemies/fengxue_shaoqi.png': 'assets/enemies/fengxue_shaoqi.png',
  'assets/enemies/beipai_youshao.png': 'assets/enemies/beipai_youshao.png',
  'assets/enemies/beipai_zongjiang.png': 'assets/enemies/beipai_zongjiang.png',
  'assets/enemies/huiyiren_beijing.png': 'assets/enemies/huiyiren_beijing.png',
  'assets/enemies/huiyiren_saibei.png': 'assets/enemies/huiyiren_saibei.png',
  'assets/enemies/huiyiren_final.png': 'assets/enemies/huiyiren_final.png',
  // Ch9「碛北」5 敌立绘(codex image_gen·透明全身图)
  'assets/enemies/qibei_guanmazei.png': 'assets/enemies/qibei_guanmazei.png',
  'assets/enemies/qibei_baiguo_shadao.png':
      'assets/enemies/qibei_baiguo_shadao.png',
  'assets/enemies/qibei_shenlou_huanjing.png':
      'assets/enemies/qibei_shenlou_huanjing.png',
  'assets/enemies/qibei_aikou_shouwei.png':
      'assets/enemies/qibei_aikou_shouwei.png',
  'assets/enemies/qibei_nayiwei.png': 'assets/enemies/qibei_nayiwei.png',
  // Ch10「中州」5 敌立绘(codex image_gen·透明全身图)
  'assets/enemies/zhongzhou_hetao_jianke.png':
      'assets/enemies/zhongzhou_hetao_jianke.png',
  'assets/enemies/zhongzhou_yanmen_youxia.png':
      'assets/enemies/zhongzhou_yanmen_youxia.png',
  'assets/enemies/zhongzhou_luoshui_zhaoying.png':
      'assets/enemies/zhongzhou_luoshui_zhaoying.png',
  'assets/enemies/zhongzhou_songyang_guanzhu.png':
      'assets/enemies/zhongzhou_songyang_guanzhu.png',
  'assets/enemies/zhongzhou_shouzhuo_weng.png':
      'assets/enemies/zhongzhou_shouzhuo_weng.png',
  // Ch11「名门之虚」5 敌立绘(codex image_gen·透明全身图)
  'assets/enemies/zhongzhou_xudu_mingjia.png':
      'assets/enemies/zhongzhou_xudu_mingjia.png',
  'assets/enemies/zhongzhou_jinding_menren.png':
      'assets/enemies/zhongzhou_jinding_menren.png',
  'assets/enemies/zhongzhou_luoyang_haoke.png':
      'assets/enemies/zhongzhou_luoyang_haoke.png',
  'assets/enemies/zhongzhou_yujing_jianzhu.png':
      'assets/enemies/zhongzhou_yujing_jianzhu.png',
  'assets/enemies/zhongzhou_liujin_gong.png':
      'assets/enemies/zhongzhou_liujin_gong.png',
  // Ch12「名下之实」5 敌立绘(codex image_gen·透明全身图)
  'assets/enemies/zhongzhou_hanjiang_chenggao.png':
      'assets/enemies/zhongzhou_hanjiang_chenggao.png',
  'assets/enemies/zhongzhou_huaixiang_quanshi.png':
      'assets/enemies/zhongzhou_huaixiang_quanshi.png',
  'assets/enemies/zhongzhou_qiushan_tiaoshan.png':
      'assets/enemies/zhongzhou_qiushan_tiaoshan.png',
  'assets/enemies/zhongzhou_laotie_tiejiang.png':
      'assets/enemies/zhongzhou_laotie_tiejiang.png',
  'assets/enemies/zhongzhou_huangcun_wuming.png':
      'assets/enemies/zhongzhou_huangcun_wuming.png',
  // Ch13「山外青山」5 敌立绘(codex image_gen·透明全身图)
  'assets/enemies/shanwai_chapeng_bashi.png':
      'assets/enemies/shanwai_chapeng_bashi.png',
  'assets/enemies/shanwai_banshan_seng.png':
      'assets/enemies/shanwai_banshan_seng.png',
  'assets/enemies/shanwai_zhulin_yinke.png':
      'assets/enemies/shanwai_zhulin_yinke.png',
  'assets/enemies/shanwai_duanya_shouguan.png':
      'assets/enemies/shanwai_duanya_shouguan.png',
  'assets/enemies/shanwai_jueding_houfeng.png':
      'assets/enemies/shanwai_jueding_houfeng.png',
  // Ch14「山外来客」5 敌立绘(codex image_gen·透明全身图)
  'assets/enemies/xiliang_kaidao_xinshi.png':
      'assets/enemies/xiliang_kaidao_xinshi.png',
  'assets/enemies/xiliang_xianfeng.png': 'assets/enemies/xiliang_xianfeng.png',
  'assets/enemies/xiliang_xiyu_jianke.png':
      'assets/enemies/xiliang_xiyu_jianke.png',
  'assets/enemies/xiliang_fujiang.png': 'assets/enemies/xiliang_fujiang.png',
  'assets/enemies/xiliang_mazhan_zongshi.png':
      'assets/enemies/xiliang_mazhan_zongshi.png',
  // Ch15「关山一程」5 敌立绘(codex image_gen·透明全身图)
  'assets/enemies/guanshan_songxing_tongdao.png':
      'assets/enemies/guanshan_songxing_tongdao.png',
  'assets/enemies/guanshan_dukou_yeke.png':
      'assets/enemies/guanshan_dukou_yeke.png',
  'assets/enemies/guanshan_xingjiao_seng.png':
      'assets/enemies/guanshan_xingjiao_seng.png',
  'assets/enemies/guanshan_shahai_zongpiao.png':
      'assets/enemies/guanshan_shahai_zongpiao.png',
  'assets/enemies/guanshan_shouguan_laojiang.png':
      'assets/enemies/guanshan_shouguan_laojiang.png',
  // Ch16「凉州词」5 敌立绘(codex image_gen·透明全身图)
  'assets/enemies/liangzhou_songguan_jiubu.png':
      'assets/enemies/liangzhou_songguan_jiubu.png',
  'assets/enemies/liangzhou_heishi_shoujing.png':
      'assets/enemies/liangzhou_heishi_shoujing.png',
  'assets/enemies/liangzhou_xiliang_xingke.png':
      'assets/enemies/liangzhou_xiliang_xingke.png',
  'assets/enemies/liangzhou_youqi_jiang.png':
      'assets/enemies/liangzhou_youqi_jiang.png',
  'assets/enemies/liangzhou_jieguan_ren.png':
      'assets/enemies/liangzhou_jieguan_ren.png',
  // Ch17「沙海纵深」5 敌立绘(codex image_gen·透明全身图·2026-07-26 美术批已交付,
  // 脚底 fraction 已按 alpha 包围盒实测补进下方表、allowlist 表项已清)。
  'assets/enemies/shahai_ta_sha_ke.png': 'assets/enemies/shahai_ta_sha_ke.png',
  'assets/enemies/shahai_heifeng_daoke.png':
      'assets/enemies/shahai_heifeng_daoke.png',
  'assets/enemies/shahai_shoucheng_laozu.png':
      'assets/enemies/shahai_shoucheng_laozu.png',
  'assets/enemies/shahai_juan_sha_shou.png':
      'assets/enemies/shahai_juan_sha_shou.png',
  'assets/enemies/shahai_linglu_ren.png':
      'assets/enemies/shahai_linglu_ren.png',
  // Ch18「阳关故人」宗师段收官章(2026-07-27 章批):图待出(known_missing_assets 已登记),
  // 脚底 fraction 暂走 `_ => 0.95` 默认,出图批按 alpha 包围盒实测再补本表下方映射。
  'assets/enemies/yangguan_qikou_shoushao.png':
      'assets/enemies/yangguan_qikou_shoushao.png',
  'assets/enemies/yangguan_jie_yan_ke.png':
      'assets/enemies/yangguan_jie_yan_ke.png',
  'assets/enemies/yangguan_chengxia_houke.png':
      'assets/enemies/yangguan_chengxia_houke.png',
  'assets/enemies/yangguan_san_dizi.png':
      'assets/enemies/yangguan_san_dizi.png',
  'assets/enemies/yangguan_xiliang_bazhu.png':
      'assets/enemies/yangguan_xiliang_bazhu.png',
  // Ch19「旧路照人」武圣段首章(2026-07-28 章批·美术已接线):接关人/守镜人以 Ch16 立绘
  // 作人物锚复出(非仅风格锚);脚底 fraction 见本文件下方映射表(alpha 包围盒实测)。
  'assets/enemies/jiulu_zhe_fan_ke.png': 'assets/enemies/jiulu_zhe_fan_ke.png',
  'assets/enemies/jiulu_liang_sha_ke.png':
      'assets/enemies/jiulu_liang_sha_ke.png',
  'assets/enemies/jiulu_ting_feng_ren.png':
      'assets/enemies/jiulu_ting_feng_ren.png',
  'assets/enemies/jiulu_jieguan_ren.png':
      'assets/enemies/jiulu_jieguan_ren.png',
  'assets/enemies/jiulu_heishi_shoujing.png':
      'assets/enemies/jiulu_heishi_shoujing.png',
  // Ch20「东入阳关」武圣段中章(2026-07-28 章批·2026-07-29 美术已接线):
  // 脚底 fraction 见本文件下方映射表(alpha 包围盒实测)。
  // 送关旧部/守关老将是 Ch16_01/Ch15_05 既有人物复出,出图已以
  // liangzhou_songguan_jiubu.png / guanshan_shouguan_laojiang.png 作**人物锚**,
  // 目检确认与锚图同一张脸(送关旧部新白布被风吹直 / 守关老将刀暗沉如门闩、刀尖下垂)。
  'assets/enemies/ruguan_huan_ma_ren.png':
      'assets/enemies/ruguan_huan_ma_ren.png',
  'assets/enemies/ruguan_shou_feng_ren.png':
      'assets/enemies/ruguan_shou_feng_ren.png',
  'assets/enemies/ruguan_bu_qiang_jiang.png':
      'assets/enemies/ruguan_bu_qiang_jiang.png',
  'assets/enemies/ruguan_songguan_jiubu.png':
      'assets/enemies/ruguan_songguan_jiubu.png',
  'assets/enemies/ruguan_shouguan_laojiang.png':
      'assets/enemies/ruguan_shouguan_laojiang.png',
  // Ch21「绝顶交程」武圣段收官 = 主线终章(2026-07-29 章批·同日美术已接线):
  // 脚底 fraction 见本文件下方映射表(alpha 包围盒实测)。
  // 五人全为新人物、无人物锚,风格锚取 Ch20 立绘;
  // 三处实景锚复用既有图(绝顶平台=Ch13_05 同一处 / 黄河渡=Ch5_03 / 论剑坪=Ch6_01)。
  'assets/enemies/jueding_guan_he_zu.png':
      'assets/enemies/jueding_guan_he_zu.png',
  'assets/enemies/jueding_bai_du_lao_shou.png':
      'assets/enemies/jueding_bai_du_lao_shou.png',
  'assets/enemies/jueding_lunjian_houren.png':
      'assets/enemies/jueding_lunjian_houren.png',
  'assets/enemies/jueding_lan_jing_lao_pu.png':
      'assets/enemies/jueding_lan_jing_lao_pu.png',
  'assets/enemies/jueding_xun_fu_shaonian.png':
      'assets/enemies/jueding_xun_fu_shaonian.png',
  'assets/enemies/enemy_gauntlet_su_wujiu.png':
      WuxiaUi.battleGauntletSuWujiuStandee,
  'assets/enemies/enemy_gauntlet_qingyi_hu_a.png':
      WuxiaUi.battleGauntletQingyiGuardAStandee,
  'assets/enemies/enemy_gauntlet_qingyi_hu_b.png':
      WuxiaUi.battleGauntletQingyiGuardBStandee,
  'assets/enemies/enemy_gauntlet_shi_zhenyue.png':
      WuxiaUi.battleGauntletShiZhenyueStandee,
  'assets/enemies/enemy_gauntlet_zhizhang_a.png':
      WuxiaUi.battleGauntletStaffRetainerAStandee,
  'assets/enemies/enemy_gauntlet_zhizhang_b.png':
      WuxiaUi.battleGauntletStaffRetainerBStandee,
  'assets/enemies/enemy_gauntlet_wen_jiuzhen.png':
      WuxiaUi.battleGauntletWenJiuzhenStandee,
  'assets/enemies/enemy_baicao_shanjia.png': WuxiaUi.battleBaicaoShanjiaStandee,
  'assets/enemies/enemy_baicao_fenghou.png': WuxiaUi.battleBaicaoFenghouStandee,
  'assets/enemies/enemy_baicao_duwu.png':
      WuxiaUi.battleBaicaoPoisonHerbalistStandee,
  'assets/enemies/enemy_baicao_fog_leader.png':
      WuxiaUi.battleBaicaoFogLeaderStandee,
  'assets/enemies/enemy_baicao_fog_guard.png':
      WuxiaUi.battleBaicaoFogGuardStandee,
  'assets/enemies/enemy_baicao_fog_scout.png':
      WuxiaUi.battleBaicaoFogScoutStandee,
  'assets/enemies/enemy_baicao_ridge_leader.png':
      WuxiaUi.battleBaicaoRidgeLeaderStandee,
  'assets/enemies/enemy_baicao_ridge_needler.png':
      WuxiaUi.battleBaicaoRidgeNeedlerStandee,
  'assets/enemies/enemy_baicao_ridge_runner.png':
      WuxiaUi.battleBaicaoRidgeRunnerStandee,
};

/// 透明图脚底在原图高度中的实际比例。生成立绘的透明画布留白不同，
/// 不能用 Widget 容器底边冒充脚底；否则接触影和状态牌会漂在人物下方。
const _stageStandeeAnchorFootFraction = 0.95;

double battleStandeeFootFraction(String? path) => switch (path) {
  WuxiaUi.battleFounderFallback => 0.938,
  WuxiaUi.battleFirstDiscipleFallback => 0.961,
  WuxiaUi.battleSampleFirstDiscipleStandee => 0.999,
  WuxiaUi.battleSecondDiscipleFallback => 0.957,
  WuxiaUi.battleHiddenElderStandee => 0.952,
  WuxiaUi.battleSampleHiddenElderStandee => 0.942,
  WuxiaUi.battleBanditBladeStandee => 0.823,
  WuxiaUi.battleSampleBanditBladeStandee => 0.811,
  WuxiaUi.battleBanditArcherStandee => 0.939,
  WuxiaUi.battleSampleBanditArcherStandee => 0.885,
  WuxiaUi.battleYoungRuffianStandee => 0.928,
  WuxiaUi.battleGauntCutpurseStandee => 0.943,
  WuxiaUi.battleVillageRuffianStandee => 0.957,
  WuxiaUi.battleBanditHeadStandee => 0.968,
  WuxiaUi.battleQingshanStandee => 0.958,
  WuxiaUi.battleGreyElderStandee => 0.943,
  WuxiaUi.battleSpringHallYouthStandee => 0.962,
  WuxiaUi.battleBaldStaffFighterStandee => 0.911,
  WuxiaUi.battleArenaChampionStandee => 0.969,
  WuxiaUi.battleGreyMonkStandee => 0.943,
  WuxiaUi.battleScarredBossStandee => 0.969,
  WuxiaUi.battleUmbrellaStandee => 0.9462,
  WuxiaUi.battleGreySwordsmanStandee => 0.971,
  WuxiaUi.battleFerryBanditStandee => 0.961,
  WuxiaUi.battleFerryBoatmanStandee => 0.870,
  WuxiaUi.battleFerrySaberStandee => 0.892,
  WuxiaUi.battleNightPatrolStandee => 0.936,
  WuxiaUi.battleRooftopConstableStandee => 0.961,
  WuxiaUi.battleRooftopAssassinStandee => 0.951,
  WuxiaUi.battleJiangnanSwordsmanStandee => 0.960,
  WuxiaUi.battleBambooSaberStandee => 0.974,
  WuxiaUi.battleBambooWandererStandee => 0.968,
  WuxiaUi.battleMountainStreamSwordStandee => 0.933,
  WuxiaUi.battleWaterfallSaberStandee => 0.961,
  WuxiaUi.battleCliffWandererStandee => 0.846,
  WuxiaUi.battleGateCommanderStandee => 0.821,
  WuxiaUi.battleLongWindSwordStandee => 0.832,
  WuxiaUi.battleLongRoadSaberStandee => 0.859,
  WuxiaUi.battleVillageBanditLeaderStandee => 0.935,
  WuxiaUi.battleVillageBanditArcherStandee => 0.926,
  WuxiaUi.battleVillageBanditSaberStandee => 0.919,
  WuxiaUi.battleTownBanditLeaderStandee => 0.772,
  WuxiaUi.battleTownBanditWandererStandee => 0.813,
  WuxiaUi.battleTownBanditAssassinStandee => 0.921,
  WuxiaUi.battleRivalSectMasterStandee => 0.936,
  WuxiaUi.battleRivalSectProtectorStandee => 0.926,
  WuxiaUi.battleRivalSectDiscipleStandee => 0.882,
  WuxiaUi.battleFrontierCommanderStandee => 0.910,
  WuxiaUi.battleFrontierOutriderStandee => 0.855,
  WuxiaUi.battleFrontierIronGuardStandee => 0.840,
  WuxiaUi.battleWesternRemnantGeneralStandee => 0.907,
  WuxiaUi.battleWesternFrenziedRiderStandee => 0.766,
  WuxiaUi.battleWesternRemnantAssassinStandee => 0.814,
  WuxiaUi.battleSwordStoneElderStandee => 0.880,
  WuxiaUi.battleBlackWindChiefStandee => 0.956,
  WuxiaUi.battleNightPavilionMasterStandee => 0.963,
  WuxiaUi.battleSummitSwordDemonStandee => 0.900,
  WuxiaUi.battleWesternMartialSeniorStandee => 0.928,
  WuxiaUi.battleWesternOverlordStandee => 0.925,
  WuxiaUi.battleCentralPlainsVanguardStandee => 0.936,
  WuxiaUi.battleWesternThirdDiscipleStandee => 0.932,
  WuxiaUi.battleKunlunGateGuardianStandee => 0.950,
  WuxiaUi.battleWesternOverlordSaintStandee => 0.950,
  WuxiaUi.battleWanderingPalmFighterStandee => 0.923,
  WuxiaUi.battleEstablishedSectDiscipleStandee => 0.924,
  WuxiaUi.battleLowRankSaberFighterStandee => 0.886,
  WuxiaUi.battleBlackWindUnderlingStandee => 0.888,
  WuxiaUi.battleIndependentWandererStandee => 0.907,
  WuxiaUi.battleRaiderLeaderStandee => 0.934,
  WuxiaUi.battleYumenGarrisonOfficerStandee => 0.947,
  WuxiaUi.battleDesertBanditLeaderStandee => 0.944,
  WuxiaUi.battleTongguanDefenderStandee => 0.953,
  WuxiaUi.battleSongshanDaoistDiscipleStandee => 0.921,
  WuxiaUi.battleCanalGangHelmsmanStandee => 0.934,
  WuxiaUi.battleArenaPatrolStandee => 0.936,
  WuxiaUi.battleSongshanGatekeeperStandee => 0.942,
  WuxiaUi.battleYellowRiverFisherStandee => 0.926,
  WuxiaUi.battleLeftGuardianStandee => 0.940,
  WuxiaUi.battleRightGuardianStandee => 0.956,
  WuxiaUi.battleTowerBoss30Standee => 0.972,
  WuxiaUi.battleJianghuSeniorStandee => 0.950,
  WuxiaUi.battleWulinOverlordStandee => 0.958,
  WuxiaUi.battleNightSwordsmanStandee => 0.951,
  WuxiaUi.battleAdviserStandee => 0.951,
  WuxiaUi.battleFuChiefStandee => 0.927,
  'assets/enemies/monan_mazei.png' => 0.988,
  'assets/enemies/hanhai_shadao.png' => 0.974,
  'assets/enemies/gucheng_shuwei.png' => 0.977,
  'assets/enemies/beidi_shuzu.png' => 0.975,
  'assets/enemies/fengxue_shaoqi.png' => 0.964,
  'assets/enemies/beipai_youshao.png' => 0.965,
  'assets/enemies/beipai_zongjiang.png' => 0.970,
  'assets/enemies/huiyiren_beijing.png' => 0.981,
  'assets/enemies/huiyiren_saibei.png' => 0.976,
  'assets/enemies/huiyiren_final.png' => 0.991,
  // Ch9「碛北」5 敌脚底校准(alpha 包围盒实测·2026-07-20)
  'assets/enemies/qibei_guanmazei.png' => 0.972,
  'assets/enemies/qibei_baiguo_shadao.png' => 0.965,
  'assets/enemies/qibei_shenlou_huanjing.png' => 0.986,
  'assets/enemies/qibei_aikou_shouwei.png' => 0.970,
  'assets/enemies/qibei_nayiwei.png' => 0.981,
  // Ch10「中州」5 敌脚底校准(alpha 包围盒实测·2026-07-21)
  'assets/enemies/zhongzhou_hetao_jianke.png' => 0.958,
  'assets/enemies/zhongzhou_yanmen_youxia.png' => 0.960,
  'assets/enemies/zhongzhou_luoshui_zhaoying.png' => 0.934,
  'assets/enemies/zhongzhou_songyang_guanzhu.png' => 0.964,
  'assets/enemies/zhongzhou_shouzhuo_weng.png' => 0.982,
  // Ch11「名门之虚」5 敌脚底校准(alpha 包围盒实测·2026-07-21)
  'assets/enemies/zhongzhou_xudu_mingjia.png' => 0.983,
  'assets/enemies/zhongzhou_jinding_menren.png' => 0.953,
  'assets/enemies/zhongzhou_luoyang_haoke.png' => 0.968,
  'assets/enemies/zhongzhou_yujing_jianzhu.png' => 0.952,
  'assets/enemies/zhongzhou_liujin_gong.png' => 0.962,
  // Ch12「名下之实」5 敌脚底校准(alpha 包围盒实测·2026-07-22)
  'assets/enemies/zhongzhou_hanjiang_chenggao.png' => 0.965,
  'assets/enemies/zhongzhou_huaixiang_quanshi.png' => 0.958,
  'assets/enemies/zhongzhou_qiushan_tiaoshan.png' => 0.950,
  'assets/enemies/zhongzhou_laotie_tiejiang.png' => 0.956,
  'assets/enemies/zhongzhou_huangcun_wuming.png' => 0.951,
  // Ch13「山外青山」5 敌脚底校准(alpha 包围盒实测·2026-07-22)
  'assets/enemies/shanwai_chapeng_bashi.png' => 0.961,
  'assets/enemies/shanwai_banshan_seng.png' => 0.954,
  'assets/enemies/shanwai_zhulin_yinke.png' => 0.983,
  'assets/enemies/shanwai_duanya_shouguan.png' => 0.986,
  'assets/enemies/shanwai_jueding_houfeng.png' => 0.960,
  // Ch14「山外来客」5 敌脚底校准(alpha 包围盒实测·2026-07-23)
  'assets/enemies/xiliang_kaidao_xinshi.png' => 0.949,
  'assets/enemies/xiliang_xianfeng.png' => 0.947,
  'assets/enemies/xiliang_xiyu_jianke.png' => 0.982,
  'assets/enemies/xiliang_fujiang.png' => 0.986,
  'assets/enemies/xiliang_mazhan_zongshi.png' => 0.951,
  // Ch15「关山一程」5 敌脚底校准(alpha 包围盒实测·2026-07-24)
  'assets/enemies/guanshan_songxing_tongdao.png' => 0.956,
  'assets/enemies/guanshan_dukou_yeke.png' => 0.989,
  'assets/enemies/guanshan_xingjiao_seng.png' => 0.962,
  'assets/enemies/guanshan_shahai_zongpiao.png' => 0.990,
  'assets/enemies/guanshan_shouguan_laojiang.png' => 0.959,
  // Ch16「凉州词」5 敌脚底校准(alpha 包围盒实测·2026-07-25)
  'assets/enemies/liangzhou_songguan_jiubu.png' => 0.973,
  'assets/enemies/liangzhou_heishi_shoujing.png' => 0.982,
  'assets/enemies/liangzhou_xiliang_xingke.png' => 0.982,
  'assets/enemies/liangzhou_youqi_jiang.png' => 0.958,
  'assets/enemies/liangzhou_jieguan_ren.png' => 0.973,
  // Ch17「沙海纵深」5 敌脚底校准(alpha 包围盒实测·2026-07-26)
  'assets/enemies/shahai_ta_sha_ke.png' => 0.970,
  'assets/enemies/shahai_heifeng_daoke.png' => 0.982,
  'assets/enemies/shahai_shoucheng_laozu.png' => 0.990,
  'assets/enemies/shahai_juan_sha_shou.png' => 0.982,
  'assets/enemies/shahai_linglu_ren.png' => 0.988,
  // Ch18「阳关故人」5 敌脚底校准(alpha 包围盒实测·2026-07-27·codex image_gen 专批)
  'assets/enemies/yangguan_qikou_shoushao.png' => 0.947,
  'assets/enemies/yangguan_jie_yan_ke.png' => 0.953,
  'assets/enemies/yangguan_chengxia_houke.png' => 0.954,
  'assets/enemies/yangguan_san_dizi.png' => 0.934,
  'assets/enemies/yangguan_xiliang_bazhu.png' => 0.991,
  // Ch19「旧路照人」(2026-07-28 美术批):alpha 包围盒实测登记。
  'assets/enemies/jiulu_zhe_fan_ke.png' => 0.963,
  'assets/enemies/jiulu_liang_sha_ke.png' => 0.994,
  'assets/enemies/jiulu_ting_feng_ren.png' => 0.973,
  'assets/enemies/jiulu_jieguan_ren.png' => 0.981,
  'assets/enemies/jiulu_heishi_shoujing.png' => 0.981,
  // Ch20「东入阳关」(2026-07-29 美术批):alpha 包围盒实测登记(PIL 逐图现测,非采信出图端自报)。
  // 送关旧部 0.9277 明显低于同批其余四张(0.9486-0.9635),是其 alpha 包围盒底沿实测值
  // (bbox=(40,86,1003,1425) / 1536)——本表存在的意义就是吸收这种逐图差异,勿手改成「看着齐」。
  'assets/enemies/ruguan_huan_ma_ren.png' => 0.9486,
  'assets/enemies/ruguan_shou_feng_ren.png' => 0.9635,
  'assets/enemies/ruguan_bu_qiang_jiang.png' => 0.9622,
  'assets/enemies/ruguan_songguan_jiubu.png' => 0.9277,
  'assets/enemies/ruguan_shouguan_laojiang.png' => 0.9622,
  // Ch21「绝顶交程」主线终章(2026-07-29 美术批):alpha 包围盒实测登记(PIL 逐图现测)。
  // 五张人像纵向占比收敛在 1374-1415px 窄带(摆渡老手首版只占 1127px、比同批矮两成,
  // 已退回重构图修正),故本章无需再上 `_stageStandeeOpticalProfile` 的 scale 补偿。
  // 2026-07-30 真机战斗屏目检补记:`jueding_lunjian_houren` 曾**左脚整只(含鞋尖)悬空**、
  // 与落地的右脚差 164px(=其身高纵跨 1394 的 10.7%),违「脚完整踩在同一水平面上」。
  // 已返修(后脚只抬跟、脚尖仍着地,双脚最低点差降到 10px),**脚底 fraction 实测仍 0.9603
  // 故本表零改动**。此类缺陷 `battle_standee_asset_role_test` 逮不到——九判据只验 alpha
  // 包围盒**底沿**,单脚悬空不改底沿;且已实测存量 75 张里 30 张底部高差 >120px 全是
  // 前后脚透视深度差(前脚更近故在画布上更低)而非悬空,该几何量不具判别力,不可自动化。
  'assets/enemies/jueding_guan_he_zu.png' => 0.9596,
  'assets/enemies/jueding_bai_du_lao_shou.png' => 0.9473,
  'assets/enemies/jueding_lunjian_houren.png' => 0.9603,
  'assets/enemies/jueding_lan_jing_lao_pu.png' => 0.9427,
  'assets/enemies/jueding_xun_fu_shaonian.png' => 0.9479,
  WuxiaUi.battleGauntletSuWujiuStandee => 0.9681,
  WuxiaUi.battleGauntletQingyiGuardAStandee => 0.9571,
  WuxiaUi.battleGauntletQingyiGuardBStandee => 0.9642,
  WuxiaUi.battleGauntletShiZhenyueStandee => 0.9755,
  WuxiaUi.battleGauntletStaffRetainerAStandee => 0.9740,
  WuxiaUi.battleGauntletStaffRetainerBStandee => 0.9631,
  WuxiaUi.battleGauntletWenJiuzhenStandee => 0.9818,
  WuxiaUi.battleBaicaoShanjiaStandee => 0.9707,
  WuxiaUi.battleBaicaoFenghouStandee => 0.9538,
  WuxiaUi.battleBaicaoPoisonHerbalistStandee => 0.9733,
  WuxiaUi.battleBaicaoFogLeaderStandee => 0.9629,
  WuxiaUi.battleBaicaoFogGuardStandee => 0.9727,
  WuxiaUi.battleBaicaoFogScoutStandee => 0.9407,
  WuxiaUi.battleBaicaoRidgeLeaderStandee => 0.9817,
  WuxiaUi.battleBaicaoRidgeNeedlerStandee => 0.9564,
  WuxiaUi.battleBaicaoRidgeRunnerStandee => 0.9566,
  _ => 0.95,
};

typedef _StageStandeeOpticalProfile = ({
  double scale,
  double horizontalShiftFraction,
});

typedef _StageStandeeSampleAspect = ({
  double horizontalScale,
  double verticalScale,
});

/// 黄金样板角色原画的身形校准。这里只修正透明立绘在舞台上的视觉纵横比，
/// 不改变阵型锚点、状态牌位置或战斗数值。
_StageStandeeSampleAspect _stageStandeeSampleAspect(String? path) =>
    switch (path) {
      WuxiaUi.battleFounderFallback => (
        horizontalScale: 1.30,
        verticalScale: 0.95,
      ),
      WuxiaUi.battleSampleFirstDiscipleStandee => (
        horizontalScale: 1.0,
        verticalScale: 1.0,
      ),
      WuxiaUi.battleSecondDiscipleFallback => (
        horizontalScale: 1.0,
        verticalScale: 0.88,
      ),
      WuxiaUi.battleHiddenElderStandee => (
        horizontalScale: 1.12,
        verticalScale: 0.93,
      ),
      WuxiaUi.battleSampleHiddenElderStandee => (
        horizontalScale: 1.12,
        verticalScale: 0.96,
      ),
      WuxiaUi.battleBanditBladeStandee => (
        horizontalScale: 1.08,
        verticalScale: 0.92,
      ),
      WuxiaUi.battleBanditArcherStandee => (
        horizontalScale: 1.05,
        verticalScale: 0.95,
      ),
      WuxiaUi.battleSampleBanditBladeStandee => (
        horizontalScale: 1.30,
        verticalScale: 1.25,
      ),
      WuxiaUi.battleSampleBanditArcherStandee => (
        horizontalScale: 1.12,
        verticalScale: 1.22,
      ),
      _ => (horizontalScale: 1.0, verticalScale: 1.0),
    };

/// 以透明像素的有效包围盒为基准的光学校准。
/// 数值只补偿原图画布留白，不表示战斗单位的体型或阵型位置。
_StageStandeeOpticalProfile _stageStandeeOpticalProfile(
  String? path,
) => switch (path) {
  WuxiaUi.battleFounderFallback => (
    scale: 1.40,
    horizontalShiftFraction: -0.05,
  ),
  WuxiaUi.battleFirstDiscipleFallback => (
    scale: 1.18,
    horizontalShiftFraction: 0.04,
  ),
  WuxiaUi.battleSampleFirstDiscipleStandee => (
    scale: 1.08,
    horizontalShiftFraction: -0.03,
  ),
  WuxiaUi.battleSecondDiscipleFallback => (
    scale: 1.12,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleHiddenElderStandee => (scale: 1.14, horizontalShiftFraction: 0),
  WuxiaUi.battleSampleHiddenElderStandee => (
    scale: 1.14,
    horizontalShiftFraction: 0.03,
  ),
  WuxiaUi.battleBanditBladeStandee => (
    scale: 1.33,
    horizontalShiftFraction: 0.015,
  ),
  WuxiaUi.battleBanditArcherStandee => (
    scale: 1.28,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleSampleBanditBladeStandee => (
    scale: 1.0,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleSampleBanditArcherStandee => (
    scale: 1.05,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleYoungRuffianStandee => (
    scale: 1.06,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleGauntCutpurseStandee => (
    scale: 1.07,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleVillageRuffianStandee => (
    scale: 1.1,
    horizontalShiftFraction: 0.03,
  ),
  WuxiaUi.battleBanditHeadStandee => (scale: 1, horizontalShiftFraction: 0.02),
  WuxiaUi.battleQingshanStandee => (scale: 1, horizontalShiftFraction: 0.02),
  WuxiaUi.battleGreyElderStandee => (scale: 1.07, horizontalShiftFraction: 0),
  WuxiaUi.battleBaldStaffFighterStandee => (
    scale: 1.04,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleGreyMonkStandee => (scale: 1.04, horizontalShiftFraction: 0),
  WuxiaUi.battleScarredBossStandee => (
    scale: 0.96,
    horizontalShiftFraction: 0.015,
  ),
  // stage_01_05 为 3v1；撑伞图的有效 alpha 面积较宽，若沿用 1v1 画布
  // 放大，会达到我方三人中位面积的约 2.07 倍。0.81 将 §3.5 唯一口径
  // 收进约 1.36，同时不改变阵列锚点或案台比例。
  WuxiaUi.battleUmbrellaStandee => (scale: 0.81, horizontalShiftFraction: 0),
  WuxiaUi.battleGreySwordsmanStandee => (
    scale: 0.95,
    horizontalShiftFraction: 0.02,
  ),
  WuxiaUi.battleFerryBoatmanStandee => (
    scale: 1.08,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleFerrySaberStandee => (scale: 1.06, horizontalShiftFraction: 0),
  WuxiaUi.battleNightPatrolStandee => (scale: 1.03, horizontalShiftFraction: 0),
  WuxiaUi.battleJiangnanSwordsmanStandee => (
    scale: 0.95,
    horizontalShiftFraction: 0.02,
  ),
  WuxiaUi.battleBambooSaberStandee => (
    scale: 0.96,
    horizontalShiftFraction: 0.01,
  ),
  WuxiaUi.battleMountainStreamSwordStandee => (
    scale: 0.96,
    horizontalShiftFraction: 0.01,
  ),
  WuxiaUi.battleCliffWandererStandee => (
    scale: 1.12,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleGateCommanderStandee => (
    scale: 1.15,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleLongWindSwordStandee => (
    scale: 1.13,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleLongRoadSaberStandee => (
    scale: 1.1,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleVillageBanditLeaderStandee => (
    scale: 1.03,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleVillageBanditArcherStandee => (
    scale: 1.02,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleVillageBanditSaberStandee => (
    scale: 0.98,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleTownBanditLeaderStandee => (
    scale: 1.2,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleTownBanditWandererStandee => (
    scale: 1.15,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleTownBanditAssassinStandee => (
    scale: 1.02,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleRivalSectProtectorStandee => (
    scale: 1.02,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleRivalSectDiscipleStandee => (
    scale: 1.08,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleFrontierOutriderStandee => (
    scale: 1.06,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleFrontierIronGuardStandee => (
    scale: 1.08,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleWesternFrenziedRiderStandee => (
    scale: 1.18,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleWesternRemnantAssassinStandee => (
    scale: 1.12,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleSwordStoneElderStandee => (
    scale: 1.05,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleLowRankSaberFighterStandee => (
    scale: 1.05,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleBlackWindUnderlingStandee => (
    scale: 1.05,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleTongguanDefenderStandee => (
    scale: 1.05,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleArenaPatrolStandee => (scale: 1.08, horizontalShiftFraction: 0),
  'assets/enemies/monan_mazei.png' => (scale: 1, horizontalShiftFraction: 0.06),
  'assets/enemies/hanhai_shadao.png' => (
    scale: 1.02,
    horizontalShiftFraction: -0.015,
  ),
  'assets/enemies/gucheng_shuwei.png' => (
    scale: 0.98,
    horizontalShiftFraction: 0.01,
  ),
  'assets/enemies/beidi_shuzu.png' => (scale: 0.98, horizontalShiftFraction: 0),
  'assets/enemies/fengxue_shaoqi.png' => (
    scale: 1.03,
    horizontalShiftFraction: 0.02,
  ),
  'assets/enemies/beipai_youshao.png' => (
    scale: 1.01,
    horizontalShiftFraction: -0.04,
  ),
  'assets/enemies/beipai_zongjiang.png' => (
    scale: 1,
    horizontalShiftFraction: 0,
  ),
  'assets/enemies/huiyiren_beijing.png' => (
    scale: 0.99,
    horizontalShiftFraction: -0.03,
  ),
  'assets/enemies/huiyiren_saibei.png' => (
    scale: 1,
    horizontalShiftFraction: -0.05,
  ),
  'assets/enemies/huiyiren_final.png' => (
    scale: 0.99,
    horizontalShiftFraction: -0.035,
  ),
  WuxiaUi.battleGauntletSuWujiuStandee => (
    scale: 0.99,
    horizontalShiftFraction: -0.013,
  ),
  WuxiaUi.battleGauntletQingyiGuardAStandee => (
    scale: 1.03,
    horizontalShiftFraction: -0.031,
  ),
  WuxiaUi.battleGauntletQingyiGuardBStandee => (
    scale: 1.01,
    horizontalShiftFraction: -0.079,
  ),
  WuxiaUi.battleGauntletShiZhenyueStandee => (
    scale: 1,
    horizontalShiftFraction: 0.001,
  ),
  WuxiaUi.battleGauntletStaffRetainerAStandee => (
    scale: 1,
    horizontalShiftFraction: 0.039,
  ),
  WuxiaUi.battleGauntletStaffRetainerBStandee => (
    scale: 1.01,
    horizontalShiftFraction: -0.001,
  ),
  WuxiaUi.battleGauntletWenJiuzhenStandee => (
    scale: 0.98,
    horizontalShiftFraction: -0.021,
  ),
  WuxiaUi.battleBaicaoShanjiaStandee => (
    scale: 0.99,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleBaicaoFenghouStandee => (
    scale: 1.03,
    horizontalShiftFraction: 0.003,
  ),
  WuxiaUi.battleBaicaoPoisonHerbalistStandee => (
    scale: 1,
    horizontalShiftFraction: -0.007,
  ),
  WuxiaUi.battleBaicaoFogLeaderStandee => (
    scale: 1.02,
    horizontalShiftFraction: -0.004,
  ),
  WuxiaUi.battleBaicaoFogGuardStandee => (
    scale: 1.01,
    horizontalShiftFraction: 0.008,
  ),
  WuxiaUi.battleBaicaoFogScoutStandee => (
    scale: 1.06,
    horizontalShiftFraction: -0.045,
  ),
  WuxiaUi.battleBaicaoRidgeLeaderStandee => (
    scale: 0.98,
    horizontalShiftFraction: 0,
  ),
  WuxiaUi.battleBaicaoRidgeNeedlerStandee => (
    scale: 1.02,
    horizontalShiftFraction: -0.014,
  ),
  WuxiaUi.battleBaicaoRidgeRunnerStandee => (
    scale: 1.04,
    horizontalShiftFraction: -0.012,
  ),
  _ => (scale: 1, horizontalShiftFraction: 0),
};

class _FirstGlyphStandee extends StatelessWidget {
  const _FirstGlyphStandee({
    required this.width,
    required this.height,
    required this.color,
    required this.firstGlyph,
  });

  final double width;
  final double height;
  final Color color;
  final String firstGlyph;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('battle.stageStandeeIdentitySilhouette'),
      width: width,
      height: height,
      child: CustomPaint(
        painter: _IdentitySilhouettePainter(accent: color),
        child: Align(
          alignment: const Alignment(0, -0.04),
          child: Text(
            firstGlyph,
            style: TextStyle(
              color: WuxiaUi.paper.withValues(alpha: 0.72),
              fontSize: width * 0.115,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 1)],
            ),
          ),
        ),
      ),
    );
  }
}

/// 用既有透明站姿的 alpha 外形绘制纯墨身份影，不泄露该站姿原人物的肤色、
/// 衣纹或五官；专用人物图补齐后只需更新 source→standee 登记即可自动替换。
class _InkIdentityStandee extends StatelessWidget {
  const _InkIdentityStandee({
    required this.shapePath,
    required this.width,
    required this.height,
    required this.accent,
    required this.firstGlyph,
  });

  final String shapePath;
  final double width;
  final double height;
  final Color accent;
  final String firstGlyph;

  @override
  Widget build(BuildContext context) {
    final sealSize = width * 0.155;
    return SizedBox(
      key: const ValueKey('battle.stageStandeeIdentitySilhouette'),
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          WuxiaImage(
            shapePath,
            width: width,
            height: height,
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            color: WuxiaUi.ink2.withValues(alpha: 0.78),
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: wuxiaAssetErrorBuilder(
              () => _FirstGlyphStandee(
                width: width,
                height: height,
                color: accent,
                firstGlyph: firstGlyph,
              ),
            ),
          ),
          Positioned(
            top: height * 0.39,
            child: Container(
              width: sealSize,
              height: sealSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WuxiaUi.ink.withValues(alpha: 0.40),
                border: Border.all(
                  color: accent.withValues(alpha: 0.48),
                  width: 1,
                ),
              ),
              child: Text(
                firstGlyph,
                style: TextStyle(
                  color: WuxiaUi.paper.withValues(alpha: 0.78),
                  fontSize: width * 0.082,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 1)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentitySilhouettePainter extends CustomPainter {
  const _IdentitySilhouettePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final ink = Paint()
      ..color = WuxiaUi.ink2.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.55);
    final deepInk = Paint()
      ..color = WuxiaUi.ink.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;

    // 发髻与头颈不采用几何圆头：略偏的轮廓、颌线和发束让墨影仍读作武侠人物。
    final topknot = Path()
      ..moveTo(centerX - size.width * 0.033, size.height * 0.126)
      ..quadraticBezierTo(
        centerX,
        size.height * 0.096,
        centerX + size.width * 0.034,
        size.height * 0.128,
      )
      ..quadraticBezierTo(
        centerX + size.width * 0.026,
        size.height * 0.160,
        centerX - size.width * 0.026,
        size.height * 0.158,
      )
      ..close();
    final head = Path()
      ..moveTo(centerX - size.width * 0.058, size.height * 0.155)
      ..quadraticBezierTo(
        centerX - size.width * 0.082,
        size.height * 0.200,
        centerX - size.width * 0.048,
        size.height * 0.252,
      )
      ..quadraticBezierTo(
        centerX,
        size.height * 0.283,
        centerX + size.width * 0.050,
        size.height * 0.246,
      )
      ..quadraticBezierTo(
        centerX + size.width * 0.076,
        size.height * 0.190,
        centerX + size.width * 0.042,
        size.height * 0.153,
      )
      ..quadraticBezierTo(
        centerX,
        size.height * 0.137,
        centerX - size.width * 0.058,
        size.height * 0.155,
      )
      ..close();
    final neck = Path()
      ..moveTo(centerX - size.width * 0.035, size.height * 0.238)
      ..lineTo(centerX - size.width * 0.052, size.height * 0.300)
      ..lineTo(centerX + size.width * 0.052, size.height * 0.300)
      ..lineTo(centerX + size.width * 0.035, size.height * 0.238)
      ..close();

    // 中心袍服、两袖与分步下摆分开落墨，避免“厕所标识”式单块轮廓。
    final robe = Path()
      ..moveTo(centerX - size.width * 0.050, size.height * 0.282)
      ..quadraticBezierTo(
        centerX - size.width * 0.145,
        size.height * 0.300,
        centerX - size.width * 0.165,
        size.height * 0.386,
      )
      ..lineTo(centerX - size.width * 0.112, size.height * 0.585)
      ..quadraticBezierTo(
        centerX - size.width * 0.175,
        size.height * 0.720,
        centerX - size.width * 0.128,
        size.height * 0.852,
      )
      ..lineTo(centerX - size.width * 0.098, size.height * 0.915)
      ..lineTo(centerX - size.width * 0.022, size.height * 0.915)
      ..lineTo(centerX + size.width * 0.004, size.height * 0.704)
      ..lineTo(centerX + size.width * 0.046, size.height * 0.915)
      ..lineTo(centerX + size.width * 0.126, size.height * 0.915)
      ..quadraticBezierTo(
        centerX + size.width * 0.185,
        size.height * 0.742,
        centerX + size.width * 0.112,
        size.height * 0.575,
      )
      ..lineTo(centerX + size.width * 0.164, size.height * 0.380)
      ..quadraticBezierTo(
        centerX + size.width * 0.143,
        size.height * 0.300,
        centerX + size.width * 0.050,
        size.height * 0.282,
      )
      ..close();
    final leftSleeve = Path()
      ..moveTo(centerX - size.width * 0.120, size.height * 0.318)
      ..quadraticBezierTo(
        centerX - size.width * 0.225,
        size.height * 0.365,
        centerX - size.width * 0.278,
        size.height * 0.515,
      )
      ..quadraticBezierTo(
        centerX - size.width * 0.300,
        size.height * 0.586,
        centerX - size.width * 0.246,
        size.height * 0.612,
      )
      ..quadraticBezierTo(
        centerX - size.width * 0.198,
        size.height * 0.566,
        centerX - size.width * 0.132,
        size.height * 0.430,
      )
      ..close();
    final rightSleeve = Path()
      ..moveTo(centerX + size.width * 0.118, size.height * 0.316)
      ..quadraticBezierTo(
        centerX + size.width * 0.238,
        size.height * 0.342,
        centerX + size.width * 0.275,
        size.height * 0.455,
      )
      ..quadraticBezierTo(
        centerX + size.width * 0.286,
        size.height * 0.506,
        centerX + size.width * 0.240,
        size.height * 0.528,
      )
      ..quadraticBezierTo(
        centerX + size.width * 0.182,
        size.height * 0.492,
        centerX + size.width * 0.108,
        size.height * 0.410,
      )
      ..close();
    final forearm = Path()
      ..moveTo(centerX + size.width * 0.245, size.height * 0.482)
      ..quadraticBezierTo(
        centerX + size.width * 0.168,
        size.height * 0.525,
        centerX + size.width * 0.060,
        size.height * 0.550,
      )
      ..lineTo(centerX + size.width * 0.026, size.height * 0.505)
      ..quadraticBezierTo(
        centerX + size.width * 0.128,
        size.height * 0.455,
        centerX + size.width * 0.232,
        size.height * 0.430,
      )
      ..close();

    for (final shape in [
      topknot,
      neck,
      robe,
      leftSleeve,
      rightSleeve,
      forearm,
    ]) {
      canvas.drawPath(shape, ink);
    }
    canvas.drawPath(head, ink);

    final hairWash = Path()
      ..moveTo(centerX - size.width * 0.053, size.height * 0.158)
      ..quadraticBezierTo(
        centerX + size.width * 0.018,
        size.height * 0.142,
        centerX + size.width * 0.050,
        size.height * 0.194,
      )
      ..quadraticBezierTo(
        centerX + size.width * 0.010,
        size.height * 0.174,
        centerX - size.width * 0.053,
        size.height * 0.203,
      )
      ..close();
    canvas.drawPath(hairWash, deepInk);

    final clothWash = Paint()
      ..color = WuxiaUi.paper.withValues(alpha: 0.085)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.7);
    final lapel = Path()
      ..moveTo(centerX - size.width * 0.070, size.height * 0.315)
      ..quadraticBezierTo(
        centerX + size.width * 0.018,
        size.height * 0.405,
        centerX + size.width * 0.070,
        size.height * 0.520,
      );
    final robeFold = Path()
      ..moveTo(centerX - size.width * 0.028, size.height * 0.595)
      ..quadraticBezierTo(
        centerX - size.width * 0.085,
        size.height * 0.744,
        centerX - size.width * 0.090,
        size.height * 0.865,
      );
    canvas.drawPath(lapel, clothWash);
    canvas.drawPath(robeFold, clothWash..strokeWidth = size.width * 0.012);

    // 流派色只落成腰间一笔与胸口小印，保留身份提示但不把墨影画成彩色轮廓。
    final accentStroke = Paint()
      ..color = accent.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX - size.width * 0.116, size.height * 0.566),
      Offset(centerX + size.width * 0.118, size.height * 0.558),
      accentStroke,
    );
    canvas.drawCircle(
      Offset(centerX, size.height * 0.478),
      size.width * 0.070,
      Paint()
        ..color = accent.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(centerX, size.height * 0.478),
      size.width * 0.070,
      accentStroke..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _IdentitySilhouettePainter oldDelegate) =>
      oldDelegate.accent != accent;
}

const _grayscaleFilter = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

class _BossAvatarFrame extends StatelessWidget {
  const _BossAvatarFrame({required this.avatarSize, required this.child});

  final double avatarSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frameSize = avatarSize * 1.42;
    return SizedBox(
      key: const ValueKey<String>('battle.bossAvatarFrame'),
      width: frameSize,
      height: frameSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          IgnorePointer(
            child: WuxiaImage(
              WuxiaUi.bossFrameLarge,
              width: frameSize,
              height: frameSize,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 占位头像:首字 + 流派色 4px 边框 CircleAvatar 风格(原 character_avatar 占位降级)。
class _FirstGlyphAvatar extends StatelessWidget {
  final double avatarSize;
  final Color color;
  final double borderWidth;
  final String firstGlyph;

  const _FirstGlyphAvatar({
    required this.avatarSize,
    required this.color,
    this.borderWidth = 4,
    required this.firstGlyph,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: borderWidth),
        color: WuxiaColors.avatarFill,
      ),
      alignment: Alignment.center,
      child: Text(
        firstGlyph,
        style: TextStyle(
          fontSize: avatarSize * 0.42,
          color: WuxiaColors.textPrimary,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}
