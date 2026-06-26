import 'package:isar_community/isar.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../domain/equipment_disposal.dart';

/// 装备单件出售/分解的操作结果。
enum DisposalOutcome {
  /// 出售成功。
  sold,

  /// 分解成功。
  disassembled,

  /// 拒绝：装备穿戴中（ownerCharacterId != null）。
  rejectedEquipped,

  /// 拒绝：师承遗物（isLineageHeritage）。
  rejectedHeritage,

  /// 拒绝：装备不存在（id 无对应行）。
  notFound,
}

/// 装备出售/分解 service（2026-06-26 用户拍板推翻「永久收藏品/只买不卖」红线）。
///
/// **原子事务**：校验 → 删装备 → 入银两/材料，走单个 [writeTxn]。
/// **守卫**：已装备（[Equipment.ownerCharacterId] != null）/
///         师承遗物（[Equipment.isLineageHeritage]）不可处置。
class EquipmentDisposalService {
  EquipmentDisposalService({required this.isar, required this.config});

  final Isar isar;
  final EquipmentDisposalConfig config;

  /// 出售单件：删装备 + 入银两。
  Future<DisposalOutcome> sell(int equipmentId) =>
      isar.writeTxn(() async {
        final eq = await isar.equipments.get(equipmentId);
        final guard = _guard(eq);
        if (guard != null) return guard;

        final price = equipmentSellPrice(eq!.tier, eq.enhanceLevel, config);
        await isar.equipments.delete(equipmentId);
        await _addItem('item_silver', ItemType.silver, price);
        return DisposalOutcome.sold;
      });

  /// 分解单件：删装备 + 入磨剑石/心血结晶。
  Future<DisposalOutcome> disassemble(int equipmentId) =>
      isar.writeTxn(() async {
        final eq = await isar.equipments.get(equipmentId);
        final guard = _guard(eq);
        if (guard != null) return guard;

        final r = equipmentDisassembleRewards(eq!.tier, eq.enhanceLevel, config);
        await isar.equipments.delete(equipmentId);
        if (r.mojianshi > 0) {
          await _addItem('item_mojianshi', ItemType.moJianShi, r.mojianshi);
        }
        if (r.xinxuejiejing > 0) {
          await _addItem(
              'item_xinxuejiejing', ItemType.xinXueJieJing, r.xinxuejiejing);
        }
        return DisposalOutcome.disassembled;
      });

  /// 前置守卫：null = 可处置；否则返回拒绝/未找到结果。
  DisposalOutcome? _guard(Equipment? eq) {
    if (eq == null) return DisposalOutcome.notFound;
    if (eq.ownerCharacterId != null) return DisposalOutcome.rejectedEquipped;
    if (eq.isLineageHeritage) return DisposalOutcome.rejectedHeritage;
    return null;
  }

  /// upsert（仿 ShopService 76-89 体例）：已有行累加，无则新建。须在 [writeTxn] 内调。
  Future<void> _addItem(String defId, ItemType type, int amount) async {
    final now = DateTime.now();
    final existing = await isar.inventoryItems.getByDefId(defId);
    if (existing != null) {
      existing.quantity += amount;
      existing.lastObtainedAt = now;
      await isar.inventoryItems.put(existing);
    } else {
      await isar.inventoryItems.put(InventoryItem()
        ..defId = defId
        ..itemType = type
        ..quantity = amount
        ..firstObtainedAt = now
        ..lastObtainedAt = now);
    }
  }
}
