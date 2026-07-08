import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/currency_pill.dart';
import '../../../shared/widgets/wuxia_ui/light_paper_panel.dart';
import '../application/sweep_readiness_providers.dart';
import '../domain/sweep_readiness.dart';

class SweepReadinessPill extends ConsumerWidget {
  const SweepReadinessPill({
    super.key,
    this.tone = CurrencyPillTone.paper,
    this.compact = false,
  });

  final CurrencyPillTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sweepReadinessStatusProvider);
    final isDark = tone == CurrencyPillTone.dark;
    final textColor = isDark ? WuxiaUi.paper : WuxiaUi.ink;
    final borderColor = isDark
        ? WuxiaUi.qing.withValues(alpha: 0.58)
        : WuxiaUi.qing.withValues(alpha: 0.42);
    final fillColor = isDark
        ? WuxiaUi.ink.withValues(alpha: 0.68)
        : WuxiaUi.paper.withValues(alpha: 0.70);

    final text = async.when(
      data: (state) =>
          UiStrings.sweepReadinessShort(state.points, state.config.maxPoints),
      loading: () => UiStrings.sweepReadinessLoading,
      error: (_, _) => UiStrings.sweepReadinessUnavailable,
    );

    return Tooltip(
      message: async.maybeWhen(
        data: (state) => _readinessTooltip(state),
        orElse: () => text,
      ),
      child: DecoratedBox(
        key: const Key('sweep_readiness_pill'),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 11,
            vertical: compact ? 5 : 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                size: compact ? 16 : 18,
                color: isDark ? WuxiaUi.gold : WuxiaUi.qing,
              ),
              SizedBox(width: compact ? 6 : 8),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: compact ? 12.5 : 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: compact ? 0.6 : 1.0,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SweepReadinessPanel extends ConsumerWidget {
  const SweepReadinessPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sweepReadinessStatusProvider);
    return LightPaperPanel(
      padding: const EdgeInsets.all(14),
      paperOpacity: 0.14,
      child: async.when(
        data: _ReadinessPanelContent.new,
        loading: () => const _ReadinessPanelFallback(
          title: UiStrings.sweepReadinessPanelTitle,
          body: UiStrings.sweepReadinessLoading,
        ),
        error: (_, _) => const _ReadinessPanelFallback(
          title: UiStrings.sweepReadinessPanelTitle,
          body: UiStrings.sweepReadinessUnavailable,
        ),
      ),
    );
  }
}

class _ReadinessPanelContent extends StatelessWidget {
  const _ReadinessPanelContent(this.state);

  final SweepReadinessState state;

  @override
  Widget build(BuildContext context) {
    final max = state.config.maxPoints;
    final progress = max <= 0 ? 1.0 : (state.points / max).clamp(0.0, 1.0);
    final nextLine = _nextRecoveryLine(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_fire_department_outlined,
              size: 21,
              color: WuxiaUi.qing,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                UiStrings.sweepReadinessPanelTitle,
                style: TextStyle(
                  color: WuxiaUi.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
            Text(
              UiStrings.sweepReadinessShort(state.points, max),
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress,
            backgroundColor: WuxiaUi.ink.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(WuxiaUi.qing),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          nextLine == null
              ? UiStrings.sweepReadinessPanelBody
              : '${UiStrings.sweepReadinessPanelBody} · $nextLine',
          style: const TextStyle(
            color: WuxiaUi.muted,
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReadinessPanelFallback extends StatelessWidget {
  const _ReadinessPanelFallback({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.local_fire_department_outlined,
          size: 21,
          color: WuxiaUi.qing,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: WuxiaUi.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          body,
          style: const TextStyle(
            color: WuxiaUi.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _readinessTooltip(SweepReadinessState state) {
  final nextLine = _nextRecoveryLine(state);
  if (nextLine == null) {
    return UiStrings.sweepReadinessPanelBody;
  }
  return '${UiStrings.sweepReadinessPanelBody} · $nextLine';
}

String? _nextRecoveryLine(SweepReadinessState state) {
  final nextRecoveryAt = state.nextRecoveryAt;
  if (nextRecoveryAt == null) return UiStrings.sweepReadinessFull;
  final minutes = nextRecoveryAt.difference(DateTime.now()).inMinutes + 1;
  return UiStrings.sweepReadinessNextRecoveryMinutes(minutes.clamp(1, 9999));
}
