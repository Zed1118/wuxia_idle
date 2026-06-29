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
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ReputationRow(
                reputation: list[i],
                tier: svc.tierOf(list[i].value),
              ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WuxiaColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              reputation.factionId,
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ReputationTierChip(tier: tier, value: reputation.value),
        ],
      ),
    );
  }
}
