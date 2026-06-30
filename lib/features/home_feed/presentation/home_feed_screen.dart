import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/game_event.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../main_menu/presentation/main_menu.dart';
import '../../seclusion/presentation/offline_recap_gate.dart';
import '../../sect/application/sect_providers.dart';
import '../application/home_feed_providers.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';

const double _homeFeedContentMaxWidth = 760;
const double _homeFeedActionMaxWidth = 420;

/// "昨晚发生的事"上线第一屏(GDD §9.2 / P1 #42 Phase 3)。
///
/// 设计纪律(反主流红线):
/// - **不是任务列表**(无红点 / 无勾选)
/// - 金色文字摘要 feed,按 occurredAt 倒序
/// - 快速领取按钮 30s 上线流程,push replace 进 MainMenu
/// - 空 feed 时显占位文案(首次启动 / 旧存档迁移)+ 直接快速领取
class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  @override
  void initState() {
    super.initState();
    // M2 离线收益:首帧后检查 active 闭关,若离开 ≥ 阈值弹一次「归来」卡。
    // 无 active / 无 Isar 时 hook 静默 no-op（GDD §5.5 红线无关）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowOfflineRecap(context: context, ref: ref);
      // B1 接通:门派月度 tick(真实日历月锚)。无 sect / 无 Isar 静默 no-op,
      // 不弹任何 UI——纯后台触发 pending 事件 + 声望衰减 + 过期回收,
      // 下游 sect_screen StreamProvider watch 自动刷新(GDD §5.5 真实时间锚)。
      maybeRunSectMonthlyTick(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(gameEventsFeedProvider());
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        title: const Text(
          UiStrings.homeFeedTitle,
          style: TextStyle(
            color: WuxiaColors.resultHighlight,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // M4 PoC #46 美术 Stage 2 W6 收官:水墨红印章落款,水墨克制氛围锚点。
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: WuxiaImage(
              'assets/ui/seal_red.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: feedAsync.when(
                data: (events) => events.isEmpty
                    ? const _EmptyHint()
                    : _FeedList(events: events),
                loading: () => const Center(
                  child: InkLoadingIndicator(
                    color: WuxiaColors.resultHighlight,
                  ),
                ),
                error: (e, st) => const _EmptyHint(),
              ),
            ),
            _QuickClaimButton(
              onTap: () async {
                await markAllFeedRead(ref.read(isarProvider));
                ref.invalidate(gameEventsFeedProvider);
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainMenu()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        key: const ValueKey('home-feed-content'),
        constraints: const BoxConstraints(maxWidth: _homeFeedContentMaxWidth),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            UiStrings.homeFeedEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({required this.events});

  final List<GameEvent> events;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Center(
      child: ConstrainedBox(
        key: const ValueKey('home-feed-content'),
        constraints: const BoxConstraints(maxWidth: _homeFeedContentMaxWidth),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _FeedItem(event: events[i], now: now),
        ),
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({required this.event, required this.now});

  final GameEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaColors.panel.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      color: WuxiaColors.resultHighlight,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: WuxiaUi.ink.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: WuxiaUi.paper.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    UiStrings.homeFeedRelativeTime(event.occurredAt, now),
                    style: const TextStyle(
                      color: WuxiaColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              event.summary,
              style: const TextStyle(
                color: WuxiaColors.textSecondary,
                fontSize: 14,
                height: 1.62,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickClaimButton extends StatelessWidget {
  const _QuickClaimButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _homeFeedActionMaxWidth,
            ),
            child: SizedBox(
              key: const ValueKey('home-feed-quick-claim-button'),
              width: double.infinity,
              child: PlaqueButton(
                label: UiStrings.homeFeedQuickClaimLabel,
                primary: true,
                onTap: () => unawaited(onTap()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
