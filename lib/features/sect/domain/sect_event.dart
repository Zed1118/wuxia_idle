import 'package:isar_community/isar.dart';

import 'sect.dart';

part 'sect_event.g.dart';

/// 门派事件实例(P3.4 §12.1 default 决议 · spec p3_4_sect_event_spec_2026-05-24 §2)。
///
/// composite index `(sectId, triggeredAt)` 支持「本 sect 时序」O(log n) 查询,
/// 沿 P1.2 enmity / P2.x inner_demon 体例。
@collection
class SectEvent {
  Id id = Isar.autoIncrement;

  /// 复合索引 `(sectId, triggeredAt)`:本 sect 按触发时间倒序拉 active/history。
  @Index(composite: [CompositeIndex('triggeredAt')])
  late int sectId;

  @Enumerated(EnumType.name)
  late SectEventType type;

  @Enumerated(EnumType.name)
  late SectEventStatus status;

  late DateTime triggeredAt;

  /// resolve / expire 时落点;pending 期保持 null。
  DateTime? resolvedAt;

  /// FK 指向 `data/lore/sect_event/<id>.yaml` 文案文件。
  late String narrativeId;

  /// resolve/expire 时写入(win +10 / loss -5 / expired -5)。
  int? reputationDelta;
}
