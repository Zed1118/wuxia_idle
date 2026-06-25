import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../domain/island_building_type.dart';
import '../domain/taohua_island_config.dart';

/// 建筑升级操作的失败/成功原因。
enum UpgradeResult {
  /// 升级成功。
  ok,

  /// 已达最高等级，无法继续升。
  maxLevelReached,

  /// 建筑自身境界门槛高于祖师当前境界（config-backed，当前全 0）。
  realmLocked,

  /// 银两不足。
  notEnoughSilver,

  /// 自产材料不足。
  notEnoughMaterial,
}

/// 选配方操作的失败/成功原因。
enum SelectRecipeResult {
  /// 选配方成功。
  ok,

  /// 目标建筑不是 processor（source 建筑无配方）。
  notProcessor,

  /// 配方 ID 在该建筑找不到。
  recipeNotFound,

  /// 配方境界门槛高于祖师当前境界（§5.3 实现：不爆产高阶料）。
  realmLocked,
}

/// 桃花岛建筑升级 + 选配方服务（Isar 写，原子事务）。
///
/// 职责：
/// - [upgradeBlockReason]：**纯静态**升级前置检查（不读写 Isar），widget 与 upgrade 共用，消除双源。
/// - [upgrade]：调用 [upgradeBlockReason] 做 maxLevel / realmUnlock 检查，
///   然后读 Isar 做银两 / 材料检查，全过则原子写 Isar。
/// - [selectRecipe]：检查 isProcessor / recipeExists / realmUnlock，全过则原子写 Isar。
///
/// 失败路径**无任何副作用**（check 在 writeTxn 外先做；txn 内仅在全过后写，
/// 单一 txn 保证原子性）。
class IslandActionService {
  IslandActionService._();

  // ── upgradeBlockReason（纯静态，不读写 Isar）──────────────────────────────

  /// 检查是否可升级（纯判断，不访问 Isar）。
  ///
  /// - 返回 `null` 表示可升级。
  /// - 返回非 null 表示被阻止的原因（widget 和 upgrade 两端共用此函数消除 drift）。
  ///
  /// 注意：[silver] / [material] 须由调用方从缓存 view 或 Isar 读取后传入；
  /// 此函数只做纯算术比较，不自行访问 Isar。
  static UpgradeResult? upgradeBlockReason({
    required BuildingConfig cfg,
    required int level,
    required int founderRealmIndex,
    required int silver,
    required int material,
  }) {
    if (level >= cfg.maxLevel) return UpgradeResult.maxLevelReached;
    // 节奏 B：按等级分阶境界 gate。升 level→level+1 需祖师达 upgradeRealmFor(level)。
    // maxLevel 检查在前，保证 level ∈ [1, maxLevel-1]，upgradeRealmFor 索引不越界。
    if (cfg.upgradeRealmFor(level) > founderRealmIndex) {
      return UpgradeResult.realmLocked;
    }
    if (silver < cfg.upgradeSilverFor(level)) return UpgradeResult.notEnoughSilver;
    if (material < cfg.upgradeMaterialFor(level)) return UpgradeResult.notEnoughMaterial;
    return null;
  }

  // ── upgrade ───────────────────────────────────────────────────────────────

  /// 升级指定建筑。
  ///
  /// - [save]：调用前从 Isar 取出的 SaveData 快照（仅作 check 初值用；
  ///   txn 内重新 get 确保最新）。
  /// - [buildingType]：要升级的建筑类型。
  /// - [founderRealmIndex]：祖师境界 index（0=学徒…6=武圣）。
  ///
  /// 返回 [UpgradeResult]；失败时 Isar 无任何改动。
  static Future<UpgradeResult> upgrade({
    required SaveData save,
    required BuildingType buildingType,
    required int founderRealmIndex,
  }) async {
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    final bCfg = cfg.buildings[buildingType]!;

    // 从 save 快照取当前建筑（check 用）
    final building =
        save.islandBuildings.firstWhere((b) => b.type == buildingType);
    final currentLevel = building.level;

    // ── 纯检查阶段（txn 外，不写 Isar）──────────────────────────────────────

    // 1 & 2: maxLevel / realmLocked（纯静态，不需要 Isar）
    // 传 silver=-1 / material=-1 先只检查前两项（后两项待读 Isar 后再检查）
    final earlyBlock = upgradeBlockReason(
      cfg: bCfg,
      level: currentLevel,
      founderRealmIndex: founderRealmIndex,
      silver: 0,
      material: 0,
    );
    // earlyBlock 仅覆盖 maxLevelReached / realmLocked（silver/material=0 时
    // 若实际有资源也会误报 notEnoughSilver，所以分两阶段：先检 level/realm）
    if (earlyBlock == UpgradeResult.maxLevelReached) {
      return UpgradeResult.maxLevelReached;
    }
    if (earlyBlock == UpgradeResult.realmLocked) {
      return UpgradeResult.realmLocked;
    }

    final isar = IsarSetup.instance;

    // 3. 银两与材料检查（读 Isar 但不写，再调纯静态函数复用同一判断逻辑）
    final silverItem = await isar.inventoryItems.getByDefId('item_silver');
    final silverQty = silverItem?.quantity ?? 0;
    final materialItem =
        await isar.inventoryItems.getByDefId(bCfg.upgradeMaterialItem);
    final materialQty = materialItem?.quantity ?? 0;

    // 预先算出扣除量（txn 内使用）
    final silverNeeded = bCfg.upgradeSilverFor(currentLevel);
    final materialNeeded = bCfg.upgradeMaterialFor(currentLevel);

    final fullBlock = upgradeBlockReason(
      cfg: bCfg,
      level: currentLevel,
      founderRealmIndex: founderRealmIndex,
      silver: silverQty,
      material: materialQty,
    );
    if (fullBlock != null) return fullBlock;

    // ── 执行阶段（单一 writeTxn 原子）────────────────────────────────────────
    await isar.writeTxn(() async {
      // txn 内重新 get 取最新快照（沿 Task 6 模式）
      final s = (await isar.saveDatas.get(0))!;

      // 升级建筑 level
      s.islandBuildings
          .firstWhere((b) => b.type == buildingType)
          .level += 1;
      await isar.saveDatas.put(s);

      // 扣银两
      final silver = await isar.inventoryItems.getByDefId('item_silver');
      if (silver != null) {
        silver.quantity -= silverNeeded;
        await isar.inventoryItems.put(silver);
      }

      // 扣材料
      final mat =
          await isar.inventoryItems.getByDefId(bCfg.upgradeMaterialItem);
      if (mat != null) {
        mat.quantity -= materialNeeded;
        await isar.inventoryItems.put(mat);
      }
    });

    return UpgradeResult.ok;
  }

  // ── selectRecipe ──────────────────────────────────────────────────────────

  /// 为指定 processor 建筑切换激活配方。
  ///
  /// - [save]：调用前从 Isar 取出的 SaveData 快照。
  /// - [buildingType]：目标建筑类型（须为 processor）。
  /// - [recipeId]：要激活的配方 ID。
  /// - [founderRealmIndex]：祖师境界 index。
  ///
  /// 返回 [SelectRecipeResult]；失败时 Isar 无任何改动。
  static Future<SelectRecipeResult> selectRecipe({
    required SaveData save,
    required BuildingType buildingType,
    required String recipeId,
    required int founderRealmIndex,
  }) async {
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    final bCfg = cfg.buildings[buildingType]!;

    // 1. 建筑必须是 processor
    if (bCfg.kind != BuildingKind.processor) {
      return SelectRecipeResult.notProcessor;
    }

    // 2. 配方必须存在
    final recipe = bCfg.recipeById(recipeId);
    if (recipe == null) {
      return SelectRecipeResult.recipeNotFound;
    }

    // 3. 境界门槛（§5.3 config-backed 实现）
    if (recipe.realmUnlockIndex > founderRealmIndex) {
      return SelectRecipeResult.realmLocked;
    }

    // ── 执行阶段（单一 writeTxn 原子）────────────────────────────────────────
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final s = (await isar.saveDatas.get(0))!;
      s.islandBuildings
          .firstWhere((b) => b.type == buildingType)
          .activeRecipeId = recipeId;
      await isar.saveDatas.put(s);
    });

    return SelectRecipeResult.ok;
  }
}
