import 'package:isar/isar.dart';

import 'enums.dart';
import 'reward_entry.dart';

part 'retreat_session.g.dart';

/// 单次闭关 session 记录（Phase 3 T48）。
///
/// 每次进入地图创建一行；收功或放弃后 [status] 更新，不删除（保留历史）。
///
/// 关键约束：
///   - 同一 saveDataId 至多一条 active session（startRetreat 开始前先
///     abandon 旧的）
///   - completedAt == null 表示进行中或已放弃（由 status 区分）
///   - actualRewards 仅在 status == completed 时有意义
@collection
class RetreatSession {
  Id id = Isar.autoIncrement;

  /// 关联 SaveData.slotId（Phase 3 固定 1）。
  late int saveDataId;

  @enumerated
  late RetreatMapType mapType;

  /// 计划闭关时长（小时，来自用户选择：1 / 4 / 12）。
  late int durationHours;

  /// 开始闭关时刻（时辰加成以此时刻决定，不动态切换）。
  late DateTime startedAt;

  /// 收功 / 放弃时刻；active session 时为 null。
  DateTime? completedAt;

  @enumerated
  RetreatStatus status = RetreatStatus.active;

  /// 收功时写入的实际奖励列表（rewardKey → quantity）。
  /// status == active / abandoned 时为空。
  List<RewardEntry> actualRewards = [];
}
