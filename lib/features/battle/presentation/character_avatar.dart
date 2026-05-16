import 'package:flutter/material.dart';

import '../domain/battle_state.dart';
import '../domain/enum_localizations.dart';
import '../../../ui/theme/colors.dart';
import 'hp_bar.dart';

/// 战斗角色头像（phase1_tasks.md T14 §784）。
///
/// 占位用首字 + 流派色边框 CircleAvatar，下方依次：名字 / 境界 / HP 条 / 内力条。
/// `character.isAlive == false` 时整体 opacity 0.3（§794 死亡变灰验收）。
class CharacterAvatar extends StatelessWidget {
  final BattleCharacter character;
  final double avatarSize;
  final double barWidth;

  const CharacterAvatar({
    super.key,
    required this.character,
    this.avatarSize = 80,
    this.barWidth = 160,
  });

  @override
  Widget build(BuildContext context) {
    final color = WuxiaColors.schoolColor(character.school);
    final firstGlyph = character.name.characters.isEmpty
        ? '?'
        : character.name.characters.first;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
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
        ),
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
      ],
    );

    return Opacity(
      opacity: character.isAlive ? 1.0 : 0.3,
      child: content,
    );
  }
}
