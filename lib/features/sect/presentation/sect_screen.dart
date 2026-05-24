import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/colors.dart';
import '../application/sect_providers.dart';
import '../domain/sect.dart';
import '../domain/sect_event.dart';
import 'widgets/sect_event_dialog.dart';

/// 门派事务屏(1.0 P3.4 §12.1,Batch 2.3 nightshift T16 · spec §5)。
///
/// 三段布局:
/// - 顶部:`sect_name` / `sectLevel` 1-7 沿七阶 / `sectReputation` 0-100 LinearProgressIndicator
/// - 中部:active SectEvent list(`status == pending` · 红点 + 「应战」CTA → 弹 [SectEventDialog])
/// - 底部:history tab(`status == resolved | expired` · 灰色显示 + reputationDelta)
///
/// **Demo 数据源**:[sectStateProvider] StateNotifier 内存 state。真 Isar 持久化
/// 见 [sectStateProvider] 类注释挂账。
class SectScreen extends ConsumerWidget {
  const SectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sectStateProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: WuxiaColors.background,
        appBar: AppBar(
          title: const Text('门派事务'),
          backgroundColor: WuxiaColors.sidebar,
          foregroundColor: WuxiaColors.textPrimary,
          bottom: const TabBar(
            tabs: [Tab(text: '当前事件'), Tab(text: '历史记录')],
            labelColor: WuxiaColors.textPrimary,
            unselectedLabelColor: WuxiaColors.textMuted,
            indicatorColor: WuxiaColors.hpHigh,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _SectHeader(sect: state.sect),
              const Divider(color: WuxiaColors.border, height: 1),
              Expanded(
                child: TabBarView(
                  children: [
                    _ActiveEventList(events: state.activeEvents),
                    _HistoricalEventList(events: state.historicalEvents),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectHeader extends StatelessWidget {
  const _SectHeader({required this.sect});
  final Sect sect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                sect.name,
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: WuxiaColors.panel,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: WuxiaColors.border),
                ),
                child: Text(
                  '等阶 ${sect.sectLevel}',
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '声望',
                style:
                    TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: (sect.sectReputation / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: WuxiaColors.panel,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      WuxiaColors.hpHigh),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${sect.sectReputation} / 100',
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '累计胜场 ${sect.totalWins}',
            style:
                const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActiveEventList extends StatelessWidget {
  const _ActiveEventList({required this.events});
  final List<SectEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          '当前无门派事件',
          style: TextStyle(color: WuxiaColors.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: events.length,
      itemBuilder: (ctx, i) {
        final e = events[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ActiveEventRow(event: e),
        );
      },
    );
  }
}

class _ActiveEventRow extends StatelessWidget {
  const _ActiveEventRow({required this.event});
  final SectEvent event;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WuxiaColors.sidebar,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => SectEventDialog(event: event),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WuxiaColors.border),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.circle, color: WuxiaColors.hpLow, size: 10),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _typeLabel(event.type),
                      style: const TextStyle(
                        color: WuxiaColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '触发 · ${_formatDate(event.triggeredAt)}',
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: WuxiaColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoricalEventList extends StatelessWidget {
  const _HistoricalEventList({required this.events});
  final List<SectEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          '尚无历史记录',
          style: TextStyle(color: WuxiaColors.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: events.length,
      itemBuilder: (ctx, i) {
        final e = events[i];
        final delta = e.reputationDelta ?? 0;
        final deltaStr = delta >= 0 ? '+$delta' : '$delta';
        final color = delta >= 0 ? WuxiaColors.hpHigh : WuxiaColors.hpLow;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: WuxiaColors.sidebar,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: WuxiaColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_typeLabel(e.type)} · ${_statusLabel(e.status)}',
                        style: const TextStyle(
                          color: WuxiaColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(e.resolvedAt ?? e.triggeredAt),
                        style: const TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '声望 $deltaStr',
                  style: TextStyle(color: color, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _typeLabel(SectEventType type) {
  switch (type) {
    case SectEventType.tournament:
      return '比武大会';
    case SectEventType.mission:
      return '弟子任务';
    case SectEventType.crisis:
      return '门派危机';
  }
}

String _statusLabel(SectEventStatus status) {
  switch (status) {
    case SectEventStatus.pending:
      return '待处理';
    case SectEventStatus.resolved:
      return '已结算';
    case SectEventStatus.expired:
      return '已过期';
  }
}

String _formatDate(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
