import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/game_event.dart';
import '../../../data/isar_provider.dart';

part 'home_feed_providers.g.dart';

/// "昨晚发生的事"金色摘要 feed(GDD §9.2 / P1 #42 Phase 3)。
///
/// 默认拉最近 20 条 GameEvent,按 occurredAt desc。Isar 未 init 时(test 路径)
/// 返回空 list,不抛 — 沿 [isarProvider] nullable propagation 体例。
@riverpod
Future<List<GameEvent>> gameEventsFeed(
  Ref ref, {
  int limit = 20,
}) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return const [];
  return isar.gameEvents
      .where()
      .sortByOccurredAtDesc()
      .limit(limit)
      .findAll();
}

/// 快速领取:把所有 GameEvent.isRead = true。
///
/// caller(HomeFeedScreen 快速领取按钮)取 isarProvider 后直接调用,
/// invalidate gameEventsFeedProvider 留 caller 端 ref 触发(避免 Ref/WidgetRef
/// 类型耦合 + provider 闭包持有 ref disposed 风险)。Isar 未 init 时 no-op。
Future<void> markAllFeedRead(Isar? isar) async {
  if (isar == null) return;
  await isar.writeTxn(() async {
    final unread =
        await isar.gameEvents.filter().isReadEqualTo(false).findAll();
    for (final e in unread) {
      e.isRead = true;
    }
    if (unread.isNotEmpty) {
      await isar.gameEvents.putAll(unread);
    }
  });
}
