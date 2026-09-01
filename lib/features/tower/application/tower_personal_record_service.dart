import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../domain/tower_personal_record.dart';

/// 在调用方拥有的胜利结算事务内维护九霄塔个人记录。
class TowerPersonalRecordService {
  const TowerPersonalRecordService({required this.isar});

  final Isar isar;

  /// 记录一场可证明参与者的真实胜利。
  ///
  /// [elapsedMs] 为 0 表示该入口没有真实墙钟耗时（当前为扫荡）；此时只更新
  /// 最高层，不创建或覆盖最好耗时。调用方必须已经开启 write transaction。
  Future<void> recordVictoryInTxn({
    required int saveDataId,
    required int participantId,
    required int floorIndex,
    required int elapsedMs,
    required DateTime now,
  }) async {
    if (floorIndex <= 0) {
      throw ArgumentError.value(floorIndex, 'floorIndex', 'must be > 0');
    }
    if (elapsedMs < 0) {
      throw ArgumentError.value(elapsedMs, 'elapsedMs', 'must be >= 0');
    }
    if (await isar.characters.get(participantId) == null) {
      throw StateError('Tower personal record participant does not exist');
    }

    final key = TowerPersonalRecord.canonicalKey(
      saveDataId: saveDataId,
      participantId: participantId,
    );
    final existing = await isar.towerPersonalRecords
        .filter()
        .recordKeyEqualTo(key)
        .findFirst();
    if (existing == null) {
      final created = TowerPersonalRecord()
        ..recordKey = key
        ..saveDataId = saveDataId
        ..participantId = participantId
        ..highestClearedFloor = floorIndex
        ..bestClearTimeMs = elapsedMs > 0 ? elapsedMs : null
        ..createdAt = now
        ..updatedAt = now
        ..lastClearedAt = now;
      created.validateIdentity();
      await isar.towerPersonalRecords.put(created);
      return;
    }

    existing.validateIdentity();
    if (floorIndex > existing.highestClearedFloor) {
      existing.highestClearedFloor = floorIndex;
    }
    if (elapsedMs > 0 &&
        (existing.bestClearTimeMs == null ||
            elapsedMs < existing.bestClearTimeMs!)) {
      existing.bestClearTimeMs = elapsedMs;
    }
    existing
      ..updatedAt = now
      ..lastClearedAt = now;
    existing.validateIdentity();
    await isar.towerPersonalRecords.put(existing);
  }
}
