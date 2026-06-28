import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../shared/strings.dart';
import '../domain/equipment_disposal.dart';
import '../domain/equipment_slot_occupancy.dart';

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

  /// 拒绝：装备穿戴中（仍被任一角色装备槽引用）。
  rejectedEquipped,

  /// 拒绝：师承遗物（isLineageHeritage）。
  rejectedHeritage,

  /// 拒绝：玩家锁定保护（isLocked）。
  rejectedLocked,

  /// 拒绝：高阶/稀有/剧情来源等保护规则。
  rejectedProtected,

  /// 拒绝：装备不存在（id 无对应行）。
  notFound,
}

EquipmentProtectionPolicy defaultEquipmentProtectionPolicy() =>
    const EquipmentProtectionPolicy(
      protectedObtainedFrom: {
        UiStrings.dropSourceRareBonus,
        UiStrings.dropSourceMassBattleMerit,
        UiStrings.dropSourceInnerDemonReward,
        UiStrings.dropSourceAscensionReward,
      },
    );

/// 装备出售/分解 service（2026-06-26 用户拍板推翻「永久收藏品/只买不卖」红线）。
///
/// **原子事务**：校验 → 删装备 → 入银两/材料，走单个 [writeTxn]。
/// **守卫**：已装备（任一 `Character.equipped{Slot}Id` 指向该装备）/
///         师承遗物（[Equipment.isLineageHeritage]）/
///         玩家锁定（[Equipment.isLocked]）不可处置。
class EquipmentDisposalService {
  EquipmentDisposalService({
    required this.isar,
    required this.config,
    EquipmentProtectionPolicy? protectionPolicy,
  }) : protectionPolicy =
           protectionPolicy ?? defaultEquipmentProtectionPolicy();

  final Isar isar;
  final EquipmentDisposalConfig config;
  final EquipmentProtectionPolicy protectionPolicy;

  /// 出售单件：删装备 + 入银两。
  Future<DisposalOutcome> sell(int equipmentId) => isar.writeTxn(() async {
    final eq = await isar.equipments.get(equipmentId);
    final guard = await _guard(eq);
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
      final guard = await _guard(eq);
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
  /// 跳过已装备（任一角色槽位引用）、师承遗物（[Equipment.isLineageHeritage]）
  /// 和玩家锁定（[Equipment.isLocked]）装备。
  Future<BulkDisposalResult> sellAllOfTier(EquipmentTier tier) =>
      isar.writeTxn(() async {
        final items = await _bulkSellableOfTier(tier);
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
  /// 跳过已装备/师承遗物/玩家锁定（与 [sellAllOfTier] 相同护栏）。
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

  /// 查询指定品级中可处置的自由装备，沿用单件处置守卫。
  /// 须在 [writeTxn] 内调（读在同事务内）。
  Future<List<Equipment>> _disposableOfTier(EquipmentTier tier) async {
    final all = await isar.equipments.filter().tierEqualTo(tier).findAll();
    final equippedIds = await _equippedEquipmentIds();
    final activeEquippedIds = await _activeFormationEquipmentIds();
    return all
        .where(
          (e) => isEquipmentDisposable(
            e,
            equippedIds,
            activeFormationEquipmentIds: activeEquippedIds,
            policy: protectionPolicy,
          ),
        )
        .toList();
  }

  Future<List<Equipment>> _bulkSellableOfTier(EquipmentTier tier) async {
    return _disposableOfTier(tier);
  }

  /// 前置守卫：null = 可处置；否则返回拒绝/未找到结果。
  Future<DisposalOutcome?> _guard(Equipment? eq) async {
    if (eq == null) return DisposalOutcome.notFound;
    final reason = equipmentProtectionReason(
      eq,
      equippedEquipmentIds: await _equippedEquipmentIds(),
      activeFormationEquipmentIds: await _activeFormationEquipmentIds(),
      policy: protectionPolicy,
    );
    if (reason == EquipmentProtectionReason.currentFormation ||
        reason == EquipmentProtectionReason.equipped) {
      return DisposalOutcome.rejectedEquipped;
    }
    if (reason == EquipmentProtectionReason.lineageHeritage) {
      return DisposalOutcome.rejectedHeritage;
    }
    if (reason == EquipmentProtectionReason.locked) {
      return DisposalOutcome.rejectedLocked;
    }
    if (reason != null) return DisposalOutcome.rejectedProtected;
    return null;
  }

  Future<Set<int>> _equippedEquipmentIds() async {
    final characters = await isar.characters.where().findAll();
    return equippedEquipmentIdsForCharacters(characters);
  }

  Future<Set<int>> _activeFormationEquipmentIds() async {
    final save = await isar.saveDatas.get(0);
    final activeIds = save?.activeCharacterIds.toSet() ?? const <int>{};
    if (activeIds.isEmpty) return const {};
    final characters = await isar.characters.where().findAll();
    return equippedEquipmentIdsForCharacters(
      characters.where((c) => activeIds.contains(c.id)),
    );
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

/// 装备是否可被出售/分解。供 service 与 UI 批量入口共用，避免筛选漂移。
/// 已装备走槽位真值源（[isEquipmentEquippedBySlot]），不再看 ownerCharacterId。
bool isEquipmentDisposable(
  Equipment e,
  Set<int> equippedEquipmentIds, {
  Set<int> activeFormationEquipmentIds = const {},
  EquipmentProtectionPolicy policy = EquipmentProtectionPolicy.defaultPolicy,
}) => !isEquipmentProtected(
  e,
  equippedEquipmentIds: equippedEquipmentIds,
  activeFormationEquipmentIds: activeFormationEquipmentIds,
  policy: policy,
);
