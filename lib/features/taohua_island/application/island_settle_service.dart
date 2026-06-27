import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../domain/island_building_state.dart';
import '../domain/island_building_type.dart';
import '../domain/taohua_island_config.dart';
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
  /// 查 Isar 的同步做不到，故为 async；在 writeTxn 之外调用（txn 不可 await 外部
  /// async 调用），先拿到再开 txn。供 [island_providers.dart] 与 action 层复用。
  static Future<int> founderRealmIndex(SaveData save) async {
    final isar = IsarSetup.instance;

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
    final cfg = GameRepository.instance.numbers.taohuaIsland;

    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      // txn 内重新 get 取最新版本，不复用 txn 外 save 快照
      final s = (await isar.saveDatas.get(0))!;

      final existingTypes = s.islandBuildings.map((b) => b.type).toSet();
      final missingTypes = BuildingType.values
          .where((type) => cfg.buildings.containsKey(type))
          .where((type) => !existingTypes.contains(type))
          .toList();

      if (s.islandBuildings.isNotEmpty && missingTypes.isEmpty) return;

      final buildings = s.islandBuildings.map((b) => b.copy()).toList();
      for (final type in missingTypes) {
        buildings.add(_initialBuildingState(type, cfg.buildings[type]!));
      }

      s.islandBuildings = buildings;
      s.islandLastSettledAt ??= now;
      await isar.saveDatas.put(s);
    });
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
    final cfg = GameRepository.instance.numbers.taohuaIsland;

    // 若未初始化先建
    if (save.islandLastSettledAt == null || save.islandBuildings.isEmpty) {
      await ensureInitialized(save, now);
      return; // ensureInitialized 已写 now，无需再 settle（elapsed=0）
    }

    // 旧档可能已有一期建筑和结算时间，但缺少二期新增建筑。先补建再重读，
    // 保留原 islandLastSettledAt，让新建筑参与同一段离线结算。
    if (!_hasAllConfiguredBuildings(save, cfg)) {
      await ensureInitialized(save, now);
      save = (await IsarSetup.instance.saveDatas.get(0))!;
    }

    final elapsed =
        now.difference(save.islandLastSettledAt!).inSeconds / 3600.0;
    if (elapsed <= 0) return;

    final realmIdx = await founderRealmIndex(save);

    final newStates = IslandProductionService.settle(
      states: save.islandBuildings,
      config: cfg,
      elapsedHours: elapsed,
      founderRealmIndex: realmIdx,
    );

    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      // txn 内重新 get 取最新版本，不复用 txn 外 save 快照
      final s = (await isar.saveDatas.get(0))!;
      s.islandBuildings = newStates;
      s.islandLastSettledAt = now;
      await isar.saveDatas.put(s);
    });
  }

  static bool _hasAllConfiguredBuildings(
    SaveData save,
    TaohuaIslandConfig cfg,
  ) {
    final existingTypes = save.islandBuildings.map((b) => b.type).toSet();
    return cfg.buildings.keys.every(existingTypes.contains);
  }

  // ── harvest ──────────────────────────────────────────────────────────────

  /// 先结算产出，再把各建筑整数部分成品收入背包，返回 [IslandHarvest]。
  ///
  /// - 小数尾保留在 stored 中（float continuity）。
  /// - 每种成品 defId 对应一条 InventoryItem，已有则累加 quantity。
  /// - settle 串行完成后，harvest 开单一 writeTxn：在同一 save 快照内同时
  ///   统计 gainedMap、扣减 stored 小数尾、写 InventoryItem，保证背包入账
  ///   与 stored 扣除来自同一次读取、严格一致、无竞态窗口。
  static Future<IslandHarvest> harvest(SaveData save, DateTime now) async {
    // 先 settle（settle 自己的 txn 串行完成，harvest 之后再开自己的 txn）
    await settle(save, now);

    final isar = IsarSetup.instance;
    final cfg = GameRepository.instance.numbers.taohuaIsland;

    // gainedMap 在 writeTxn 内、基于同一 save 快照计算，与 stored 扣减严格一致
    final gainedMap = <String, int>{};

    await isar.writeTxn(() async {
      // txn 内重新 get 取最新版本，不复用 txn 外 save 快照
      final s = (await isar.saveDatas.get(0))!;

      // 统计各建筑整数成品，同时扣除 floor 部分、保留小数尾
      final newStates = s.islandBuildings.map((b) {
        final copy = b.copy();
        final bCfg = cfg.buildings[b.type]!;

        // 取成品 defId：source 取 outputItem，processor 取激活配方的 outputItem
        String? outputDefId;
        if (bCfg.kind == BuildingKind.source) {
          outputDefId = bCfg.outputItem;
        } else {
          final recipeId = b.activeRecipeId;
          if (recipeId != null) {
            outputDefId = bCfg.recipeById(recipeId)?.outputItem;
          }
        }

        final floored = b.stored.floor();
        if (floored > 0 && outputDefId != null) {
          gainedMap[outputDefId] = (gainedMap[outputDefId] ?? 0) + floored;
          copy.stored = b.stored - floored; // 保留小数尾
        }

        return copy;
      }).toList();

      if (gainedMap.isEmpty) {
        // 无成品：仍需写回（newStates 无变化，但保持 txn 完整性）
        // 不写 inventory，直接返回即可（txn 内无法提前 return，用 flag 跳过）
        return;
      }

      s.islandBuildings = newStates;
      await isar.saveDatas.put(s);

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
