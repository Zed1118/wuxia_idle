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
    final sourceFootFraction = _stageStandeeFootFraction(resolvedIconPath);
    final footY = portraitHeight * _stageStandeeAnchorFootFraction;
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

    // 立绘生成时的透明画布留白不一致。绕实际脚底缩放，使成对角色的
    // 有效人物高度接近；水平修正 alpha 重心，垂直将脚底对齐公共基准线。
    final opticalProfile = _stageStandeeOpticalProfile(resolvedIconPath);
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
        child: portraitImage,
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
    final portraitHeight = height * 0.91;
    final footY = portraitHeight * _stageStandeeAnchorFootFraction;
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
};

bool _isTransparentBattleStandee(String? path) =>
    path?.startsWith('assets/characters/battle_') == true ||
    path?.startsWith('assets/enemies/battle_') == true ||
    _battleStandeeOverrides[path] == path;

/// 透明图脚底在原图高度中的实际比例。生成立绘的透明画布留白不同，
/// 不能用 Widget 容器底边冒充脚底；否则接触影和状态牌会漂在人物下方。
const _stageStandeeAnchorFootFraction = 0.95;

double _stageStandeeFootFraction(String? path) => switch (path) {
  WuxiaUi.battleFounderFallback => 0.938,
  WuxiaUi.battleFirstDiscipleFallback => 0.961,
  WuxiaUi.battleSecondDiscipleFallback => 0.957,
  WuxiaUi.battleHiddenElderStandee => 0.952,
  WuxiaUi.battleBanditBladeStandee => 0.823,
  WuxiaUi.battleBanditArcherStandee => 0.939,
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
  _ => 0.95,
};

typedef _StageStandeeOpticalProfile = ({
  double scale,
  double horizontalShiftFraction,
});

/// 以透明像素的有效包围盒为基准的光学校准。
/// 数值只补偿原图画布留白，不表示战斗单位的体型或阵型位置。
_StageStandeeOpticalProfile _stageStandeeOpticalProfile(
  String? path,
) => switch (path) {
  WuxiaUi.battleFounderFallback => (scale: 1.055, horizontalShiftFraction: 0),
  WuxiaUi.battleFirstDiscipleFallback => (
    scale: 1,
    horizontalShiftFraction: 0.04,
  ),
  WuxiaUi.battleBanditBladeStandee => (
    scale: 1.18,
    horizontalShiftFraction: 0.015,
  ),
  WuxiaUi.battleBanditArcherStandee => (
    scale: 1.045,
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
