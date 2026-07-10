import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/game_event.dart';
import '../../../data/isar_provider.dart';

part 'game_event_feed_providers.g.dart';

/// 最近发生的江湖事件，按时间倒序返回。
///
/// Isar 未初始化时返回空列表，供百科等只读入口安全使用。
@riverpod
Future<List<GameEvent>> gameEventsFeed(Ref ref, {int limit = 20}) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) return const [];
  return isar.gameEvents.where().sortByOccurredAtDesc().limit(limit).findAll();
}
