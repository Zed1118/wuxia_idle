import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../application/offline_recap_service.dart';

/// M2 离线收益汇总「归来」卡。
///
/// 纯渲染 [OfflineRecap] 数据 + 触发 [onGoCollect] / [onDismiss] 回调;
/// 导航（去收功跳 ActiveRetreatScreen）由调用方在回调里处理,卡本身无副作用,
/// 故可纯 widget test。水墨样式复用 [PaperPanel] + [PlaqueButton]。
class OfflineRecapCard extends StatelessWidget {
  const OfflineRecapCard({
    super.key,
    required this.recap,
    required this.onGoCollect,
    required this.onDismiss,
  });

  final OfflineRecap recap;
  final VoidCallback onGoCollect;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final statusLine = recap.isComplete
        ? UiStrings.offlineRecapMapComplete(recap.mapName)
        : UiStrings.offlineRecapMapProgress(
            recap.mapName,
            (recap.progressPct * 100).round(),
          );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: PaperPanel(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              UiStrings.offlineRecapTitle,
              style: TextStyle(
                color: WuxiaUi.ink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              UiStrings.offlineRecapAwayLine(recap.awayHours.floor()),
              style: const TextStyle(color: WuxiaUi.ink, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              statusLine,
              style: const TextStyle(color: WuxiaUi.ink, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              UiStrings.offlineRecapRewardLine(
                recap.estimatedMojianshi,
                recap.estimatedExperience,
              ),
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PlaqueButton(
                  label: UiStrings.offlineRecapDismiss,
                  onTap: onDismiss,
                ),
                const SizedBox(width: 10),
                PlaqueButton(
                  label: UiStrings.offlineRecapGoCollect,
                  onTap: onGoCollect,
                  primary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
