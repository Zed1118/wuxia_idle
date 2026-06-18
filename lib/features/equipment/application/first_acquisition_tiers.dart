import 'package:isar_community/isar.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import 'drop_service.dart';

/// 计算本次掉落里达「首次获得展示」门槛的 tier 集合(当前仅利器首次)。
///
/// **须在掉落已 putAll 入库后调用**:判定依据是库存总数 ≤ 本次掉落件数 ——
/// 入库前总数=0 会误判所有空库情形;入库后「库存总数 ≤ 本次掉落件数」等价于
/// 「入库前无同 tier 装备」即首次获得。
///
/// 若本次掉落无利器,直接返回空集合(短路,不查库)。
/// 依赖 [GameRepository] 已加载(用 getEquipment 查 tier);未加载则返回空集合自保。
Future<Set<EquipmentTier>> computeFirstAcquisitionTiers(
    Isar isar, DropResult drops) async {
  if (!GameRepository.isLoaded) return const {};
  final droppedLiQi = drops.equipments
      .where((e) =>
          GameRepository.instance.getEquipment(e.defId).tier ==
          EquipmentTier.liQi)
      .length;
  if (droppedLiQi == 0) return const {};

  final all = await isar.equipments.where().findAll();
  var totalLiQi = 0;
  for (final e in all) {
    if (GameRepository.instance.getEquipment(e.defId).tier ==
        EquipmentTier.liQi) {
      totalLiQi++;
    }
  }
  // 入库后总数 ≤ 本次掉落件数 → 入库前库存为 0 → 首次获得。
  return totalLiQi <= droppedLiQi ? {EquipmentTier.liQi} : const {};
}
