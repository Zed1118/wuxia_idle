import '../core/domain/island_building_type.dart';
import '../core/domain/save_data.dart';
import 'defs/taohua_island_config.dart';

/// Upgrades the meaning observable in a legacy save, without guessing history.
abstract final class PlayerYieldMigration {
  static void migrateIslandStocks(SaveData save, TaohuaIslandConfig config) {
    final buildings = save.islandBuildings
        .map((entry) => entry.copy())
        .toList();
    for (final building in buildings) {
      final def = config.buildings[building.type];
      if (def == null) {
        throw StateError('Unknown saved island building: ${building.type}');
      }
      if (def.kind != BuildingKind.processor) continue;
      if (!building.stored.isFinite || building.stored < 0) {
        throw StateError('Invalid legacy island stock: ${building.type}');
      }
      if (building.stored == 0) continue;
      final recipeId = building.activeRecipeId;
      final recipe = recipeId == null ? null : def.recipeById(recipeId);
      if (recipe == null) {
        throw StateError(
          'Legacy island stock has no recipe: ${building.type}/$recipeId',
        );
      }
      // A valid old scalar is a distinct, still-unmigrated balance. Once moved,
      // clear it in the same transaction so re-entry cannot duplicate it.
      building.setProductStored(
        recipe.outputItem,
        building.productStored(recipe.outputItem) + building.stored,
      );
      building.stored = 0;
    }
    save.islandBuildings = buildings;
  }

  static void initializePassiveAnchor(SaveData save) {
    if (save.passiveLastSettledAt != null) return;
    // Equal creation/presence times never established an earned idle window.
    // Leave this case for the first valid leader/lifecycle boundary.
    if (save.lastOnlineAt == save.createdAt) return;
    save.passiveLastSettledAt = save.lastOnlineAt;
  }
}
