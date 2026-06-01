import 'package:flutter/material.dart';

import '../domain/battle_state.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';

/// 胜负仪式全屏 overlay(出版美术 B1)。
/// 暗幕 + 印章符 + 金「胜」/绛红「败」大题字 + 副标题 + 统计 + 继续按钮。
/// 纯展示 widget;弹出由 battle_screen 的 showGeneralDialog 负责。
class VictoryOverlay extends StatelessWidget {
  final BattleResult result;
  final int totalDamage;
  final int critCount;
  final int totalTicks;
  final VoidCallback onContinue;

  const VictoryOverlay({
    super.key,
    required this.result,
    required this.totalDamage,
    required this.critCount,
    required this.totalTicks,
    required this.onContinue,
  });

  bool get _isVictory => result == BattleResult.leftWin;

  @override
  Widget build(BuildContext context) {
    final accent = _isVictory ? WuxiaColors.resultHighlight : WuxiaColors.gangMeng;
    final title = _isVictory ? UiStrings.victoryTitle : UiStrings.defeatTitle;
    final subtitle = _isVictory ? UiStrings.victorySubtitle : UiStrings.defeatSubtitle;

    return Container(
      color: const Color(0xB3000000), // 暗幕 black 70%
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 印章符
          Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: WuxiaColors.gangMeng,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text(UiStrings.sealGlyph,
                style: TextStyle(color: WuxiaColors.textPrimary,
                  fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          // 大题字
          Text(title, style: TextStyle(
            color: accent, fontSize: 96, fontWeight: FontWeight.bold,
            shadows: const [Shadow(blurRadius: 12, color: Color(0xCC000000), offset: Offset(2, 3))],
          )),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(width: 180, height: 1, color: WuxiaColors.border),
          const SizedBox(height: 16),
          Text(UiStrings.battleSummary(totalDamage, critCount, totalTicks),
            style: const TextStyle(color: WuxiaColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          // 继续按钮(金框)
          OutlinedButton(
            onPressed: onContinue,
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text(UiStrings.battleContinue,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
