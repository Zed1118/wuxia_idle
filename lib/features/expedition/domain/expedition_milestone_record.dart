import 'package:isar_community/isar.dart';

part 'expedition_milestone_record.g.dart';

/// 百草岭险关模板的宗门级首次亲战事实与待办。
///
/// 一条 canonical `routeId + milestoneId` 记录从首次离线撞门时建立，
/// [manualClearedAt] 只有可见真人战斗胜利事务能写入。待办与已解锁共用一行，
/// 避免返程、恢复和自动化门各自持有漂移状态。
@collection
class ExpeditionMilestoneRecord {
  Id id = Isar.autoIncrement;

  int recordVersion = 1;

  @Index(unique: true)
  late String recordKey;

  @Index()
  late int saveDataId;

  late String routeId;
  late String milestoneId;

  /// 首次撞门的原远征节点身份；用于可见亲战复现同一敌队与周目。
  late int nodeIndex;
  late int nodeSeed;
  int cycleIndex = 1;

  late int sourceRunId;
  late int sourceParticipantId;
  late DateTime discoveredAt;

  /// null = 待亲战；非 null = 该模板已由玩家可见战斗通过，可自动处理。
  DateTime? manualClearedAt;

  static String canonicalKey({
    required int saveDataId,
    required String routeId,
    required String milestoneId,
  }) {
    if (saveDataId < 1 || saveDataId > 3) {
      throw ArgumentError.value(saveDataId, 'saveDataId', 'must be 1, 2 or 3');
    }
    final route = _component(routeId, 'routeId');
    final milestone = _component(milestoneId, 'milestoneId');
    return 'v1:$saveDataId:$route:$milestone';
  }

  static String _component(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.contains(':')) {
      throw ArgumentError.value(value, name, 'must be non-empty without :');
    }
    return normalized;
  }

  void validateIdentity() {
    if (recordVersion != 1 ||
        recordKey !=
            canonicalKey(
              saveDataId: saveDataId,
              routeId: routeId,
              milestoneId: milestoneId,
            ) ||
        nodeIndex <= 0 ||
        cycleIndex < 1 ||
        sourceRunId <= 0 ||
        sourceParticipantId <= 0) {
      throw StateError('Expedition milestone record identity drifted');
    }
  }
}
