import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../application/jianghu_providers.dart';
import '../domain/reputation.dart';
import 'widgets/reputation_tier_chip.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

/// 江湖声望面板(P1.2 §4 GDD §12.2)。
///
/// 沿 [LineagePanelScreen] 三段式卡片体例:AppBar + ListView 卡片 + 兜底空态。
/// Demo 单 save · playerId=1,走 [reputationsForCurrentPlayerProvider]。
///
/// **不渲染门派显示名**(factions.yaml 当前未进 NumbersConfig,1.0 P5+ wire);
/// 直接显 [Reputation.factionId] 字符串 id + value chip。
class ReputationPanelScreen extends ConsumerWidget {
  const ReputationPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reputationsForCurrentPlayerProvider);
    final svc = ref.watch(reputationServiceProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        title: const Text(UiStrings.reputationPanelTitle),
        leading: Navigator.of(context).canPop()
            ? BackButton(onPressed: () => Navigator.of(context).pop())
            : null,
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: InkLoadingIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              '${UiStrings.reputationPanelLoadError}: $e',
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (list) {
            if (list.isEmpty || svc == null) {
              return const Center(
                child: Text(
                  UiStrings.reputationPanelEmpty,
                  style: TextStyle(color: WuxiaColors.textSecondary),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth >= 920
                    ? 860.0
                    : constraints.maxWidth;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: _ReputationRow(
                        reputation: list[i],
                        tier: svc.tierOf(list[i].value),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReputationRow extends StatelessWidget {
  const _ReputationRow({required this.reputation, required this.tier});

  final Reputation reputation;
  final String tier;

  @override
  Widget build(BuildContext context) {
    final value = reputation.value.clamp(-100, 100);
    final normalized = (value + 100) / 200;
    final accent = value > 0
        ? WuxiaColors.hpHigh
        : value < 0
        ? WuxiaColors.sealCrimson
        : WuxiaColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [accent.withValues(alpha: 0.12), WuxiaColors.panel],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reputation.factionId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WuxiaColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ReputationTierChip(tier: tier, value: reputation.value),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: normalized,
                    backgroundColor: WuxiaColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
