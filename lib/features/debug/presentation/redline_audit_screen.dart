import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../application/redline_audit.dart';

class RedlineAuditScreen extends StatelessWidget {
  const RedlineAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = GameRepository.instanceOrNull;
    if (repo == null) {
      return const Scaffold(
        body: Center(child: Text(UiStrings.redlineAuditRepoNotLoaded)),
      );
    }

    final report = buildRedlineAuditReport(repo);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.redlineAuditScreenTitle),
        backgroundColor: WuxiaUi.paper,
        foregroundColor: WuxiaUi.ink,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryBanner(report: report),
          const SizedBox(height: 12),
          for (final item in report.items) ...[
            _AuditTile(item: item),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.report});

  final RedlineAuditReport report;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(report.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WuxiaUi.paper,
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(report.status), color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              UiStrings.redlineAuditSummary(
                statusLabel(report.status),
                report.items.length,
              ),
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.item});

  final RedlineAuditItem item;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WuxiaUi.paper,
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(item.status), color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: WuxiaUi.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                statusLabel(item.status),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _Metric(
                label: UiStrings.redlineAuditMetricObserved,
                value: item.observed.toString(),
              ),
              _Metric(
                label: UiStrings.redlineAuditMetricLimit,
                value: item.limit.toString(),
              ),
              _Metric(
                label: UiStrings.redlineAuditMetricHeadroom,
                value: item.headroom.toString(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            UiStrings.redlineAuditSourceLine(item.source),
            style: const TextStyle(color: WuxiaUi.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            item.note,
            style: const TextStyle(color: WuxiaUi.ink, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 104),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: WuxiaUi.muted, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(RedlineAuditStatus status) => switch (status) {
  RedlineAuditStatus.pass => const Color(0xFF2E7D32),
  RedlineAuditStatus.warn => const Color(0xFFB26A00),
  RedlineAuditStatus.fail => const Color(0xFF9D2F2F),
};

IconData _statusIcon(RedlineAuditStatus status) => switch (status) {
  RedlineAuditStatus.pass => Icons.check_circle_outline,
  RedlineAuditStatus.warn => Icons.warning_amber_rounded,
  RedlineAuditStatus.fail => Icons.error_outline,
};
