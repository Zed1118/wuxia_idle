import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/battle_shared/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/portrait_frame.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';
import '../../../shared/widgets/wuxia_ui/light_paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../activity/domain/activity_occupancy.dart';
import '../application/disciple_scheduling_provider.dart';
import '../domain/disciple_scheduling_summary.dart';

/// 二阶段 U08 门人调度当前态页。
///
/// 这里不再提供全局三席编成。页面只呈现当代门人的真实去向，亲战、重打与
/// 差遣参与者仍由各活动生产入口逐次选择。
class DiscipleSchedulingScreen extends ConsumerWidget {
  const DiscipleSchedulingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(discipleSchedulingProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.discipleSchedulingTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: InkLoadingIndicator()),
          error: (_, _) => _LoadError(
            onRetry: () => ref.invalidate(discipleSchedulingProvider),
          ),
          data: (summary) => _SchedulingBody(summary: summary),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: IntrinsicWidth(
          child: LightPaperPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  UiStrings.discipleSchedulingLoadError,
                  style: TextStyle(color: WuxiaUi.ink, fontSize: 14),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onRetry,
                  child: const Text(UiStrings.errorRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SchedulingBody extends StatelessWidget {
  const _SchedulingBody({required this.summary});

  final DiscipleSchedulingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const LightPaperPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(UiStrings.discipleSchedulingSectionTitle),
                  SizedBox(height: 8),
                  Text(
                    UiStrings.discipleSchedulingPerActivityHint,
                    style: TextStyle(
                      color: WuxiaUi.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < summary.members.length; index++) ...[
              if (index > 0) const SizedBox(height: 10),
              IntrinsicHeight(
                child: LightPaperPanel(
                  key: ValueKey(
                    'disciple-scheduling-member-'
                    '${summary.members[index].characterId}',
                  ),
                  child: _MemberRow(member: summary.members[index]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final DiscipleSchedulingMember member;

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(member);
    final statusColor = _statusColorFor(member);
    return Row(
      children: [
        PortraitFrame(
          portraitPath: member.portraitPath,
          placeholderText: member.name,
          size: 56,
          borderColor: member.isLeader ? WuxiaUi.gold : WuxiaUi.ink2,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WuxiaUi.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (member.isLeader) ...[
                    const SizedBox(width: 8),
                    const _StatusTag(
                      label: UiStrings.discipleSchedulingLeaderTag,
                      color: WuxiaUi.goldOnPaper,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                EnumL10n.realm(member.realmTier, member.realmLayer),
                style: const TextStyle(color: WuxiaUi.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _StatusTag(label: status, color: statusColor),
      ],
    );
  }
}

String _statusFor(DiscipleSchedulingMember member) {
  if (!member.isAlive) return UiStrings.discipleSchedulingUnavailable;
  return switch (member.activity) {
    ActivityKind.retreat => UiStrings.discipleSchedulingActivityRetreat,
    ActivityKind.expedition => UiStrings.discipleSchedulingActivityExpedition,
    ActivityKind.bossGauntlet => UiStrings.discipleSchedulingActivityGauntlet,
    ActivityKind.lightFoot => UiStrings.mainMenuLightFoot,
    ActivityKind.massBattle => UiStrings.mainMenuMassBattle,
    null => UiStrings.discipleSchedulingAvailable,
  };
}

Color _statusColorFor(DiscipleSchedulingMember member) {
  if (!member.isAlive) return WuxiaUi.muted;
  return member.activity == null ? WuxiaUi.qing : WuxiaUi.jiang;
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
