import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/island_building_state.dart';
import '../../../core/domain/island_building_type.dart';
import '../../../data/defs/taohua_island_config.dart';
import '../../seclusion/application/offline_passive_service.dart';
import 'island_production_service.dart';

/// 桃花岛一次收获的产出汇总。
class IslandHarvest {
  /// `defId → 数量`，仅含本次 floor 后 > 0 的成品。
  final Map<String, int> gained;

  const IslandHarvest(this.gained);

  bool get isEmpty => gained.isEmpty;
}

/// 桃花岛 Isar 读写服务：首开初始化 / 产出结算 / 收取入背包。
///
/// 职责分工（与 [IslandProductionService] 互补）：
/// - [IslandProductionService]：纯函数，只算数，不碰 Isar。
/// - [IslandSettleService]：负责全部副作用——读/写 SaveData.islandBuildings、
///   更新 islandLastSettledAt、写 InventoryItem。
///
/// **所有方法均接受 SaveData 实例**（调用前由调用方从 Isar 取出），
/// 内部各用单一 writeTxn 完成持久化，避免多 txn 竞态。harvest 的
/// gainedMap 统计与 stored 扣减在同一个 txn 内、基于同一个 save 快照
/// 完成，保证背包入账与 stored 扣除严格一致、无竞态窗口。
class IslandSettleService {
  IslandSettleService._();

  // ── 公开 helper：取祖师境界 index ─────────────────────────────────────────

  /// 按「founder → active 第一位 → fallback 0」顺序返回境界 index。
  ///
  /// Reads only this slot's Isar rows; callers inside a writeTxn see the same
  /// transaction snapshot. Shared by the view and transactional action paths.
  static Future<int> founderRealmIndex(SaveData save, {Isar? database}) async {
    final isar = database ?? IsarSetup.instance;

    // 优先用 founderCharacterId 直接取
    if (save.founderCharacterId != null) {
      final c = await isar.characters.get(save.founderCharacterId!);
      if (c != null) return c.realmTier.index;
    }

    // 扫 active 角色找 isFounder=true
    if (save.activeCharacterIds.isNotEmpty) {
      for (final id in save.activeCharacterIds) {
        final c = await isar.characters.get(id);
        if (c != null && c.isFounder) return c.realmTier.index;
      }
      // 没有 founder 则取第一个 active
      final first = await isar.characters.get(save.activeCharacterIds.first);
      if (first != null) return first.realmTier.index;
    }

    return 0; // fallback
  }

  // ── ensureInitialized ─────────────────────────────────────────────────────

  /// 首开/补建初始化：按配置补齐缺失的 level-1 建筑。
  ///
  /// - 空档：写入全量建筑，并将 [save.islandLastSettledAt] 设为 [now]。
  /// - 旧档：保留已有建筑 level/stored/activeRecipeId，只追加缺失建筑；
  ///   不重置 [save.islandLastSettledAt]。
  ///
  /// 内部调用 writeTxn 完成持久化（与 offline_passive_service 体例一致）。
  static Future<void> ensureInitialized(SaveData save, DateTime now) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final current = await loadAfterPassiveInTxn(now, database: isar);
      if (_ensureBuildings(current, now)) {
        await isar.saveDatas.put(current);
      }
    });
  }

  static bool _ensureBuildings(SaveData save, DateTime now) {
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    final existing = save.islandBuildings.map((b) => b.type).toSet();
    final missing = cfg.buildings.keys.where(
      (type) => !existing.contains(type),
    );
    var changed = false;
    if (missing.isNotEmpty) {
      save.islandBuildings = [
        for (final state in save.islandBuildings) state.copy(),
        for (final type in missing)
          _initialBuildingState(type, cfg.buildings[type]!),
      ];
      changed = true;
    }
    if (save.islandLastSettledAt == null) {
      save.islandLastSettledAt = now;
      changed = true;
    }
    return changed;
  }

  static IslandBuildingState _initialBuildingState(
    BuildingType type,
    BuildingConfig bCfg,
  ) {
    final state = IslandBuildingState()
      ..type = type
      ..level = 1
      ..stored = 0;

    // processor 建筑选第一条配方为默认激活配方
    if (bCfg.kind == BuildingKind.processor && bCfg.recipes.isNotEmpty) {
      state.activeRecipeId = bCfg.recipes.first.recipeId;
    }

    return state;
  }

  // ── settle ────────────────────────────────────────────────────────────────

  /// 结算产出并更新 storage，**不**入背包。
  ///
  /// - 若 [save.islandLastSettledAt] 为 null，先调 [ensureInitialized]。
  /// - 调用 [IslandProductionService.settle] 得到新状态后写回 Isar。
  static Future<void> settle(SaveData save, DateTime now) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final current = await loadAfterPassiveInTxn(now, database: isar);
      await settleInTxn(current, now, database: isar);
      await isar.saveDatas.put(current);
    });
  }

  /// Caller owns the transaction. Resolve pending passive realm changes before
  /// an island visit or action can advance beyond those changes. First opening
  /// establishes the island clock without backdating production. Internal
  /// passive boundaries call [settleInTxn] directly to avoid recursive accrual.
  static Future<SaveData> loadAfterPassiveInTxn(
    DateTime now, {
    Isar? database,
  }) async {
    final isar = database ?? IsarSetup.instance;
    await OfflinePassiveService.settleWithinTxn(isar: isar, now: now);
    return (await isar.saveDatas.get(0))!;
  }

  /// Advances the caller's fresh transaction snapshot without opening a nested
  /// transaction or writing it. The caller owns the final atomic save/inventory
  /// write. Repeated or older times do not replay production or move time back.
  static Future<void> settleInTxn(
    SaveData save,
    DateTime now, {
    int? realmIndex,
    Isar? database,
  }) async {
    _ensureBuildings(save, now);
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    IslandProductionService.validateProductStocks(save.islandBuildings, cfg);
    final elapsed =
        now.difference(save.islandLastSettledAt!).inMicroseconds /
        Duration.microsecondsPerHour;
    if (elapsed <= 0) return;
    final realm =
        realmIndex ?? await founderRealmIndex(save, database: database);
    save.islandBuildings = IslandProductionService.settle(
      states: save.islandBuildings,
      config: cfg,
      elapsedHours: elapsed,
      founderRealmIndex: realm,
    );
    save.islandLastSettledAt = now;
  }

  // ── harvest ──────────────────────────────────────────────────────────────

  /// 先结算产出，再把各建筑整数部分成品收入背包，返回 [IslandHarvest]。
  ///
  /// - 小数尾保留在 stored 中（float continuity）。
  /// - 每种成品 defId 对应一条 InventoryItem，已有则累加 quantity。
  /// - Production, separately floored item quantities, retained fractions, and
  ///   inventory credits are committed in one transaction using the latest save.
  static Future<IslandHarvest> harvest(SaveData save, DateTime now) async {
    final isar = IsarSetup.instance;
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    final gainedMap = <String, int>{};

    await isar.writeTxn(() async {
      final current = await loadAfterPassiveInTxn(now, database: isar);
      await settleInTxn(current, now, database: isar);

      for (final state in current.islandBuildings) {
        final bCfg = cfg.buildings[state.type]!;
        if (bCfg.kind == BuildingKind.source) {
          final qty = state.stored.floor();
          final output = bCfg.outputItem;
          if (qty > 0 && output != null) {
            gainedMap[output] = (gainedMap[output] ?? 0) + qty;
            state.stored -= qty;
          }
        } else {
          for (final stock in state.productStocks) {
            final qty = stock.stored.floor();
            if (qty <= 0) continue;
            final output = stock.outputItemId;
            gainedMap[output] = (gainedMap[output] ?? 0) + qty;
            stock.stored -= qty;
          }
          state.productStocks = state.productStocks
              .where((stock) => stock.stored > 0)
              .toList();
        }
      }
      await isar.saveDatas.put(current);

      // 写入背包（与 offline_passive_service 相同路径）
      for (final entry in gainedMap.entries) {
        final defId = entry.key;
        final qty = entry.value;
        final itemType = ItemType.fromDefId(defId);

        final existing = await isar.inventoryItems.getByDefId(defId);
        if (existing != null) {
          existing.quantity += qty;
          existing.lastObtainedAt = now;
          await isar.inventoryItems.put(existing);
        } else {
          await isar.inventoryItems.put(
            InventoryItem()
              ..defId = defId
              ..itemType = itemType
              ..quantity = qty
              ..firstObtainedAt = now
              ..lastObtainedAt = now,
          );
        }
      }
    });

    if (gainedMap.isEmpty) {
      return const IslandHarvest({});
    }

    return IslandHarvest(gainedMap);
  }
}
