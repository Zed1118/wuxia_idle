import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../domain/inner_demon_panel.dart';

/// 心魔成长瓶颈面板(P0-3 ③,泛化自旧 InnerDemonBreakthroughBlocker)。
///
/// 纯渲染职责:按 [state] 显示 cleared / blocked / inProgress 三态。
/// 武圣常驻(由 caller `_BreakthroughBlockerSection` 决定显隐),
/// X/total 进度条数据单一真相源 = MainlineProgress.clearedStageIds。
/// stage 名由 caller 用 stageDefs 解后传入。「突破」CTA = onNavigate(导航至
/// InnerDemonScreen,不引新突破机制,进阶仍自动)。
class InnerDemonProgressPanel extends StatelessWidget {
  const InnerDemonProgressPanel({
    super.key,
    required this.state,
    required this.clearedCount,
    required this.totalCount,
    this.blockingStageName,
    this.nextStageName,
    this.onNavigate,
  });

  final InnerDemonPanelState state;
  final int clearedCount;
  final int totalCount;

  /// blocked 态拦截关名。
  final String? blockingStageName;

  /// inProgress 态下一关名。
  final String? nextStageName;

  /// 「突破」/「前往心魔境」CTA 回调(cleared 态不显 CTA)。
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0
        ? 0.0
        : (clearedCount / totalCount).clamp(0.0, 1.0);
    final isBlocked = state == InnerDemonPanelState.blocked;

    return Material(
      color: WuxiaColors.sidebar,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBlocked ? Icons.lock_outline : Icons.self_improvement,
                  size: 16,
                  color: isBlocked
                      ? WuxiaColors.resultHighlight
                      : WuxiaColors.textMuted,
                ),
                const SizedBox(width: 6),
                const Text(
                  UiStrings.innerDemonPanelTitle,
                  style: TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  UiStrings.innerDemonPanelProgress(clearedCount, totalCount),
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 6,
              backgroundColor: WuxiaColors.barTrack,
              valueColor: AlwaysStoppedAnimation<Color>(
                isBlocked
                    ? WuxiaColors.resultHighlight
                    : WuxiaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ..._body(),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() {
    switch (state) {
      case InnerDemonPanelState.cleared:
        return const [
          Text(
            UiStrings.innerDemonClearedLabel,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
        ];
      case InnerDemonPanelState.blocked:
        return [
          Text(
            UiStrings.innerDemonBlockedBody(blockingStageName ?? ''),
            style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
          if (onNavigate != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: PlaqueButton(
                  label: UiStrings.innerDemonBreakthroughCta,
                  onTap: onNavigate,
                  destructive: true,
                ),
              ),
            ),
          ],
        ];
      case InnerDemonPanelState.inProgress:
        return [
          if (nextStageName != null)
            Text(
              UiStrings.innerDemonNextLabel(nextStageName!),
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
              ),
            ),
          if (onNavigate != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: PlaqueButton(
                  label: UiStrings.breakthroughGoToInnerDemon,
                  onTap: onNavigate,
                ),
              ),
            ),
          ],
        ];
    }
  }
}
