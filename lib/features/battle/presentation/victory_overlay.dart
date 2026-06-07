import 'package:flutter/material.dart';

import '../domain/battle_state.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';

/// 胜负仪式全屏 overlay(出版美术 B1)。
/// 暗幕 + 印章符 + 金「勝」/绛红「敗」大题字 + 副标题 + 统计 + 继续按钮。
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
    final accent = _isVictory
        ? WuxiaColors.resultHighlight
        : WuxiaColors.gangMeng;
    final title = _isVictory ? UiStrings.victoryTitle : UiStrings.defeatTitle;
    final subtitle = _isVictory
        ? UiStrings.victorySubtitle
        : UiStrings.defeatSubtitle;

    return Container(
      // P0-2：径向 vignette 暗角，中心淡 → 四周暗，战场单位仍可读（不整屏压暗）。
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 0.9,
          colors: [Color(0x33000000), Color(0xCC000000)],
          stops: [0.45, 1.0],
        ),
      ),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 印章符
            Transform.rotate(
              angle: -0.08,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      WuxiaUi.sealRed,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: WuxiaColors.gangMeng,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const Text(
                      UiStrings.sealGlyph,
                      style: TextStyle(
                        color: WuxiaColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 大题字
            Text(
              title,
              style: TextStyle(
                color: accent,
                fontSize: 96,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    blurRadius: 12,
                    color: Color(0xCC000000),
                    offset: Offset(2, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            CeremonyImagePanel(
              assetPath: _isVictory
                  ? WuxiaUi.ceremonyVictoryTag
                  : WuxiaUi.ceremonyFailureInk,
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
              borderColor: accent.withValues(alpha: 0.48),
              imageOpacity: 0.3,
              paperVeilOpacity: 0.78,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Image.asset(
                    WuxiaUi.inkDivider,
                    height: 12,
                    fit: BoxFit.fill,
                    errorBuilder: (_, _, _) => Container(
                      width: 180,
                      height: 1,
                      color: WuxiaUi.ink.withValues(alpha: 0.42),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    UiStrings.battleSummary(totalDamage, critCount, totalTicks),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: WuxiaUi.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  PlaqueButton(
                    label: UiStrings.battleContinue,
                    primary: true,
                    onTap: onContinue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
