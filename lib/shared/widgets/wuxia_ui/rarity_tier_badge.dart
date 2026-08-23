import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../battle_shared/enum_localizations.dart';
import '../../strings.dart';
import '../../theme/wuxia_tokens.dart';

/// 人物资质的谱牒印鉴。只负责已有档位与出生点数的呈现，不计算档位。
class RarityTierBadge extends StatelessWidget {
  const RarityTierBadge({
    super.key,
    required this.tier,
    required this.birthTotal,
    this.compact = false,
  });

  final RarityTier tier;
  final int birthTotal;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tierName = EnumL10n.rarityTier(tier);
    final label = UiStrings.rarityTierWithTotal(tierName, birthTotal);
    final colors = _RarityTierStyle.forTier(tier);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 7, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 9, vertical: 5);

    return Semantics(
      container: true,
      button: false,
      label: '$label，出生点数 $birthTotal',
      child: CustomPaint(
        painter: _RarityFiberPainter(
          ink: colors.ink,
          pattern: colors.pattern,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colors.paper,
            border: Border.all(color: colors.ink, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SealMark(color: colors.seal, compact: compact),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: compact ? 11 : 12,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SealMark extends StatelessWidget {
  const _SealMark({required this.color, required this.compact});

  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: compact ? 16 : 18,
        height: compact ? 16 : 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: WuxiaUi.ink, width: 0.7),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          '鉴',
          style: TextStyle(
            color: WuxiaUi.paper,
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _RarityFiberPainter extends CustomPainter {
  const _RarityFiberPainter({required this.ink, required this.pattern});

  final Color ink;
  final int pattern;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink.withValues(alpha: 0.08)
      ..strokeWidth = 0.6;
    for (var i = 0; i < 3; i++) {
      final y = 5.0 + i * 7 + pattern;
      canvas.drawLine(Offset(28, y), Offset(size.width - 3, y + 2), paint);
    }
    if (pattern >= 3) {
      final cloud = Path()
        ..moveTo(size.width - 35, 3)
        ..quadraticBezierTo(size.width - 24, 8, size.width - 14, 3)
        ..quadraticBezierTo(size.width - 8, 0, size.width - 3, 5);
      canvas.drawPath(cloud, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RarityFiberPainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.pattern != pattern;
}

class _RarityTierStyle {
  const _RarityTierStyle({
    required this.ink,
    required this.paper,
    required this.seal,
    required this.pattern,
  });

  final Color ink;
  final Color paper;
  final Color seal;
  final int pattern;

  static _RarityTierStyle forTier(RarityTier tier) => switch (tier) {
        RarityTier.yongCai => const _RarityTierStyle(
            ink: Color(0xFF51483D),
            paper: Color(0xFFE4D9C4),
            seal: Color(0xFF706458),
            pattern: 0,
          ),
        RarityTier.xunChang => const _RarityTierStyle(
            ink: Color(0xFF4A514B),
            paper: Color(0xFFE6DEC9),
            seal: Color(0xFF667269),
            pattern: 1,
          ),
        RarityTier.biaoZhun => const _RarityTierStyle(
            ink: Color(0xFF3E4D4A),
            paper: Color(0xFFE8DFC8),
            seal: Color(0xFF596F68),
            pattern: 2,
          ),
        RarityTier.ziYou => const _RarityTierStyle(
            ink: Color(0xFF604C39),
            paper: Color(0xFFE9DEC0),
            seal: Color(0xFF816642),
            pattern: 3,
          ),
        RarityTier.tianCai => const _RarityTierStyle(
            ink: Color(0xFF63352D),
            paper: Color(0xFFE9D8BA),
            seal: Color(0xFF8A4A3A),
            pattern: 4,
          ),
        RarityTier.jueShi => const _RarityTierStyle(
            ink: Color(0xFF5C3B2A),
            paper: Color(0xFFE9D8B7),
            seal: Color(0xFF8A2B21),
            pattern: 5,
          ),
      };
}
