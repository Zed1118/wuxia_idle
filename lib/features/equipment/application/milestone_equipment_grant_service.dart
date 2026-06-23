import 'package:isar_community/isar.dart';

import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/utils/rng.dart';
import 'equipment_factory.dart';

/// F1 里程碑装备授予。按 `dropSourceTags` 筛装备，授予未授予过的进背包。
///
/// 沿 [DiscipleJoinService] 一次性防重体例：[SaveData.grantedMilestoneEquipmentIds]
/// gate，重打/重飞升幂等 no-op。`dropSourceTags` 由此成为 live 消费字段(修审计 F6)。
///
/// 两个入口：
///   - [grantForTag] 自开 writeTxn(群战/心魔 post-victory hook 用，caller 不持锁)
///   - [grantForTagInTxn] caller 持锁变体(AscendService.performAscend 在自身
///     writeTxn 内调用，避免嵌套 writeTxn throw)
///
/// 设计原则(与同期服务一致)：依赖注入 [Isar]；装备实例化复用
/// [EquipmentFactory.fromDef] 不重复 roll 逻辑。
class MilestoneEquipmentGrantService {
  MilestoneEquipmentGrantService({required this.isar, DateTime Function()? now})
      : now = now ?? DateTime.now;

  final Isar isar;

  /// 当前时间提供者(注入式，便于测试固定 obtainedAt)。
  final DateTime Function() now;

  /// 自开 writeTxn 授予(caller 不持锁)。
  /// 返回本次新授予的 defId(已授予过 / 无匹配 / repo 未载 → 空)。
  Future<List<String>> grantForTag(
    String tag, {
    required String obtainedFrom,
  }) async {
    if (!GameRepository.isLoaded) return const [];
    final defs = _defsForTag(tag);
    if (defs.isEmpty) return const [];

    final granted = <String>[];
    await isar.writeTxn(() async {
      final save = await isar.saveDatas.get(0);
      if (save == null) return;
      granted.addAll(await _grantInTxn(save, defs, obtainedFrom));
    });
    return granted;
  }

  /// caller 持有 writeTxn 时用(如 performAscend)。直接 mutate [save](caller
  /// 须保证 save 是当前 txn 内对象)并 put 装备 + save。返回新授予 defId。
  Future<List<String>> grantForTagInTxn(
    SaveData save,
    String tag, {
    required String obtainedFrom,
  }) async {
    if (!GameRepository.isLoaded) return const [];
    final defs = _defsForTag(tag);
    if (defs.isEmpty) return const [];
    return _grantInTxn(save, defs, obtainedFrom);
  }

  List<EquipmentDef> _defsForTag(String tag) =>
      GameRepository.instance.equipmentDefs.values
          .where((d) => d.dropSourceTags.contains(tag))
          .toList();

  /// 共享授予核心(必须在 writeTxn 内调用)。
  Future<List<String>> _grantInTxn(
    SaveData save,
    List<EquipmentDef> defs,
    String obtainedFrom,
  ) async {
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
    if (newly.isEmpty) return const [];
    save.grantedMilestoneEquipmentIds = [
      ...save.grantedMilestoneEquipmentIds,
      ...newly,
    ];
    await isar.saveDatas.put(save);
    return newly;
  }
}
