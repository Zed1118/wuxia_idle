import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/game_event.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/bgm_scope.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../codex/presentation/codex_tab.dart';
import '../../event/application/game_event_feed_providers.dart';
import 'encounter_tab.dart';
import 'martial_arts_tab.dart';
import '../../../shared/widgets/wuxia_ui/ink_empty_state.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';

/// 江湖见闻录(P1 #42 Phase 4/P1.z / GDD §10.2 第 3 方式百科)。
///
/// 3 tab:
///   - 见闻:GameEvent 全量列表(分页 limit=50,按时间倒序)
///   - 典故:按 7 阶分组装备清单,显化 [EquipmentDef.presetLoreIds] 引用数
///   - 机制(P1.z):8 条机制百科条目(GDD §10.2 第 3 方式,§10.1 8 档对齐解锁)
class BaikeScreen extends StatelessWidget {
  const BaikeScreen({super.key, this.initialTab = 0});

  /// 仅供直达验收/深链接选择首屏；正常入口仍从「见闻」开始。
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return BgmScope(
      track: BgmTrack.baike,
      child: DefaultTabController(
        length: 5,
        initialIndex: initialTab,
        child: Scaffold(
          backgroundColor: WuxiaColors.background,
          appBar: WuxiaTitleBar(
            title: UiStrings.baikeScreenTitle,
            onBack: Navigator.of(context).canPop()
                ? () => Navigator.of(context).pop()
                : null,
          ),
          body: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8D8B7), Color(0xFFD7C196)],
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xFF6B5637))),
                ),
                child: const TabBar(
                  indicatorColor: Color(0xFF8D2F25),
                  indicatorWeight: 3,
                  labelColor: Color(0xFF2A241C),
                  unselectedLabelColor: Color(0xFF756A58),
                  dividerColor: Colors.transparent,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                  tabs: [
                    Tab(text: UiStrings.baikeTabFeed),
                    Tab(text: UiStrings.baikeTabLore),
                    Tab(text: UiStrings.baikeTabCodex),
                    Tab(text: UiStrings.baikeTabEncounter),
                    Tab(text: UiStrings.baikeTabSkills),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _FeedTab(),
                    _LoreTab(),
                    CodexTab(),
                    EncounterTab(),
                    MartialArtsTab(),
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
        child: InkLoadingIndicator(color: WuxiaColors.resultHighlight),
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
                  UiStrings.gameEventRelativeTime(e.occurredAt, now),
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
                      UiStrings.baikeLoreCount(def.presetLoreIds.length),
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
        child: InkEmptyState(
          variant: InkEmptyStateVariant.empty,
          title: UiStrings.baikeEmptyTitle,
          body: text,
          icon: Icons.auto_stories_outlined,
        ),
      ),
    );
  }
}
