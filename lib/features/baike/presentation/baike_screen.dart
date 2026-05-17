import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/game_event.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../home_feed/application/home_feed_providers.dart';

/// 江湖见闻录(P1 #42 Phase 4 / GDD §10.2 第 3 方式百科)。
///
/// 2 tab:
///   - 见闻:GameEvent 全量列表(分页 limit=50,沿 HomeFeed 体例倒序金色文字)
///   - 典故:按 7 阶分组装备清单,显化 [EquipmentDef.presetLoreIds] 引用数
///     (Phase 4 仅显占位,延续典故详情留 Phase 5 EquipmentDetailScreen 混排)
class BaikeScreen extends StatelessWidget {
  const BaikeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: WuxiaColors.background,
        appBar: AppBar(
          backgroundColor: WuxiaColors.background,
          title: const Text(
            UiStrings.baikeScreenTitle,
            style: TextStyle(color: WuxiaColors.resultHighlight),
          ),
          bottom: const TabBar(
            indicatorColor: WuxiaColors.resultHighlight,
            labelColor: WuxiaColors.resultHighlight,
            unselectedLabelColor: WuxiaColors.textMuted,
            tabs: [
              Tab(text: UiStrings.baikeTabFeed),
              Tab(text: UiStrings.baikeTabLore),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FeedTab(),
            _LoreTab(),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFeed = ref.watch(gameEventsFeedProvider(limit: 50));
    return asyncFeed.when(
      data: (events) => events.isEmpty
          ? const _EmptyHint(text: UiStrings.baikeFeedEmpty)
          : _FeedList(events: events),
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: WuxiaColors.resultHighlight,
        ),
      ),
      error: (e, st) => const _EmptyHint(text: UiStrings.baikeFeedEmpty),
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({required this.events});

  final List<GameEvent> events;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: events.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 24, color: WuxiaColors.border),
      itemBuilder: (context, i) {
        final e = events[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    e.title,
                    style: const TextStyle(
                      color: WuxiaColors.resultHighlight,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  UiStrings.homeFeedRelativeTime(e.occurredAt, now),
                  style: const TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              e.summary,
              style: const TextStyle(
                color: WuxiaColors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoreTab extends StatelessWidget {
  const _LoreTab();

  @override
  Widget build(BuildContext context) {
    if (!GameRepository.isLoaded) {
      return const _EmptyHint(text: UiStrings.baikeLoreEmpty);
    }
    // 7 阶顺序:寻常货 → 神物。同阶按 yaml 列序。
    final byTier = <EquipmentTier, List<EquipmentDef>>{};
    for (final def in GameRepository.instance.equipmentDefs.values) {
      byTier.putIfAbsent(def.tier, () => []).add(def);
    }
    final tiers = EquipmentTier.values
        .where((t) => byTier[t]?.isNotEmpty ?? false)
        .toList(growable: false);
    if (tiers.isEmpty) {
      return const _EmptyHint(text: UiStrings.baikeLoreEmpty);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: tiers.length,
      itemBuilder: (context, i) {
        final tier = tiers[i];
        final defs = byTier[tier]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                EnumL10n.equipmentTier(tier),
                style: const TextStyle(
                  color: WuxiaColors.resultHighlight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final def in defs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        def.name,
                        style: const TextStyle(
                          color: WuxiaColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${def.presetLoreIds.length} 段典故',
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: WuxiaColors.border),
          ],
        );
      },
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: WuxiaColors.textMuted,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
