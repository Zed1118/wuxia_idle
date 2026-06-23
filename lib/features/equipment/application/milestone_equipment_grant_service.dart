import 'package:isar_community/isar.dart';

import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../shared/utils/rng.dart';
import 'equipment_factory.dart';

/// F1 里程碑装备授予。按 `dropSourceTags` 筛装备，授予未授予过的进背包。
///
/// 沿 [DiscipleJoinService] 一次性防重体例：[SaveData.grantedMilestoneEquipmentIds]
/// gate，重打/重飞升幂等 no-op。`dropSourceTags` 由此成为 live 消费字段(修审计 F6)。
///
/// 设计原则(与同期服务一致)：
///   - 依赖注入 [Isar]；不读 GameRepository 单例以外的全局
///   - 装备实例化复用 [EquipmentFactory.fromDef]，不重复 roll 逻辑
///   - 内部自开 writeTxn(caller 不持锁)；ascend 等已持锁路径见 spec Task6 (b) 分支
class MilestoneEquipmentGrantService {
  MilestoneEquipmentGrantService({required this.isar, DateTime Function()? now})
      : now = now ?? DateTime.now;

  final Isar isar;

  /// 当前时间提供者(注入式，便于测试固定 obtainedAt)。
  final DateTime Function() now;

  /// 授予所有 `dropSourceTags` 含 [tag] 且未授予过的装备进背包。
  /// 返回本次新授予的 defId 列表(已授予过 / 无匹配 / repo 未载 → 空)。
  Future<List<String>> grantForTag(
    String tag, {
    required String obtainedFrom,
  }) async {
    if (!GameRepository.isLoaded) return const [];
    final defs = GameRepository.instance.equipmentDefs.values
        .where((d) => d.dropSourceTags.contains(tag))
        .toList();
    if (defs.isEmpty) return const [];

    final granted = <String>[];
    await isar.writeTxn(() async {
      final save = await isar.saveDatas.get(0);
      if (save == null) return;
      final already = save.grantedMilestoneEquipmentIds.toSet();
      final rng = DefaultRng();
      final newly = <String>[];
      for (final def in defs) {
        if (already.contains(def.id)) continue;
        final eq = EquipmentFactory.fromDef(
          def,
          rng: rng,
          obtainedAt: now(),
          obtainedFrom: obtainedFrom,
        );
        await isar.equipments.put(eq);
        newly.add(def.id);
      }
      if (newly.isEmpty) return;
      save.grantedMilestoneEquipmentIds = [
        ...save.grantedMilestoneEquipmentIds,
        ...newly,
      ];
      await isar.saveDatas.put(save);
      granted.addAll(newly);
    });
    return granted;
  }
}
