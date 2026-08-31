import 'package:isar_community/isar.dart';

import 'progressive_unlock.dart';

part 'progressive_unlock_receipt.g.dart';

@collection
class ProgressiveUnlockReceipt {
  Id id = Isar.autoIncrement;

  int receiptVersion = 1;

  @Index(unique: true)
  late String receiptKey;

  @Index()
  late int saveDataId;

  @Enumerated(EnumType.name)
  late ProgressiveUnlockId unlockId;

  @Enumerated(EnumType.name)
  late ProgressiveUnlockState highestState;

  late DateTime firstObservedAt;
  late DateTime updatedAt;

  /// 首次真实从非 open 推进到 open 的时点。首次观测即 open 的旧入口也记录，
  /// 但同时建立已确认基线，不补弹历史蜡封。
  DateTime? openedAt;

  /// 非空表示玩家已收下题签；之后不再重复弹出，也不形成永久红点。
  DateTime? sealAcknowledgedAt;

  static String canonicalKey({
    required int saveDataId,
    required ProgressiveUnlockId unlockId,
  }) {
    if (saveDataId < 1 || saveDataId > 3) {
      throw ArgumentError.value(saveDataId, 'saveDataId', 'must be 1, 2 or 3');
    }
    return 'v1:$saveDataId:${unlockId.name}';
  }

  static ProgressiveUnlockReceipt firstObservation({
    required int saveDataId,
    required ProgressiveUnlockId unlockId,
    required ProgressiveUnlockState state,
    required DateTime observedAt,
  }) {
    final initiallyOpen = state == ProgressiveUnlockState.open;
    return ProgressiveUnlockReceipt()
      ..receiptKey = canonicalKey(saveDataId: saveDataId, unlockId: unlockId)
      ..saveDataId = saveDataId
      ..unlockId = unlockId
      ..highestState = state
      ..firstObservedAt = observedAt
      ..updatedAt = observedAt
      ..openedAt = initiallyOpen ? observedAt : null
      ..sealAcknowledgedAt = initiallyOpen ? observedAt : null;
  }

  void validateIdentity() {
    if (receiptVersion != 1 ||
        receiptKey !=
            canonicalKey(saveDataId: saveDataId, unlockId: unlockId)) {
      throw StateError('Progressive unlock receipt identity drifted');
    }
    if (sealAcknowledgedAt != null && openedAt == null) {
      throw StateError('Acknowledged progressive unlock has no openedAt');
    }
  }
}
