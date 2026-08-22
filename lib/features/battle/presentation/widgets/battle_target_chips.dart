import 'package:flutter/material.dart';

import '../../domain/battle_state.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../../../../shared/widgets/asset_fallback.dart';
import '../../../../shared/widgets/wuxia_image.dart';
import '../../../../shared/theme/combat_typography.dart';

/// 单体技待发态时,在技能格上方冒出的敌人快捷选择栏(存活敌人按 slotIndex 升序)。
class TargetChipStrip extends StatelessWidget {
  final List<BattleCharacter> enemies;
  final int? hoveredEnemyId;
  final void Function(int enemyId) onSelect;
  final void Function(int enemyId, bool hovering) onHover;

  const TargetChipStrip({
    super.key,
    required this.enemies,
    required this.hoveredEnemyId,
    required this.onSelect,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...enemies]
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            TargetChip(
              key: ValueKey('target_chip_${sorted[i].characterId}'),
              enemy: sorted[i],
              hovered: hoveredEnemyId == sorted[i].characterId,
              onTap: () => onSelect(sorted[i].characterId),
              onHover: (h) => onHover(sorted[i].characterId, h),
            ),
            if (i < sorted.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

/// 单个敌人选择 chip:小头像(iconPath,缺图走首字降级) + 细血条。
class TargetChip extends StatelessWidget {
  final BattleCharacter enemy;
  final bool hovered;
  final VoidCallback onTap;
  final void Function(bool hovering) onHover;

  const TargetChip({
    super.key,
    required this.enemy,
    required this.hovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final color = WuxiaColors.schoolColor(enemy.school);
    final firstGlyph = enemy.name.isEmpty ? '?' : enemy.name.substring(0, 1);
    final hasIcon = enemy.iconPath != null && enemy.iconPath!.isNotEmpty;
    final hpRatio = enemy.maxHp <= 0
        ? 0.0
        : (enemy.currentHp / enemy.maxHp).clamp(0.0, 1.0);
    final glyph = Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      color: const Color(0xFF302C26),
      child: Text(
        firstGlyph,
        style: TextStyle(
          fontSize: 16,
          color: Color.lerp(color, WuxiaUi.paper2, 0.62),
          fontFamily: BattleTypography.displayFamily,
          fontFamilyFallback: BattleTypography.displayFallback,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final content = Container(
      key: ValueKey('battle.targetChip.inkPlaque.${enemy.characterId}'),
      width: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF23A342B), Color(0xFA211F1B)],
        ),
        border: Border.all(
          color: hovered ? const Color(0xFFC09A55) : const Color(0xFF6D5940),
          width: hovered ? 1.6 : 1,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x73000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
          if (hovered)
            const BoxShadow(
              color: Color(0x52C09A55),
              blurRadius: 9,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x806D5940)),
            ),
            child: ClipRect(
              child: hasIcon
                  ? WuxiaImage(
                      enemy.iconPath!,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                      color: const Color(0xFFD7C6A2),
                      colorBlendMode: BlendMode.modulate,
                      errorBuilder: wuxiaAssetErrorBuilder(() => glyph),
                    )
                  : glyph,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            key: ValueKey('battle.targetChip.hpInk.${enemy.characterId}'),
            width: 40,
            height: 4,
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              color: Color(0xFF191714),
              border: Border(
                bottom: BorderSide(color: Color(0x806D5940), width: 0.5),
              ),
            ),
            child: FractionallySizedBox(
              widthFactor: hpRatio,
              child: const ColoredBox(color: Color(0xFF8A2B21)),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      button: true,
      label: enemy.name,
      value: UiStrings.battleTargetHealth(enemy.currentHp, enemy.maxHp),
      onTap: onTap,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: InkWell(
          onTap: onTap,
          customBorder: const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          mouseCursor: SystemMouseCursors.click,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.focused)
                ? const Color(0x33C09A55)
                : Colors.transparent;
          }),
          child: content,
        ),
      ),
    );
  }
}
