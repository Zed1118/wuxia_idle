import 'package:flutter/material.dart';

import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';

/// 江湖声望 7 阶 chip(P1.2 §4 GDD §12.2)。
///
/// 颜色梯度沿 GDD §5.2 七阶语义:
///   学徒(声名狼藉)灰 → 三流(恶名)橘红 → 二流(默默无闻)浅灰 →
///   一流(薄有微名)青 → 绝顶(侠名初显)金 → 宗师(声振江湖)金红 →
///   武圣(天下闻名)朱砂。
///
/// label 走 [UiStrings.reputationTier*],不在代码硬编中文(§5.6)。
class ReputationTierChip extends StatelessWidget {
  const ReputationTierChip({
    super.key,
    required this.tier,
    required this.value,
  });

  /// 7 阶枚举名(xueTu / sanLiu / erLiu / yiLiu / jueDing / zongShi / wuSheng),
  /// 走 [ReputationService.tierOf] 派生。
  final String tier;

  /// 当前 value [-100, +100],显在 chip 右侧。
  final int value;

  Color _color() {
    switch (tier) {
      case 'xueTu':
        return WuxiaColors.textMuted;
      case 'sanLiu':
        return WuxiaColors.sealCrimson;
      case 'erLiu':
        return WuxiaColors.textSecondary;
      case 'yiLiu':
        return WuxiaColors.internalForce;
      case 'jueDing':
        return WuxiaColors.resultHighlight;
      case 'zongShi':
        return WuxiaColors.bossFrame;
      case 'wuSheng':
        return WuxiaColors.gangMeng;
      default:
        return WuxiaColors.textMuted;
    }
  }

  String _label() {
    switch (tier) {
      case 'xueTu':
        return UiStrings.reputationTierXueTu;
      case 'sanLiu':
        return UiStrings.reputationTierSanLiu;
      case 'erLiu':
        return UiStrings.reputationTierErLiu;
      case 'yiLiu':
        return UiStrings.reputationTierYiLiu;
      case 'jueDing':
        return UiStrings.reputationTierJueDing;
      case 'zongShi':
        return UiStrings.reputationTierZongShi;
      case 'wuSheng':
        return UiStrings.reputationTierWuSheng;
      default:
        return UiStrings.reputationTierErLiu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.68), width: 0.9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          '${_label()} · $value',
          style: TextStyle(
            color: color == WuxiaColors.textMuted
                ? WuxiaColors.textSecondary
                : color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
