import 'package:isar_community/isar.dart';

part 'tower_personal_record.g.dart';

/// 九霄塔按实际参与者隔离的个人最好记录。
///
/// 存档级首通、解锁、周目与奖励仍由 `TowerProgress` 拥有。本集合只记录
/// 可被真实胜利结算证明的个人事实；旧档无法证明历史参与者时保持空集合。
@collection
class TowerPersonalRecord {
  Id id = Isar.autoIncrement;

  int recordVersion = 1;

  @Index(unique: true)
  late String recordKey;

  @Index()
  late int saveDataId;

  @Index()
  late int participantId;

  /// 该角色曾真实通关的最高塔层；只随胜利单调递增。
  int highestClearedFloor = 0;

  /// 该角色所有带有效耗时的真实胜利中的最短耗时。
  ///
  /// 即时扫荡没有可比较的真实墙钟耗时，写入个人最高层但不伪造本字段。
  int? bestClearTimeMs;

  late DateTime createdAt;
  late DateTime updatedAt;
  late DateTime lastClearedAt;

  static String canonicalKey({
    required int saveDataId,
    required int participantId,
  }) {
    if (saveDataId < 1 || saveDataId > 3) {
      throw ArgumentError.value(saveDataId, 'saveDataId', 'must be 1, 2 or 3');
    }
    if (participantId <= 0) {
      throw ArgumentError.value(participantId, 'participantId', 'must be > 0');
    }
    return 'v1:$saveDataId:$participantId';
  }

  void validateIdentity() {
    if (recordVersion != 1 ||
        recordKey !=
            canonicalKey(
              saveDataId: saveDataId,
              participantId: participantId,
            )) {
      throw StateError('Tower personal record identity drifted');
    }
    if (highestClearedFloor < 1 ||
        (bestClearTimeMs != null && bestClearTimeMs! <= 0)) {
      throw StateError('Tower personal record values are invalid');
    }
  }
}
