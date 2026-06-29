import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../application/offline_recap_detail.dart';
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
  }) : passiveMojianshi = null,
       passiveExperience = null,
       passiveAwayHours = null,
       passiveSettledHours = null,
       passiveIsCapped = null;

  /// M2 范围 B 被动离线告知卡（无 active 闭关时弹）。
  ///
  /// 与范围 A 不同：产出已在 settle 入库,此卡仅告知,无「前去收功」按钮
  /// （守反留存红线 §5.1）。复用 PaperPanel + PlaqueButton 水墨体例。
  const OfflineRecapCard.passive({
    super.key,
    required int mojianshi,
    required int experience,
    required double awayHours,
    required double settledHours,
    required bool isCapped,
    required this.onDismiss,
  }) : recap = null,
       onGoCollect = null,
       passiveMojianshi = mojianshi,
       passiveExperience = experience,
       passiveAwayHours = awayHours,
       passiveSettledHours = settledHours,
       passiveIsCapped = isCapped;

  final OfflineRecap? recap;
  final VoidCallback? onGoCollect;
  final VoidCallback onDismiss;

  final int? passiveMojianshi;
  final int? passiveExperience;
  final double? passiveAwayHours;
  final double? passiveSettledHours;
  final bool? passiveIsCapped;

  bool get _isPassive => passiveMojianshi != null;

  @override
  Widget build(BuildContext context) {
    if (_isPassive) return _buildPassive();
    final recap = this.recap!;
    final onGoCollect = this.onGoCollect!;
    final detail = OfflineRecapDetailFormatter.forRetreat(
      recap,
      itemNameOf: _itemNameOf,
    );
    final isCapped = recap.limitReason == OfflineRecapLimitReason.systemCap;
    final statusLine = isCapped
        ? UiStrings.offlineRecapMapCapped(recap.mapName)
        : recap.isComplete
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
            // P1-6:达系统上限 → 温和建议(不焦虑·守反留存红线)。
            if (isCapped) ...[
              const SizedBox(height: 4),
              const Text(
                UiStrings.offlineCappedAdvice,
                style: TextStyle(color: WuxiaUi.ink2, fontSize: 12),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              UiStrings.offlineRecapRewardOverview(
                recap.estimatedMojianshi,
                recap.estimatedSilver,
                recap.estimatedExperience,
              ),
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _BreakdownBlock(groups: detail.groups),
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
                  label: isCapped
                      ? UiStrings.offlineRecapCollectCapped
                      : UiStrings.offlineRecapGoCollect,
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
    final detail = OfflineRecapDetailFormatter.forPassive((
      mojianshi: passiveMojianshi!,
      experience: passiveExperience!,
      awayHours: passiveAwayHours!,
      settledHours: passiveSettledHours!,
      isCapped: passiveIsCapped!,
    ));
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
            const SizedBox(height: 10),
            Text(
              UiStrings.passiveRecapOverview(
                passiveMojianshi!,
                passiveExperience!,
              ),
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            // P1-6:被动挂机达系统上限 → 同样温和建议。
            if (passiveIsCapped!) ...[
              const SizedBox(height: 4),
              const Text(
                UiStrings.offlineCappedAdvice,
                style: TextStyle(color: WuxiaUi.ink2, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            _BreakdownBlock(groups: detail.groups),
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

  static String _itemNameOf(String defId) {
    if (!GameRepository.isLoaded) return defId;
    return GameRepository.instance.itemDefs[defId]?.name ?? defId;
  }
}

class _BreakdownBlock extends StatelessWidget {
  const _BreakdownBlock({required this.groups});

  final List<OfflineRecapDetailGroup> groups;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.34),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              UiStrings.offlineRecapBreakdownTitle,
              style: TextStyle(
                color: WuxiaUi.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final group in groups) _BreakdownGroup(group),
          ],
        ),
      ),
    );
  }
}

class _BreakdownGroup extends StatelessWidget {
  const _BreakdownGroup(this.group);

  final OfflineRecapDetailGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            group.title,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          for (final row in group.rows) _BreakdownRow(row),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: WuxiaUi.muted,
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }
}
