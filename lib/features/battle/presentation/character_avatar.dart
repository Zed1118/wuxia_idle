import 'package:flutter/material.dart';

import '../domain/battle_state.dart';
import '../domain/enum_localizations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import 'hp_bar.dart';
import '../../../shared/widgets/asset_fallback.dart';

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

  /// Boss/敌人蓄力满值（`numbers.combat.bossCharge.defaultChargeTicks`）。
  /// 用于把 [BattleCharacter.chargeTicksRemaining] 换算成蓄力进度条比例。
  final int chargeMaxTicks;

  const CharacterAvatar({
    super.key,
    required this.character,
    this.avatarSize = 110,
    this.barWidth = 160,
    this.chargeMaxTicks = 3,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Image.asset(
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

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        avatar,
        const SizedBox(height: 6),
        Text(
          character.name,
          style: const TextStyle(
            fontSize: 14,
            color: WuxiaColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          EnumL10n.realm(character.realmTier, character.realmLayer),
          style: const TextStyle(
            fontSize: 11,
            color: WuxiaColors.textSecondary,
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
            current: character.currentInternalForce,
            max: character.maxInternalForce,
            height: 9,
            isInternalForce: true,
          ),
        ),
        // P0 破招：敌人/Boss 蓄力中显蓄力进度条 + 「可破招」图标（纯读 state）。
        if (character.chargingSkill != null) ...[
          const SizedBox(height: 4),
          _ChargeBar(
            ticksRemaining: character.chargeTicksRemaining,
            maxTicks: chargeMaxTicks,
            width: barWidth,
          ),
        ],
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

class _BossAvatarFrame extends StatelessWidget {
  const _BossAvatarFrame({required this.avatarSize, required this.child});

  final double avatarSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frameSize = avatarSize * 1.42;
    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          child,
          Positioned(
            width: frameSize,
            height: frameSize,
            child: IgnorePointer(
              child: Image.asset(
                WuxiaUi.bossFrameLarge,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 蓄力进度条 + 「可破招」图标（P0 破招）。
/// 进度 = 1 - ticksRemaining / maxTicks（蓄力将满 → 条接近满）；
/// 末尾 [Icons.flash_on] 醒目色提示玩家此刻可破招。纯展示，不写 state。
class _ChargeBar extends StatelessWidget {
  final int ticksRemaining;
  final int maxTicks;
  final double width;

  const _ChargeBar({
    required this.ticksRemaining,
    required this.maxTicks,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxTicks <= 0
        ? 0.0
        : (1 - ticksRemaining / maxTicks).clamp(0.0, 1.0).toDouble();
    const accent = WuxiaColors.resultHighlight;
    final borderRadius = BorderRadius.circular(2);

    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on, size: 13, color: accent),
          const SizedBox(width: 3),
          Expanded(
            child: SizedBox(
              height: 7,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: WuxiaColors.barTrack,
                      borderRadius: borderRadius,
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: borderRadius,
                      ),
                    ),
                  ),
                ],
              ),
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
