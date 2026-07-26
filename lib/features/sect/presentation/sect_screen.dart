import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/application/battle_providers.dart';
import '../../../core/domain/character.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/utils/asset_framing.dart';
import '../../../shared/widgets/portrait_frame.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/sect_member_service.dart';
import '../application/sect_providers.dart';
import '../application/territory_service.dart';
import '../domain/sect.dart';
import '../domain/sect_event.dart';
import '../../../core/domain/sect_rank.dart';
import '../../../data/defs/territory_def.dart';
import 'widgets/sect_event_dialog.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

/// 门派总堂：横匾总览 + 宗门告示 / 门派年表 / 堂上座次 / 山门地契。
///
/// **数据源**:T19b 起切到 Isar 真持久化 — `currentSectProvider` StreamProvider
/// 读 `isar.sects.watchObject(1)` + `activeSectEventsProvider` / `historicalSectEventsProvider`
/// 各走 status filter watch。AsyncValue 三态(data / loading / error)。
class SectScreen extends ConsumerWidget {
  const SectScreen({super.key, this.initialTabIndex = 0});

  /// 默认进「当前事件」tab(index 0)。debug 视觉验收入口可传 2 直达「成员」tab
  /// 看成员立绘;默认值保持生产行为不变。
  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectAsync = ref.watch(currentSectProvider);
    final activeAsync = ref.watch(activeSectEventsProvider);
    final historyAsync = ref.watch(historicalSectEventsProvider);

    return sectAsync.when(
      loading: () =>
          const _SectStateScaffold(child: Center(child: InkLoadingIndicator())),
      error: (e, _) => _SectStateScaffold(
        child: _HallEmptyState(
          icon: Icons.cloud_off_outlined,
          message: UiStrings.sectLoadFailed(e),
        ),
      ),
      data: (sect) {
        if (sect == null) {
          return const _SectStateScaffold(
            child: _HallEmptyState(
              icon: Icons.account_balance_outlined,
              message: UiStrings.sectNotCreated,
            ),
          );
        }
        return DefaultTabController(
          length: 4,
          initialIndex: initialTabIndex,
          child: Scaffold(
            backgroundColor: WuxiaColors.background,
            appBar: WuxiaTitleBar(
              title: UiStrings.sectScreenTitle,
              onBack: Navigator.of(context).canPop()
                  ? () => Navigator.of(context).maybePop()
                  : null,
              trailing: kDebugMode
                  ? IconButton(
                      icon: const Icon(Icons.bolt, color: WuxiaUi.jiang),
                      tooltip: UiStrings.sectDebugSpawnEventTooltip,
                      onPressed: () => debugSpawnSectEvent(ref),
                    )
                  : null,
            ),
            body: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _SectHallBackdrop(),
                  Column(
                    children: [
                      _SectHeader(sect: sect),
                      const _HallTabBar(),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _ActiveEventList(
                              events:
                                  (activeAsync.asData?.value ??
                                  const <SectEvent>[]),
                              sect: sect,
                            ),
                            _HistoricalEventList(
                              events:
                                  (historyAsync.asData?.value ??
                                  const <SectEvent>[]),
                            ),
                            _MemberList(sect: sect),
                            _TerritoryGrid(sect: sect),
                          ],
                        ),
                      ),
                    ],
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

class _SectStateScaffold extends StatelessWidget {
  const _SectStateScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.sectScreenTitle,
        onBack: Navigator.of(context).canPop()
            ? () => Navigator.of(context).maybePop()
            : null,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [const _SectHallBackdrop(), child],
      ),
    );
  }
}

class _SectHallBackdrop extends StatelessWidget {
  const _SectHallBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WuxiaImage(
          'assets/scenes/sect_hall_main_v1.png',
          fit: BoxFit.cover,
          alignment: assetFramingForScene(
            'assets/scenes/sect_hall_main_v1.png',
          ).alignment,
          errorBuilder: (_, _, _) =>
              const ColoredBox(color: WuxiaColors.paperUnderlay),
        ),
        const ColoredBox(color: Color(0x990F1215)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xCC11161A),
                WuxiaColors.background.withValues(alpha: 0.76),
                WuxiaColors.background.withValues(alpha: 0.94),
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _HallTabBar extends StatelessWidget {
  const _HallTabBar();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 980),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xE63A2B1C),
          border: Border.all(color: WuxiaUi.woodLight, width: 1.2),
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: TabBar(
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: WuxiaUi.ink,
          unselectedLabelColor: const Color(0xFFD2C4A4),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          indicator: BoxDecoration(
            color: WuxiaUi.paper2,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: WuxiaUi.gold),
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.campaign_outlined, size: 18),
              text: UiStrings.sectTabEventsActive,
            ),
            Tab(
              icon: Icon(Icons.history_edu_outlined, size: 18),
              text: UiStrings.sectTabEventsHistory,
            ),
            Tab(
              icon: Icon(Icons.groups_2_outlined, size: 18),
              text: UiStrings.sectTabMembers,
            ),
            Tab(
              icon: Icon(Icons.landscape_outlined, size: 18),
              text: UiStrings.sectTabTerritories,
            ),
          ],
        ),
      ),
    );
  }
}

class _HallEmptyState extends StatelessWidget {
  const _HallEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
          color: WuxiaUi.panelFill,
          border: Border.all(color: WuxiaUi.woodLight),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: WuxiaUi.jiang, size: 34),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WuxiaUi.ink, fontSize: 15),
            ),
          ],
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
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 980),
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        padding: const EdgeInsets.fromLTRB(22, 13, 22, 14),
        decoration: BoxDecoration(
          color: const Color(0xD92B2118),
          border: Border.all(color: WuxiaUi.woodLight, width: 1.2),
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 240,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B2A1B),
                border: Border.all(color: WuxiaUi.gold),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000), blurRadius: 8),
                ],
              ),
              child: Text(
                sect.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE7D5AC),
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 5,
                ),
              ),
            ),
            const SizedBox(width: 18),
            _LevelSeal(level: sect.sectLevel),
            const SizedBox(width: 22),
            Expanded(child: _ReputationRuler(value: sect.sectReputation)),
            const SizedBox(width: 18),
            Text(
              UiStrings.sectTotalWinsLabel(sect.totalWins),
              style: const TextStyle(
                color: Color(0xFFD7C7A8),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelSeal extends StatelessWidget {
  const _LevelSeal({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.035,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: WuxiaUi.jiang.withValues(alpha: 0.76),
          border: Border.all(color: const Color(0xFFD9B39A), width: 1.2),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          UiStrings.sectLevelLabel(level),
          style: const TextStyle(
            color: Color(0xFFF0DCC8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _ReputationRuler extends StatelessWidget {
  const _ReputationRuler({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final ratio = (value / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              UiStrings.sectReputationLabel,
              style: TextStyle(color: Color(0xFFBFAF91), fontSize: 11),
            ),
            const Spacer(),
            Text(
              '$value / 100',
              style: const TextStyle(
                color: Color(0xFFE7D5AC),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sealX = (constraints.maxWidth - 10) * ratio;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(height: 2, color: const Color(0xFF8F8067)),
                  for (var i = 0; i <= 10; i++)
                    Positioned(
                      left: (constraints.maxWidth - 1) * i / 10,
                      child: Container(
                        width: 1,
                        height: i.isEven ? 8 : 5,
                        color: const Color(0xFFB3A385),
                      ),
                    ),
                  Positioned(
                    left: sealX,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: WuxiaUi.jiang,
                        border: Border.all(color: const Color(0xFFE4C4A8)),
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: const [
                          BoxShadow(color: Color(0xAA000000), blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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
      return const _HallEmptyState(
        icon: Icons.mark_email_read_outlined,
        message: UiStrings.sectNoActiveEvent,
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          itemCount: events.length,
          itemBuilder: (ctx, i) {
            final e = events[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActiveEventRow(event: e, sect: sect),
            );
          },
        ),
      ),
    );
  }
}

class _ActiveEventRow extends StatelessWidget {
  const _ActiveEventRow({required this.event, required this.sect});
  final SectEvent event;
  final Sect sect;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: WuxiaUi.panelFill,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => SectEventDialog(event: event, sect: sect),
          ),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: WuxiaUi.woodLight, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
            child: Row(
              children: [
                Transform.rotate(
                  angle: -0.08,
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: WuxiaUi.jiang.withValues(alpha: 0.10),
                      border: Border.all(color: WuxiaUi.jiang, width: 1.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Icon(
                      Icons.circle,
                      color: WuxiaUi.jiang,
                      size: 9,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeLabel(event.type),
                        style: const TextStyle(
                          color: WuxiaUi.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        UiStrings.sectEventTriggeredAt(
                          _formatDate(event.triggeredAt),
                        ),
                        style: const TextStyle(
                          color: WuxiaUi.muted,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color: WuxiaUi.jiang,
                ),
              ],
            ),
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
      return const _HallEmptyState(
        icon: Icons.history_edu_outlined,
        message: UiStrings.sectNoHistory,
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          itemCount: events.length,
          itemBuilder: (ctx, i) =>
              _HistoryEntry(event: events[i], isLast: i == events.length - 1),
        ),
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.event, required this.isLast});

  final SectEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final delta = event.reputationDelta ?? 0;
    final deltaStr = delta >= 0 ? '+$delta' : '$delta';
    final sealColor = delta >= 0 ? WuxiaUi.jiang : WuxiaUi.ink2;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: sealColor,
                    border: Border.all(color: const Color(0xFFE3C9A0)),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1, color: const Color(0xFF8C7658)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: WuxiaUi.panelFill,
                border: Border.all(color: WuxiaUi.woodLight),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_typeLabel(event.type)} · ${_statusLabel(event.status)}',
                          style: const TextStyle(
                            color: WuxiaUi.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(event.resolvedAt ?? event.triggeredAt),
                          style: const TextStyle(
                            color: WuxiaUi.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: sealColor),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      UiStrings.sectReputationDelta(deltaStr),
                      style: TextStyle(
                        color: sealColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      loading: () => const Center(child: InkLoadingIndicator()),
      error: (e, _) => Center(
        child: Text(
          UiStrings.sectLoadFailed(e),
          style: const TextStyle(color: WuxiaColors.textMuted),
        ),
      ),
      data: (members) {
        if (members.isEmpty) {
          return const _HallEmptyState(
            icon: Icons.person_search_outlined,
            message: UiStrings.sectMemberEmpty,
          );
        }
        final sorted = [...members]
          ..sort((a, b) {
            final rankA = a.sectRank?.index ?? -1;
            final rankB = b.sectRank?.index ?? -1;
            if (rankA != rankB) return rankB.compareTo(rankA);
            return b.realmTier.index.compareTo(a.realmTier.index);
          });
        final founders = sorted.where((m) => m.id == sect.founderId).toList();
        final founder = founders.isEmpty ? null : founders.first;
        final others = sorted.where((m) => m.id != sect.founderId).toList();
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _SeatCountStrip(
                  value: UiStrings.sectMemberCapDisplay(sect.memberCount, cap),
                ),
                if (founder != null) ...[
                  const SizedBox(height: 12),
                  _MemberRow(member: founder, sect: sect, featured: true),
                ],
                for (final rank in SectRank.values.reversed) ...[
                  if (others.any((m) => m.sectRank == rank)) ...[
                    const SizedBox(height: 14),
                    _SeatSection(
                      rank: rank,
                      members: others.where((m) => m.sectRank == rank).toList(),
                      sect: sect,
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SeatCountStrip extends StatelessWidget {
  const _SeatCountStrip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.people_alt_outlined,
          color: Color(0xFFD7C7A8),
          size: 17,
        ),
        const SizedBox(width: 8),
        const Text(
          '${UiStrings.sectMemberCountLabel}:',
          style: TextStyle(color: Color(0xFFC4B69B), fontSize: 12),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF0DFBC),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0x667D6A4F), height: 1)),
      ],
    );
  }
}

class _SeatSection extends StatelessWidget {
  const _SeatSection({
    required this.rank,
    required this.members,
    required this.sect,
  });

  final SectRank rank;
  final List<Character> members;
  final Sect sect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(width: 18, height: 2, color: WuxiaUi.jiang),
            const SizedBox(width: 8),
            Text(
              _sectRankLabel(rank),
              style: const TextStyle(
                color: Color(0xFFE3D1AA),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Divider(color: Color(0x667D6A4F), height: 1)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final member in members)
              SizedBox(
                width: 464,
                child: _MemberRow(member: member, sect: sect),
              ),
          ],
        ),
      ],
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.member,
    required this.sect,
    this.featured = false,
  });
  final Character member;
  final Sect sect;
  final bool featured;

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
      padding: EdgeInsets.symmetric(
        horizontal: featured ? 16 : 12,
        vertical: featured ? 12 : 9,
      ),
      decoration: BoxDecoration(
        color: featured ? const Color(0xF2E1CDA5) : WuxiaUi.panelFill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: featured ? WuxiaUi.gold : WuxiaUi.woodLight,
          width: featured ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          PortraitFrame(
            portraitPath: member.portraitPath,
            size: featured ? 72 : 58,
            borderColor: member.school == null
                ? WuxiaUi.woodLight
                : WuxiaColors.schoolColor(member.school!),
            placeholderText: member.name,
          ),
          const SizedBox(width: 12),
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
                        color: WuxiaUi.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    if (isFounder)
                      const _SmallChip(
                        label: UiStrings.sectMemberFounderTag,
                        color: WuxiaUi.jiang,
                      ),
                    if (rank != null)
                      _SmallChip(
                        label: _sectRankLabel(rank),
                        color: WuxiaUi.ink2,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  EnumL10n.realmTier(member.realmTier),
                  style: const TextStyle(color: WuxiaUi.muted, fontSize: 12),
                ),
                if (rank != null && rank != SectRank.elder && !canPromote)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      UiStrings.sectPromoteRequire(requiredForNext),
                      style: const TextStyle(
                        color: WuxiaUi.muted,
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
                foregroundColor: WuxiaUi.qing,
                backgroundColor: WuxiaUi.qing.withValues(alpha: 0.08),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(UiStrings.sectMemberPromote),
            ),
          if (!isFounder)
            TextButton(
              onPressed: () => _dismiss(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: WuxiaUi.jiang,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(UiStrings.sectMemberDismiss),
            ),
        ],
      ),
    );
  }

  Future<void> _promote(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(sectMemberMutationProvider.notifier)
        .promoteRank(characterId: member.id, contribution: sect.totalWins);
    if (!context.mounted) return;
    final msg = switch (result) {
      PromoteResult.success => UiStrings.sectPromoteSuccess,
      PromoteResult.belowThreshold => UiStrings.sectPromoteBelowThreshold,
      PromoteResult.alreadyMax => UiStrings.sectPromoteAlreadyMax,
      _ => UiStrings.sectOperationFailed,
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
        : UiStrings.sectOperationFailed;
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
      return const _HallEmptyState(
        icon: Icons.map_outlined,
        message: UiStrings.sectTerritoryEmpty,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            children: [
              const Icon(
                Icons.landscape_outlined,
                color: Color(0xFFD7C7A8),
                size: 17,
              ),
              const SizedBox(width: 8),
              const Text(
                '${UiStrings.sectTerritoryCountLabel}:',
                style: TextStyle(color: Color(0xFFC4B69B), fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                UiStrings.sectMemberCapDisplay(ownedDefs.length, cap),
                style: const TextStyle(
                  color: Color(0xFFF0DFBC),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Divider(color: Color(0x667D6A4F), height: 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 620,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.15,
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
      padding: const EdgeInsets.fromLTRB(15, 13, 13, 10),
      decoration: BoxDecoration(
        color: isOwned ? const Color(0xF2E1CDA5) : WuxiaUi.panelFill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isOwned ? WuxiaUi.jiang : WuxiaUi.woodLight,
          width: isOwned ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            def.name,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
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
                color: WuxiaUi.ink2,
              ),
              _SmallChip(
                label: isOwned
                    ? UiStrings.sectTerritoryOwnedSelf
                    : UiStrings.sectTerritoryNeutral,
                color: isOwned ? WuxiaUi.jiang : WuxiaUi.muted,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              def.description,
              style: const TextStyle(color: WuxiaUi.muted, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  isOwned ? _release(context, ref) : _claim(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: isOwned ? WuxiaUi.jiang : WuxiaUi.qing,
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
    final result = await ref
        .read(territoryMutationProvider.notifier)
        .claim(sectId: sect.id, territoryId: def.id);
    ref.invalidate(availableTerritoriesProvider);
    if (!context.mounted) return;
    final msg = switch (result) {
      ClaimResult.success => UiStrings.sectClaimSuccess,
      ClaimResult.alreadyOwned => UiStrings.sectClaimAlreadyOwned,
      ClaimResult.fullCap => UiStrings.sectClaimFullCap,
      _ => UiStrings.sectOperationFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _release(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(territoryMutationProvider.notifier)
        .release(sectId: sect.id, territoryId: def.id);
    ref.invalidate(availableTerritoriesProvider);
    if (!context.mounted) return;
    final msg = result == ReleaseResult.success
        ? UiStrings.sectReleaseSuccess
        : UiStrings.sectOperationFailed;
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
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
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
      return UiStrings.sectEventTypeTournament;
    case SectEventType.mission:
      return UiStrings.sectEventTypeMission;
    case SectEventType.crisis:
      return UiStrings.sectEventTypeCrisis;
  }
}

String _statusLabel(SectEventStatus status) {
  switch (status) {
    case SectEventStatus.pending:
      return UiStrings.sectEventStatusPending;
    case SectEventStatus.resolved:
      return UiStrings.sectEventStatusResolved;
    case SectEventStatus.expired:
      return UiStrings.sectEventStatusExpired;
  }
}

String _formatDate(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
