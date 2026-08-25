import '../../../core/domain/enums.dart';
import '../../activity/domain/activity_occupancy.dart';

/// 门人调度页的单人只读状态。
///
/// 不承载全局阵容或活动参与请求；参与者仍由各玩法入口逐次选择。
class DiscipleSchedulingMember {
  const DiscipleSchedulingMember({
    required this.characterId,
    required this.name,
    required this.realmTier,
    required this.realmLayer,
    required this.isLeader,
    required this.isAlive,
    required this.activity,
    required this.portraitPath,
  });

  final int characterId;
  final String name;
  final RealmTier realmTier;
  final RealmLayer realmLayer;
  final bool isLeader;
  final bool isAlive;
  final ActivityKind? activity;
  final String? portraitPath;
}

/// 当代宗门可核实的调度摘要。
class DiscipleSchedulingSummary {
  const DiscipleSchedulingSummary({
    required this.leaderId,
    required this.members,
  });

  final int leaderId;
  final List<DiscipleSchedulingMember> members;
}
