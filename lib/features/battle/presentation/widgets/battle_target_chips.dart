import 'package:flutter/material.dart';

import '../../domain/battle_state.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/widgets/asset_fallback.dart';
import '../../../../shared/widgets/wuxia_image.dart';
import '../hp_bar.dart';

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
    final glyph = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      color: WuxiaColors.avatarFill,
      child: Text(
        firstGlyph,
        style: TextStyle(
          fontSize: 16,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: WuxiaColors.sidebar,
            border: Border.all(
              color: hovered ? color : WuxiaColors.border,
              width: hovered ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: hasIcon
                      ? WuxiaImage(
                          enemy.iconPath!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: wuxiaAssetErrorBuilder(() => glyph),
                        )
                      : glyph,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 40,
                child: HpBar(
                  current: enemy.currentHp,
                  max: enemy.maxHp,
                  height: 4,
                  showLabel: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
