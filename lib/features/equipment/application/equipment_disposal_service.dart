import 'package:isar_community/isar.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../inventory/application/inventory_organization.dart';
import '../domain/equipment_disposal.dart';

/// 批量按品级出售/分解的汇总结果。
class BulkDisposalResult {
  final int count;
  final int totalSilver;
  final int totalMojianshi;
  final int totalXinxuejiejing;

  const BulkDisposalResult({
    this.count = 0,
    this.totalSilver = 0,
    this.totalMojianshi = 0,
    this.totalXinxuejiejing = 0,
  });
}

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

  /// 拒绝：未来锁定装备（当前 schema 未落字段，先以谓词预留）。
  rejectedLocked,

  /// 拒绝：装备不存在（id 无对应行）。
  notFound,
}

/// 装备出售/分解 service（2026-06-26 用户拍板推翻「永久收藏品/只买不卖」红线）。
///
/// **原子事务**：校验 → 删装备 → 入银两/材料，走单个 [writeTxn]。
/// **守卫**：已装备（[Equipment.ownerCharacterId] != null）/
///         师承遗物（[Equipment.isLineageHeritage]）不可处置。
class EquipmentDisposalService {
  EquipmentDisposalService({
    required this.isar,
    required this.config,
    this.isLocked = _neverLockedForDisposal,
  });

  final Isar isar;
  final EquipmentDisposalConfig config;
  final EquipmentLockPredicate isLocked;

  /// 出售单件：删装备 + 入银两。
  Future<DisposalOutcome> sell(int equipmentId) => isar.writeTxn(() async {
    final eq = await isar.equipments.get(equipmentId);
    final guard = _guard(eq);
    if (guard != null) return guard;

    final price = equipmentSellPrice(eq!.tier, eq.enhanceLevel, config);
    await isar.equipments.delete(equipmentId);
    await _addItem('item_silver', ItemType.silver, price);
    return DisposalOutcome.sold;
  });

  /// 分解单件：删装备 + 入磨剑石/心血结晶。
  Future<DisposalOutcome> disassemble(int equipmentId) => isar.writeTxn(
    () async {
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
          'item_xinxuejiejing',
          ItemType.xinXueJieJing,
          r.xinxuejiejing,
        );
      }
      return DisposalOutcome.disassembled;
    },
  );

  /// 批量出售指定品级的全部可处置背包装备（整批一个 [writeTxn]，失败自动回滚）。
  ///
  /// 跳过已装备（[Equipment.ownerCharacterId] != null）和师承遗物（[Equipment.isLineageHeritage]）。
  Future<BulkDisposalResult> sellAllOfTier(EquipmentTier tier) =>
      isar.writeTxn(() async {
        final items = await _disposableOfTier(tier);
        var total = 0;
        for (final eq in items) {
          total += equipmentSellPrice(eq.tier, eq.enhanceLevel, config);
          await isar.equipments.delete(eq.id);
        }
        if (total > 0) await _addItem('item_silver', ItemType.silver, total);
        return BulkDisposalResult(count: items.length, totalSilver: total);
      });

  /// 批量分解指定品级的全部可处置背包装备（整批一个 [writeTxn]，失败自动回滚）。
  ///
  /// 跳过已装备/师承遗物（与 [sellAllOfTier] 相同护栏）。
  Future<BulkDisposalResult> disassembleAllOfTier(EquipmentTier tier) =>
      isar.writeTxn(() async {
        final items = await _disposableOfTier(tier);
        var mj = 0, xx = 0;
        for (final eq in items) {
          final r = equipmentDisassembleRewards(
            eq.tier,
            eq.enhanceLevel,
            config,
          );
          mj += r.mojianshi;
          xx += r.xinxuejiejing;
          await isar.equipments.delete(eq.id);
        }
        if (mj > 0) await _addItem('item_mojianshi', ItemType.moJianShi, mj);
        if (xx > 0) {
          await _addItem('item_xinxuejiejing', ItemType.xinXueJieJing, xx);
        }
        return BulkDisposalResult(
          count: items.length,
          totalMojianshi: mj,
          totalXinxuejiejing: xx,
        );
      });

  /// 查询指定品级中可处置的背包装备（ownerCharacterId==null && !isLineageHeritage）。
  /// 须在 [writeTxn] 内调（读在同事务内）。
  Future<List<Equipment>> _disposableOfTier(EquipmentTier tier) async {
    final all = await isar.equipments.filter().tierEqualTo(tier).findAll();
    return all
        .where((e) => isBulkDisposalCandidate(e, isLocked: isLocked))
        .toList();
  }

  /// 前置守卫：null = 可处置；否则返回拒绝/未找到结果。
  DisposalOutcome? _guard(Equipment? eq) {
    if (eq == null) return DisposalOutcome.notFound;
    if (eq.ownerCharacterId != null) return DisposalOutcome.rejectedEquipped;
    if (eq.isLineageHeritage) return DisposalOutcome.rejectedHeritage;
    if (isLocked(eq)) return DisposalOutcome.rejectedLocked;
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
      await isar.inventoryItems.put(
        InventoryItem()
          ..defId = defId
          ..itemType = type
          ..quantity = amount
          ..firstObtainedAt = now
          ..lastObtainedAt = now,
      );
    }
  }
}

bool _neverLockedForDisposal(Equipment _) => false;
