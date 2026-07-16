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
}
