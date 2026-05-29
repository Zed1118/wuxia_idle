import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/battle_providers.dart';
import '../../../core/domain/character.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/sect_member_service.dart';
import '../application/sect_providers.dart';
import '../application/territory_service.dart';
import '../domain/sect.dart';
import '../domain/sect_event.dart';
import '../domain/sect_rank.dart';
import '../domain/territory_def.dart';
import 'widgets/sect_event_dialog.dart';

/// 门派事务屏(1.0 P3.4 §12.1,Batch 2.3 nightshift T16 · spec §5)。
///
/// 三段布局:
/// - 顶部:`sect_name` / `sectLevel` 1-7 沿七阶 / `sectReputation` 0-100 LinearProgressIndicator
/// - 中部:active SectEvent list(`status == pending` · 红点 + 「应战」CTA → 弹 [SectEventDialog])
/// - 底部:history tab(`status == resolved | expired` · 灰色显示 + reputationDelta)
///
/// **数据源**:T19b 起切到 Isar 真持久化 — `currentSectProvider` StreamProvider
/// 读 `isar.sects.watchObject(1)` + `activeSectEventsProvider` / `historicalSectEventsProvider`
/// 各走 status filter watch。AsyncValue 三态(data / loading / error)。
class SectScreen extends ConsumerWidget {
  const SectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectAsync = ref.watch(currentSectProvider);
    final activeAsync = ref.watch(activeSectEventsProvider);
    final historyAsync = ref.watch(historicalSectEventsProvider);

    return sectAsync.when(
      loading: () => const Scaffold(
        backgroundColor: WuxiaColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: WuxiaColors.background,
        appBar: AppBar(
          title: const Text(UiStrings.sectScreenTitle),
          backgroundColor: WuxiaColors.sidebar,
          foregroundColor: WuxiaColors.textPrimary,
        ),
        body: Center(
          child: Text(
            UiStrings.sectLoadFailed(e),
            style: const TextStyle(color: WuxiaColors.textMuted),
          ),
        ),
      ),
      data: (sect) {
        if (sect == null) {
          return Scaffold(
            backgroundColor: WuxiaColors.background,
            appBar: AppBar(
              title: const Text(UiStrings.sectScreenTitle),
              backgroundColor: WuxiaColors.sidebar,
              foregroundColor: WuxiaColors.textPrimary,
            ),
            body: const Center(
              child: Text(
                '门派尚未创建',
                style: TextStyle(color: WuxiaColors.textMuted),
              ),
            ),
          );
        }
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: WuxiaColors.background,
            appBar: AppBar(
              title: const Text(UiStrings.sectScreenTitle),
              backgroundColor: WuxiaColors.sidebar,
              foregroundColor: WuxiaColors.textPrimary,
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: UiStrings.sectTabEventsActive),
                  Tab(text: UiStrings.sectTabEventsHistory),
                  Tab(text: UiStrings.sectTabMembers),
                  Tab(text: UiStrings.sectTabTerritories),
                ],
                labelColor: WuxiaColors.textPrimary,
                unselectedLabelColor: WuxiaColors.textMuted,
                indicatorColor: WuxiaColors.hpHigh,
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  _SectHeader(sect: sect),
                  const Divider(color: WuxiaColors.border, height: 1),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ActiveEventList(
                          events: (activeAsync.asData?.value ?? const <SectEvent>[]),
                          sect: sect,
                        ),
                        _HistoricalEventList(
                          events: (historyAsync.asData?.value ?? const <SectEvent>[]),
                        ),
                        _MemberList(sect: sect),
                        _TerritoryGrid(sect: sect),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
  const _ActiveEventList({required this.events, required this.sect});
  final List<SectEvent> events;
  final Sect sect;

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
          child: _ActiveEventRow(event: e, sect: sect),
        );
      },
    );
  }
}

class _ActiveEventRow extends StatelessWidget {
  const _ActiveEventRow({required this.event, required this.sect});
  final SectEvent event;
  final Sect sect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WuxiaColors.sidebar,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => SectEventDialog(event: event, sect: sect),
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

class _MemberList extends ConsumerWidget {
  const _MemberList({required this.sect});
  final Sect sect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(sectMembersProvider(sect.id));
    final numbers = ref.watch(numbersConfigProvider);
    final cap = SectMemberService.memberCapFor(numbers, sect.sectLevel);
    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(UiStrings.sectLoadFailed(e),
            style: const TextStyle(color: WuxiaColors.textMuted)),
      ),
      data: (members) {
        if (members.isEmpty) {
          return const Center(
            child: Text(
              UiStrings.sectMemberEmpty,
              style: TextStyle(color: WuxiaColors.textMuted),
            ),
          );
        }
        final sorted = [...members]..sort((a, b) {
          final rankA = a.sectRank?.index ?? -1;
          final rankB = b.sectRank?.index ?? -1;
          if (rankA != rankB) return rankB.compareTo(rankA);
          return b.realmTier.index.compareTo(a.realmTier.index);
        });
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    '${UiStrings.sectMemberCountLabel}:',
                    style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    UiStrings.sectMemberCapDisplay(sect.memberCount, cap),
                    style: const TextStyle(
                      color: WuxiaColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sorted.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MemberRow(member: sorted[i], sect: sect),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.member, required this.sect});
  final Character member;
  final Sect sect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numbers = ref.watch(numbersConfigProvider);
    final isFounder = member.id == sect.founderId;
    final rank = member.sectRank;
    final threshold = numbers.sectManagement.rankPromoteThreshold;

    int requiredForNext = 0;
    bool canPromote = false;
    if (rank == SectRank.initiate) {
      requiredForNext = threshold.innerMinContribution;
      canPromote = sect.totalWins >= requiredForNext;
    } else if (rank == SectRank.inner) {
      requiredForNext = threshold.elderMinContribution;
      canPromote = sect.totalWins >= requiredForNext;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WuxiaColors.sidebar,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WuxiaColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: WuxiaColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    if (isFounder)
                      const _SmallChip(
                        label: UiStrings.sectMemberFounderTag,
                        color: WuxiaColors.hpHigh,
                      ),
                    if (rank != null)
                      _SmallChip(
                        label: _sectRankLabel(rank),
                        color: WuxiaColors.textSecondary,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  EnumL10n.realmTier(member.realmTier),
                  style: const TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (rank != null && rank != SectRank.elder && !canPromote)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      UiStrings.sectPromoteRequire(requiredForNext),
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (rank != null && rank != SectRank.elder && canPromote)
            TextButton(
              onPressed: () => _promote(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: WuxiaColors.hpHigh,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(UiStrings.sectMemberPromote),
            ),
          if (!isFounder)
            TextButton(
              onPressed: () => _dismiss(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: WuxiaColors.hpLow,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(UiStrings.sectMemberDismiss),
            ),
        ],
      ),
    );
  }

  Future<void> _promote(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(sectMemberMutationProvider.notifier).promoteRank(
              characterId: member.id,
              contribution: sect.totalWins,
            );
    if (!context.mounted) return;
    final msg = switch (result) {
      PromoteResult.success => UiStrings.sectPromoteSuccess,
      PromoteResult.belowThreshold => UiStrings.sectPromoteBelowThreshold,
      PromoteResult.alreadyMax => UiStrings.sectPromoteAlreadyMax,
      _ => '操作失败',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(sectMemberMutationProvider.notifier)
        .dismiss(characterId: member.id);
    if (!context.mounted) return;
    final msg = result == DismissResult.success
        ? UiStrings.sectDismissSuccess
        : '操作失败';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _TerritoryGrid extends ConsumerWidget {
  const _TerritoryGrid({required this.sect});
  final Sect sect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(availableTerritoriesProvider);
    final numbers = ref.watch(numbersConfigProvider);
    final cap = TerritoryService.territoryCapFor(numbers, sect.sectLevel);
    final ownedIds = sect.territoryIds;
    final ownedDefs = ownedIds
        .map((id) => TerritoryService.defOf(id))
        .whereType<TerritoryDef>()
        .toList();
    final available = availableAsync.asData?.value ?? const <TerritoryDef>[];
    final all = [...ownedDefs, ...available];

    if (all.isEmpty) {
      return const Center(
        child: Text(
          UiStrings.sectTerritoryEmpty,
          style: TextStyle(color: WuxiaColors.textMuted),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                '${UiStrings.sectTerritoryCountLabel}:',
                style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                UiStrings.sectMemberCapDisplay(ownedDefs.length, cap),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: all.length,
            itemBuilder: (ctx, i) {
              final def = all[i];
              final isOwned = ownedIds.contains(def.id);
              return _TerritoryCell(def: def, isOwned: isOwned, sect: sect);
            },
          ),
        ),
      ],
    );
  }
}

class _TerritoryCell extends ConsumerWidget {
  const _TerritoryCell({
    required this.def,
    required this.isOwned,
    required this.sect,
  });

  final TerritoryDef def;
  final bool isOwned;
  final Sect sect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WuxiaColors.sidebar,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOwned ? WuxiaColors.hpHigh : WuxiaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            def.name,
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _SmallChip(
                label:
                    '${UiStrings.sectTerritoryDefenseLabel} ${def.baseDefenseLevel}',
                color: WuxiaColors.textSecondary,
              ),
              _SmallChip(
                label: isOwned
                    ? UiStrings.sectTerritoryOwnedSelf
                    : UiStrings.sectTerritoryNeutral,
                color: isOwned ? WuxiaColors.hpHigh : WuxiaColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              def.description,
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => isOwned ? _release(context, ref) : _claim(context, ref),
              style: TextButton.styleFrom(
                foregroundColor:
                    isOwned ? WuxiaColors.hpLow : WuxiaColors.hpHigh,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                isOwned
                    ? UiStrings.sectTerritoryRelease
                    : UiStrings.sectTerritoryClaim,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(territoryMutationProvider.notifier).claim(
              sectId: sect.id,
              territoryId: def.id,
            );
    ref.invalidate(availableTerritoriesProvider);
    if (!context.mounted) return;
    final msg = switch (result) {
      ClaimResult.success => UiStrings.sectClaimSuccess,
      ClaimResult.alreadyOwned => UiStrings.sectClaimAlreadyOwned,
      ClaimResult.fullCap => UiStrings.sectClaimFullCap,
      _ => '操作失败',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _release(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(territoryMutationProvider.notifier).release(
              sectId: sect.id,
              territoryId: def.id,
            );
    ref.invalidate(availableTerritoriesProvider);
    if (!context.mounted) return;
    final msg = result == ReleaseResult.success
        ? UiStrings.sectReleaseSuccess
        : '操作失败';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}

String _sectRankLabel(SectRank rank) {
  switch (rank) {
    case SectRank.initiate:
      return UiStrings.sectRankInitiate;
    case SectRank.inner:
      return UiStrings.sectRankInner;
    case SectRank.elder:
      return UiStrings.sectRankElder;
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
