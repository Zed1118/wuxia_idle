import 'package:isar_community/isar.dart';

import '../../../core/domain/reward_entry.dart';
import '../../activity/domain/activity_member_snapshot.dart';

part 'expedition_run.g.dart';

/// 出发方针（§4.3）；只改节点权重，不改奖励公式或战斗属性。
enum ExpeditionPolicy { yanJingCaiYao, xunJiFangYou, yiZhanLiXing }

/// 百草岭远征 active 会话（每存档同类最多一条，§8.3）。照 `RetreatSession` 体例。
@collection
class ExpeditionRun {
  Id id = Isar.autoIncrement;

  /// 多存档隔离（沿 `RetreatSession.saveDataId`）。
  late int saveDataId;

  @enumerated
  late ExpeditionPolicy policy;

  /// 稳定随机种子（= 存档标识 + 远征编号派生，§4.7）。
  late int seed;

  late DateTime departedAt;
  DateTime? lastSettledAt;

  /// 已完成节点数；离线结算按 `lastSettledAt → now` 顺序推进。
  int currentNode = 0;

  /// 出发快照 + 远征生命/真气状态。
  List<ActivityMemberSnapshot> members = [];

  /// 暂存奖励（返程/召回时一次性发放，§9.1）。
  List<RewardEntry> stagedRewards = [];

  /// 战败持久态（§4.2 战败即停；07-22 审查 P1-5.2）：settle 战败时落库，
  /// 此后 settle 不再推进/重战，recall 据此兑现战败伤势——跨启动不丢
  /// （旧档无此字段读出默认 false，等价未战败）。
  bool defeated = false;
}
