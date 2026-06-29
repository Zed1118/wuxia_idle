import 'package:flutter/material.dart';

import '../domain/battle_state.dart';
import '../domain/battle_diagnosis.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../inventory/presentation/post_battle_healing_panel.dart';

/// 胜负仪式全屏 overlay(出版美术 B1)。
/// 暗幕 + 印章符 + 金「勝」/绛红「敗」大题字 + 副标题 + 统计 + 继续按钮。
/// 纯展示 widget;弹出由 battle_screen 的 showGeneralDialog 负责。
class VictoryOverlay extends StatelessWidget {
  final BattleResult result;
  final int totalDamage;
  final int critCount;
  final int totalTicks;
  final VoidCallback onContinue;

  /// 败北诊断（胜利为 null）。null 时退化为无诊断块（仅题字+统计）。
  final BattleDiagnosis? diagnosis;

  /// 诊断建议跳转回调（overlay 保持纯展示，导航交给 caller）。
  final void Function(DiagnosisJumpTarget target)? onJump;

  const VictoryOverlay({
    super.key,
    required this.result,
    required this.totalDamage,
    required this.critCount,
    required this.totalTicks,
    required this.onContinue,
    this.diagnosis,
    this.onJump,
  });

  bool get _isVictory => result == BattleResult.leftWin;

  static String _jumpLabel(DiagnosisJumpTarget t) => switch (t) {
    DiagnosisJumpTarget.skills => UiStrings.diagJumpSkills,
    DiagnosisJumpTarget.equipment => UiStrings.diagJumpEquipment,
    DiagnosisJumpTarget.cultivation => UiStrings.diagJumpCultivation,
    DiagnosisJumpTarget.roster => UiStrings.diagJumpRoster,
    DiagnosisJumpTarget.supplies => UiStrings.diagJumpSupplies,
  };

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
            // 2026-06-25:移除大题字上方那枚孤立的「武」小印章——勝/敗 大字本身即焦点,
            // 小印章渲染偏弱(图常缺失只剩文字)、悬空显突兀。胜利另有 VictorySealFlash
            // 仪式承担印章高光,此处不重复。
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
                  // 战报失败诊断三段式（spec 2026-06-15-battle-report-diagnosis）。
                  if (!_isVictory && diagnosis != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      UiStrings.defeatShortfallLabel(
                        UiStrings.defeatShortfallName(
                          diagnosis!.shortfall.name,
                        ),
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: WuxiaUi.ink.withValues(alpha: 0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      diagnosis!.primaryCause,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final line in diagnosis!.dataLines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          line,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: WuxiaUi.ink.withValues(alpha: 0.82),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    for (final s in diagnosis!.suggestions)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: s.jump == null
                            ? Text(
                                s.text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: WuxiaUi.ink.withValues(alpha: 0.78),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              )
                            : OutlinedButton(
                                onPressed: () => onJump?.call(s.jump!),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accent,
                                  side: BorderSide(
                                    color: accent.withValues(alpha: 0.55),
                                  ),
                                ),
                                child: Text(_jumpLabel(s.jump!)),
                              ),
                      ),
                  ],
                  const SizedBox(height: 10),
                  // 2026-06-25:原 inkDivider 图常缺失/偏弱(只剩淡线+小卷纹)。换成
                  // 两端淡出的细水墨横线,克制且不依赖资源加载,显得是有意的分隔而非破图。
                  Center(
                    child: Container(
                      width: 160,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            WuxiaUi.ink.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
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
                  const PostBattleHealingPanel(),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 128,
                    height: 42,
                    child: PlaqueButton(
                      label: UiStrings.battleContinue,
                      primary: true,
                      onTap: onContinue,
                    ),
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
