import '../data/defs/drop_entry.dart';
import '../data/defs/equipment_def.dart';
import '../data/defs/stage_def.dart';
import '../features/tower/domain/tower_floor_def.dart';
import '../data/models/equipment.dart';
import '../utils/rng.dart';
import 'equipment_factory.dart';

/// 单条物品掉落结果（DropResult.items 元素）。
class ItemDropResult {
  /// `InventoryItem.defId`，调用方据此 upsert 背包行。
  final String defId;
  final int quantity;

  const ItemDropResult({required this.defId, required this.quantity});

  @override
  String toString() => 'ItemDropResult($defId × $quantity)';
}

/// `DropService.rollDrops` 的返回值。
///
/// **纯结果对象**：不写 Isar、不触发 GameEvent，由调用方（T26
/// `BattleResolutionService`）汇总写入。
class DropResult {
  /// 已经 roll 完属性的装备实例列表。`ownerCharacterId` 暂为 null（入背包），
  /// 调用方可按需调整。
  final List<Equipment> equipments;

  /// `(defId, quantity)` 二元，按 yaml dropTable 顺序排列。
  final List<ItemDropResult> items;

  const DropResult({required this.equipments, required this.items});

  bool get isEmpty => equipments.isEmpty && items.isEmpty;

  @override
  String toString() =>
      'DropResult(eq=${equipments.length}, items=${items.length})';
}

/// 装备掉落服务（phase2_tasks T27 · spec §356-386）。
///
/// 设计原则（与同期服务一致）：
///   - **纯函数**：不写 Isar、不读 GameRepository，所有依赖注入
///   - **依赖注入 [Rng]**：测试可塞固定种子或 mock
///   - 装备实例化复用 [EquipmentFactory.fromDef]（T19），不重复实现 roll 逻辑
///
/// 一次 `rollDrops` 遍历 `stage.dropTable` 所有 entry，对每条独立判定。
/// 装备命中 → 加入 `equipments`；物品命中 → 加入 `items`。
class DropService {
  /// `EquipmentDef` 查询函数（注入式，避免直接耦合 GameRepository 单例）。
  final EquipmentDef Function(String defId) equipmentDefLookup;

  /// 装备 `obtainedFrom` 字段默认值（GameEvent 摘要用）。
  final String defaultObtainedFrom;

  /// 当前时间提供者（注入式，便于测试固定 `obtainedAt`）。
  final DateTime Function() now;

  DropService({
    required this.equipmentDefLookup,
    this.defaultObtainedFrom = '关卡掉落',
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  /// 对 [stage.dropTable] 逐条独立判定，返回汇总结果。
  ///
  /// `dropTable` 为空 → 直接返回空 [DropResult]，不调 rng。
  DropResult rollDrops(StageDef stage, Rng rng) =>
      _rollTable(stage.dropTable, rng);

  /// 爬塔首通奖励（T44）：与 [rollDrops] 同逻辑，从 [floor.dropTable] 抽。
  ///
  /// **重打不发奖**由调用方（[runTowerFlow]）用 isFirstClear 控制；
  /// 此方法本身不感知首通状态。
  DropResult rollTowerRewards(TowerFloorDef floor, Rng rng) =>
      _rollTable(floor.dropTable, rng);

  DropResult _rollTable(List<DropEntry> table, Rng rng) {
    if (table.isEmpty) return const DropResult(equipments: [], items: []);

    final equipments = <Equipment>[];
    final items = <ItemDropResult>[];

    for (final entry in table) {
      // 边界：dropChance=1.0 必掉，dropChance=0.0 必不掉
      // nextDouble() ∈ [0.0, 1.0)，所以 chance=0 → 0 < 0 false 永不命中；
      // chance=1.0 → 永远命中（任何 [0, 1) 值都 < 1.0）
      if (rng.nextDouble() >= entry.dropChance) continue;

      switch (entry) {
        case EquipmentDrop():
          final def = equipmentDefLookup(entry.equipmentDefId);
          equipments.add(EquipmentFactory.fromDef(
            def,
            rng: rng,
            obtainedAt: now(),
            obtainedFrom: defaultObtainedFrom,
          ));
        case ItemDrop():
          final qty = _rollQuantity(rng, entry.quantityMin, entry.quantityMax);
          items.add(ItemDropResult(
            defId: entry.inventoryItemDefId,
            quantity: qty,
          ));
      }
    }

    return DropResult(equipments: equipments, items: items);
  }

  static int _rollQuantity(Rng rng, int min, int max) {
    if (min == max) return min;
    return min + rng.nextInt(max - min + 1);
  }
}
