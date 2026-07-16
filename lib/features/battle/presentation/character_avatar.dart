import 'package:flutter/material.dart';

import '../domain/battle_state.dart';
import '../domain/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import 'avatar_status_tags.dart';
import 'countdown_ring.dart';
import 'guardian_ward_presentation.dart';
import 'hp_bar.dart';
import '../../../shared/widgets/asset_fallback.dart';
import '../../../shared/widgets/wuxia_image.dart';

enum CharacterDisplayMode { avatar, stageStandee }

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
  /// 用于把 [BattleCharacter.chargeTicksRemaining] 换算成蓄力读秒环比例。
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
  });

  @override
  Widget build(BuildContext context) {
    if (displayMode == CharacterDisplayMode.stageStandee) {
      return _StageCharacterStandee(
        character: character,
        battleState: battleState,
        beat: beat ?? const AlwaysStoppedAnimation<double>(0),
        chargeMaxTicks: chargeMaxTicks,
        staggerWindowTicks: staggerWindowTicks,
        width: standeeWidth,
        height: standeeHeight,
        inkMirror: inkMirror,
        showStatusOverlay: showStageStatusOverlay,
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
        // P0 破招：固定蓄力环行高度，避免蓄力态单槽挤压相邻头像。
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
                      BeatCountdownRing(
                        remaining: character.chargeTicksRemaining,
                        total: chargeMaxTicks,
                        beat: effBeat,
                        color: WuxiaColors.hpLow,
                        size: 34,
                      ),
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

/// 战场全人物站姿。透明战斗立绘保持完整头脚；旧 RGB 原画作为降级路径，
/// 继续用水墨晕染遮罩淡化图片矩形边缘。
class _StageCharacterStandee extends StatelessWidget {
  const _StageCharacterStandee({
    required this.character,
    required this.battleState,
    required this.beat,
    required this.chargeMaxTicks,
    required this.staggerWindowTicks,
    required this.width,
    required this.height,
    required this.inkMirror,
    required this.showStatusOverlay,
  });

  final BattleCharacter character;
  final BattleState? battleState;
  final Animation<double> beat;
  final int chargeMaxTicks;
  final int staggerWindowTicks;
  final double width;
  final double height;
  final bool inkMirror;
  final bool showStatusOverlay;

  @override
  Widget build(BuildContext context) {
    final schoolColor = WuxiaColors.schoolColor(character.school);
    final borderColor = character.isBoss ? WuxiaColors.bossFrame : schoolColor;
    final portraitHeight = height * 0.91;
    final firstGlyph = character.name.characters.isEmpty
        ? '?'
        : character.name.characters.first;
    final resolvedIconPath = _resolvedStageIconPath(character);
    final hasIcon = resolvedIconPath != null;
    final usesTransparentStandee = _isTransparentBattleStandee(
      resolvedIconPath,
    );
    final footY = portraitHeight * _stageStandeeFootFraction(resolvedIconPath);
    final groundingHeight = height * 0.065;
    final wardActive =
        battleState != null && isGuardianWardActive(character, battleState!);

    final image = hasIcon
        ? WuxiaImage(
            resolvedIconPath,
            width: width,
            height: portraitHeight,
            fit: usesTransparentStandee ? BoxFit.contain : BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: wuxiaAssetErrorBuilder(
              () => _FirstGlyphStandee(
                width: width,
                height: portraitHeight,
                color: borderColor,
                firstGlyph: firstGlyph,
              ),
            ),
          )
        : _FirstGlyphStandee(
            width: width,
            height: portraitHeight,
            color: borderColor,
            firstGlyph: firstGlyph,
          );

    Widget portraitImage = usesTransparentStandee
        ? image
        : ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const RadialGradient(
              center: Alignment(0, -0.08),
              radius: 0.72,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, 0.50, 0.88],
            ).createShader(rect),
            child: image,
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
      portrait = Container(
        key: const ValueKey<String>('battle.bossAvatarFrame'),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: WuxiaColors.bossFrame.withValues(alpha: 0.20),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
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
            left: width * 0.17,
            right: width * 0.17,
            top: (footY - groundingHeight * 0.45).clamp(
              0.0,
              height - groundingHeight,
            ),
            height: groundingHeight,
            child: const IgnorePointer(
              child: CustomPaint(painter: _StandeeGroundingPainter()),
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
          if (character.chargingSkill != null)
            Positioned(
              top: 34,
              right: 6,
              child: BeatCountdownRing(
                remaining: character.chargeTicksRemaining,
                total: chargeMaxTicks,
                beat: beat,
                color: WuxiaColors.hpLow,
                size: 34,
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

    final dimmed = Opacity(
      opacity: character.isAlive ? 1 : 0.45,
      child: content,
    );
    if (character.isAlive) return dimmed;
    return ColorFiltered(colorFilter: _grayscaleFilter, child: dimmed);
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
  });

  final BattleCharacter character;
  final BattleState? battleState;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final resolvedIconPath = _resolvedStageIconPath(character);
    final portraitHeight = height * 0.91;
    final footY = portraitHeight * _stageStandeeFootFraction(resolvedIconPath);
    final insetFraction = switch (character.slotIndex) {
      0 => 0.24,
      2 => 0.18,
      _ => 0.16,
    };
    final borderColor = character.isBoss
        ? WuxiaColors.bossFrame
        : WuxiaColors.schoolColor(character.school);

    return Positioned(
      left: width * insetFraction,
      right: width * insetFraction,
      top: (footY + 2).clamp(0.0, height - 40),
      child: Opacity(
        opacity: character.isAlive ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 2, 5, 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.28),
                Colors.black.withValues(alpha: 0.90),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: borderColor.withValues(alpha: 0.78)),
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 8, spreadRadius: 1),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                character.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 2),
              HpBar(
                current: character.currentHp,
                max: character.maxHp,
                height: 11,
                fillColorOverride: WuxiaUi.jiang,
                labelFontSize: 8,
                compactLabel: true,
              ),
              const SizedBox(height: 1),
              HpBar(
                current: character.currentQi,
                max: character.maxQi,
                height: 9,
                isInternalForce: true,
                labelPrefix: UiStrings.internalForceShortLabel,
                fillColorOverride: WuxiaUi.qing,
                labelFontSize: 7.5,
                compactLabel: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 透明立绘的接触影与脚底墨晕。影子贴在人物层内，会跟随冲锋、
/// 受击和缩放一起移动，不改战场点击区与角色实际站位。
class _StandeeGroundingPainter extends CustomPainter {
  const _StandeeGroundingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.58);
    final contact = Paint()
      ..color = const Color(0xFF17130F).withValues(alpha: 0.46)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.78,
        height: size.height * 0.46,
      ),
      contact,
    );

    final wash = Paint()
      ..color = const Color(0xFF29231D).withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    final leftWash = Path()
      ..moveTo(size.width * 0.12, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.42,
        size.width * 0.53,
        size.height * 0.67,
      );
    final rightWash = Path()
      ..moveTo(size.width * 0.42, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.48,
        size.width * 0.91,
        size.height * 0.70,
      );
    canvas.drawPath(leftWash, wash);
    canvas.drawPath(rightWash, wash..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant _StandeeGroundingPainter oldDelegate) => false;
}

String? _resolvedStageIconPath(BattleCharacter character) {
  final iconPath = character.iconPath;
  if (iconPath != null && iconPath.isNotEmpty) {
    return _battleStandeeOverrides[iconPath] ?? iconPath;
  }
  if (character.teamSide != 0) return null;
  return switch (character.slotIndex) {
    0 => WuxiaUi.battleFounderFallback,
    1 => WuxiaUi.battleFirstDiscipleFallback,
    2 => WuxiaUi.battleSecondDiscipleFallback,
    _ => null,
  };
}

const _battleStandeeOverrides = <String, String>{
  'assets/characters/founder.png': WuxiaUi.battleFounderFallback,
  'assets/characters/first_disciple.png': WuxiaUi.battleFirstDiscipleFallback,
  'assets/characters/second_disciple.png': WuxiaUi.battleSecondDiscipleFallback,
  'assets/enemies/thug_a.png': WuxiaUi.battleThugStandee,
  'assets/enemies/qingshan_main.png': WuxiaUi.battleHiddenElderStandee,
  'assets/enemies/black_killer.png': WuxiaUi.battleBlackKillerStandee,
  'assets/enemies/killer_a.png': WuxiaUi.battleBanditBladeStandee,
  'assets/enemies/killer_b.png': WuxiaUi.battleBanditArcherStandee,
  'assets/enemies/umbrella.png': WuxiaUi.battleUmbrellaStandee,
  'assets/enemies/tower_boss_20.png': WuxiaUi.battleTowerBoss20Standee,
};

bool _isTransparentBattleStandee(String? path) =>
    path?.startsWith('assets/characters/battle_') == true ||
    path?.startsWith('assets/enemies/battle_') == true;

/// 透明图脚底在原图高度中的实际比例。生成立绘的透明画布留白不同，
/// 不能用 Widget 容器底边冒充脚底；否则接触影和状态牌会漂在人物下方。
double _stageStandeeFootFraction(String? path) => switch (path) {
  WuxiaUi.battleFounderFallback => 0.938,
  WuxiaUi.battleFirstDiscipleFallback => 0.961,
  WuxiaUi.battleSecondDiscipleFallback => 0.957,
  WuxiaUi.battleHiddenElderStandee => 0.952,
  WuxiaUi.battleBanditBladeStandee => 0.823,
  WuxiaUi.battleBanditArcherStandee => 0.939,
  _ => 0.95,
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
    return Container(
      width: width,
      height: height,
      color: WuxiaColors.avatarFill,
      alignment: Alignment.center,
      child: Text(
        firstGlyph,
        style: TextStyle(
          color: color,
          fontSize: width * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
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
