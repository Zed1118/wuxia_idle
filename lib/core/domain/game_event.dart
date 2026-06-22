import 'package:isar_community/isar.dart';

import 'enums.dart';

part 'game_event.g.dart';

/// 游戏事件流（data_schema.md §4.9 / GDD §9.2）。
///
/// 用于"昨晚发生的事"摘要展示。所有值得告知玩家的事件按时间倒序展示。
@collection
class GameEvent {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.name)
  late GameEventType eventType;

  late String title;
  late String summary;

  int? relatedCharacterId;
  List<String> relatedEntityIds = [];

  @Index()
  late DateTime occurredAt;

  @Index()
  bool isRead = false;
}
