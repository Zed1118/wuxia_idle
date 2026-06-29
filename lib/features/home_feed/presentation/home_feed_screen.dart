import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/game_event.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../main_menu/presentation/main_menu.dart';
import '../../seclusion/presentation/offline_recap_gate.dart';
import '../../sect/application/sect_providers.dart';
import '../application/home_feed_providers.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

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
            child: Image.asset(
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
    return const Center(
      child: Padding(
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
      itemBuilder: (context, i) => _FeedItem(event: events[i], now: now),
    );
  }
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({required this.event, required this.now});

  final GameEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              UiStrings.homeFeedRelativeTime(event.occurredAt, now),
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          event.summary,
          style: const TextStyle(
            color: WuxiaColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _QuickClaimButton extends StatelessWidget {
  const _QuickClaimButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: WuxiaColors.resultHighlight,
            foregroundColor: WuxiaColors.background,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            UiStrings.homeFeedQuickClaimLabel,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
