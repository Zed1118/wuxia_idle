import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/island_building_type.dart';
import '../../../data/defs/taohua_island_config.dart';
import '../../expedition/application/expedition_timeline.dart';
import 'island_settle_service.dart';

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
/// Action guards roll back the action transaction, including its passive/island
/// accrual and building writes. Due expedition progress is settled separately
/// before that transaction starts.
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
    if (silver < cfg.upgradeSilverFor(level)) {
      return UpgradeResult.notEnoughSilver;
    }
    if (material < cfg.upgradeMaterialFor(level)) {
      return UpgradeResult.notEnoughMaterial;
    }
    return null;
  }

  // ── upgrade ───────────────────────────────────────────────────────────────

  /// 升级指定建筑。
  ///
  /// - [save]：调用前的快照；事务内重读，并使用持久祖师的最新境界。
  /// - [buildingType]：要升级的建筑类型。
  /// - [founderRealmIndex]：祖师境界 index（0=学徒…6=武圣）。
  ///
  /// Returns [UpgradeResult]; a failed action rolls back its transaction.
  static Future<UpgradeResult> upgrade({
    required SaveData save,
    required BuildingType buildingType,
    required int founderRealmIndex,
    DateTime? now,
  }) async {
    final bCfg =
        GameRepository.instance.numbers.taohuaIsland.buildings[buildingType]!;
    final isar = IsarSetup.instance;
    final upgradedAt = now ?? DateTime.now();
    try {
      return await ExpeditionTimeline.runAfterCatchUp(
        isar: isar,
        now: upgradedAt,
        action: () => isar.writeTxn(() async {
          final current = await IslandSettleService.loadAfterPassiveInTxn(
            upgradedAt,
            database: isar,
          );
          final building = current.islandBuildings.firstWhere(
            (state) => state.type == buildingType,
          );
          final realm = await IslandSettleService.founderRealmIndex(
            current,
            database: isar,
          );
          final silver = await isar.inventoryItems.getByDefId('item_silver');
          final material = await isar.inventoryItems.getByDefId(
            bCfg.upgradeMaterialItem,
          );
          final blocked = upgradeBlockReason(
            cfg: bCfg,
            level: building.level,
            founderRealmIndex: realm,
            silver: silver?.quantity ?? 0,
            material: material?.quantity ?? 0,
          );
          if (blocked != null) throw _ActionBlocked(blocked);

          final silverNeeded = bCfg.upgradeSilverFor(building.level);
          final materialNeeded = bCfg.upgradeMaterialFor(building.level);
          await IslandSettleService.settleInTxn(
            current,
            upgradedAt,
            realmIndex: realm,
            database: isar,
          );
          // Settlement replaces the embedded list; mutate its new state, never
          // the pre-settlement reference. The elapsed window uses the old level.
          current.islandBuildings
                  .firstWhere((state) => state.type == buildingType)
                  .level +=
              1;
          await isar.saveDatas.put(current);
          if (silver != null) {
            silver.quantity -= silverNeeded;
            await isar.inventoryItems.put(silver);
          }
          if (material != null) {
            material.quantity -= materialNeeded;
            await isar.inventoryItems.put(material);
          }
          return UpgradeResult.ok;
        }),
      );
    } on _ActionBlocked<UpgradeResult> catch (blocked) {
      return blocked.result;
    }
  }

  // ── selectRecipe ──────────────────────────────────────────────────────────

  /// 为指定 processor 建筑切换激活配方。
  ///
  /// - [save]：调用前从 Isar 取出的 SaveData 快照。
  /// - [buildingType]：目标建筑类型（须为 processor）。
  /// - [recipeId]：要激活的配方 ID。
  /// - [founderRealmIndex]：祖师境界 index。
  ///
  /// Returns [SelectRecipeResult]; a failed action rolls back its transaction.
  static Future<SelectRecipeResult> selectRecipe({
    required SaveData save,
    required BuildingType buildingType,
    required String recipeId,
    required int founderRealmIndex,
    DateTime? now,
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

    final isar = IsarSetup.instance;
    final selectedAt = now ?? DateTime.now();
    try {
      return await ExpeditionTimeline.runAfterCatchUp(
        isar: isar,
        now: selectedAt,
        action: () => isar.writeTxn(() async {
          final current = await IslandSettleService.loadAfterPassiveInTxn(
            selectedAt,
            database: isar,
          );
          final realm = await IslandSettleService.founderRealmIndex(
            current,
            database: isar,
          );
          if (recipe.realmUnlockIndex > realm) {
            throw const _ActionBlocked(SelectRecipeResult.realmLocked);
          }
          await IslandSettleService.settleInTxn(
            current,
            selectedAt,
            realmIndex: realm,
            database: isar,
          );
          current.islandBuildings
                  .firstWhere((state) => state.type == buildingType)
                  .activeRecipeId =
              recipeId;
          await isar.saveDatas.put(current);
          return SelectRecipeResult.ok;
        }),
      );
    } on _ActionBlocked<SelectRecipeResult> catch (blocked) {
      return blocked.result;
    }
  }
}

/// Abort the whole transaction, including pending passive/island accrual, when
/// an action fails a guard. Public callers continue receiving the existing enum.
class _ActionBlocked<T> implements Exception {
  final T result;

  const _ActionBlocked(this.result);
}
