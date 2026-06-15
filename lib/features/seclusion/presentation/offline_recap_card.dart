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
  })  : passiveMojianshi = null,
        passiveExperience = null,
        passiveAwayHours = null;

  /// M2 范围 B 被动离线告知卡（无 active 闭关时弹）。
  ///
  /// 与范围 A 不同：产出已在 settle 入库,此卡仅告知,无「前去收功」按钮
  /// （守反留存红线 §5.1）。复用 PaperPanel + PlaqueButton 水墨体例。
  const OfflineRecapCard.passive({
    super.key,
    required int mojianshi,
    required int experience,
    required double awayHours,
    required this.onDismiss,
  })  : recap = null,
        onGoCollect = null,
        passiveMojianshi = mojianshi,
        passiveExperience = experience,
        passiveAwayHours = awayHours;

  final OfflineRecap? recap;
  final VoidCallback? onGoCollect;
  final VoidCallback onDismiss;

  final int? passiveMojianshi;
  final int? passiveExperience;
  final double? passiveAwayHours;

  bool get _isPassive => passiveMojianshi != null;

  @override
  Widget build(BuildContext context) {
    if (_isPassive) return _buildPassive();
    final recap = this.recap!;
    final onGoCollect = this.onGoCollect!;
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

  /// 范围 B 被动告知卡渲染（Task 6 水墨精致变体）。
  ///
  /// 产出已在 settle 时自动入库，此卡纯告知，无「前去收功/领取」按钮。
  Widget _buildPassive() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: PaperPanel(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              UiStrings.passiveRecapTitle,
              style: TextStyle(
                color: WuxiaUi.ink,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              UiStrings.passiveRecapBody(
                passiveAwayHours!.floor(),
                passiveMojianshi!,
                passiveExperience!,
              ),
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 13,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PlaqueButton(
                  label: UiStrings.passiveRecapDismiss,
                  onTap: onDismiss,
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
