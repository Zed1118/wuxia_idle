import 'package:isar_community/isar.dart';

import '../../../core/domain/inventory_item.dart';
import '../../../data/defs/shop_item_def.dart';

/// 江湖商店购买逻辑（材料经济 P1 Task 5，GDD §5.1）。
///
/// 设计约束：
/// - 只买不卖（§5.1 不做卖出/退款）。
/// - 购买原子性：扣银两 + 入货品在同一 [Isar.writeTxn] 内，
///   避免扣了钱没拿到货。
/// - 余额不足或无 item_silver 行 → [PurchaseFailReason.insufficientSilver]，
///   不做任何写入。
class ShopService {
  /// 购买商品。
  ///
  /// - [isar] 已打开的 Isar 实例。
  /// - [def] 商品静态定义（来自 shop.yaml 加载的 [ShopItemDef]）。
  ///
  /// 返回 [PurchaseResult]：
  /// - `.success == true`：银两已扣、货品已入库（+1）。
  /// - `.success == false`：余额不足，无任何写入。
  static Future<PurchaseResult> purchase(
    Isar isar, {
    required ShopItemDef def,
  }) async {
    return isar.writeTxn(() async {
      // ── 1. 读银两行，得余额 ──
      final silverItem = await isar.inventoryItems.getByDefId('item_silver');
      final balance = silverItem?.quantity ?? 0;

      // ── 2. 余额校验 ──
      if (balance < def.price) {
        // 不足：事务回滚（writeTxn 内 throw 会回滚，但这里直接返回不写入也一样）。
        // 直接返回 fail；writeTxn 不提交任何更改。
        return const PurchaseResult.fail(PurchaseFailReason.insufficientSilver);
      }

      // ── 3. 扣银两 ──
      final now = DateTime.now();
      if (silverItem != null) {
        silverItem.quantity -= def.price;
        silverItem.lastObtainedAt = now;
        await isar.inventoryItems.put(silverItem);
      }
      // 注：余额 >= price >= 0 保证 silverItem 不为 null 才到此处。

      // ── 4. Upsert 货品（仿 SeclusionService._addInventoryItem）──
      final existing = await isar.inventoryItems.getByDefId(def.itemDefId);
      if (existing != null) {
        existing.quantity += 1;
        existing.lastObtainedAt = now;
        await isar.inventoryItems.put(existing);
      } else {
        final newItem = InventoryItem()
          ..defId = def.itemDefId
          ..itemType = def.itemType
          ..quantity = 1
          ..firstObtainedAt = now
          ..lastObtainedAt = now;
        await isar.inventoryItems.put(newItem);
      }

      return const PurchaseResult.success();
    });
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 数据类
// ────────────────────────────────────────────────────────────────────────────

/// 购买操作的失败原因。
enum PurchaseFailReason {
  /// 银两不足（包含 item_silver 行不存在、余额 < 价格）。
  insufficientSilver,
}

/// 购买操作结果。
///
/// 中文展示（如「银两不足」弹窗）由 UI task 处理；
/// 本 task 只暴露枚举 reason，UI 层自行映射文案。
class PurchaseResult {
  /// 是否成功。
  final bool success;

  /// 失败原因；成功时为 null。
  final PurchaseFailReason? reason;

  const PurchaseResult.success()
      : success = true,
        reason = null;

  const PurchaseResult.fail(PurchaseFailReason this.reason) : success = false;
}
