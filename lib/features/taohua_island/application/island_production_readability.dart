import 'dart:math' as math;

import '../domain/island_building_state.dart';
import '../domain/island_building_type.dart';
import '../domain/taohua_island_config.dart';
import 'island_production_service.dart';

enum IslandProductionPauseReason {
  none,
  full,
  noRecipe,
  realmLocked,
  noProgress,
}

class IslandProductionReadability {
  final BuildingType type;
  final String? recipeId;
  final String? outputItemId;
  final IslandProductionPauseReason pauseReason;
  final double? hoursToNextItem;
  final double? hoursToFull;

  const IslandProductionReadability({
    required this.type,
    required this.recipeId,
    required this.outputItemId,
    required this.pauseReason,
    required this.hoursToNextItem,
    required this.hoursToFull,
  });

  bool get isProducing => pauseReason == IslandProductionPauseReason.none;

  static IslandProductionReadability from({
    required IslandBuildingState state,
    required List<IslandBuildingState> allStates,
    required TaohuaIslandConfig config,
    required int founderRealmIndex,
  }) {
    final bCfg = config.buildingOf(state.type);
    final cap = bCfg.capFor(state.level).toDouble();
    final stored = state.stored.clamp(0.0, double.infinity).toDouble();
    final full = stored >= cap;

    String? recipeId;
    String? outputItemId;
    var locked = bCfg.realmUnlockIndex > founderRealmIndex;
    var noRecipe = false;

    if (bCfg.kind == BuildingKind.source) {
      outputItemId = bCfg.outputItem;
    } else {
      recipeId = state.activeRecipeId;
      if (recipeId == null) {
        noRecipe = true;
      } else {
        final recipe = bCfg.recipeById(recipeId);
        if (recipe == null) {
          noRecipe = true;
        } else {
          outputItemId = recipe.outputItem;
          locked = locked || recipe.realmUnlockIndex > founderRealmIndex;
        }
      }
    }

    final pauseReason = full
        ? IslandProductionPauseReason.full
        : noRecipe
        ? IslandProductionPauseReason.noRecipe
        : locked
        ? IslandProductionPauseReason.realmLocked
        : IslandProductionPauseReason.none;

    if (pauseReason != IslandProductionPauseReason.none) {
      return IslandProductionReadability(
        type: state.type,
        recipeId: recipeId,
        outputItemId: outputItemId,
        pauseReason: pauseReason,
        hoursToNextItem: null,
        hoursToFull: null,
      );
    }

    final hoursToNext = _hoursUntilStoredAtLeast(
      state: state,
      allStates: allStates,
      config: config,
      founderRealmIndex: founderRealmIndex,
      targetStored: math.min(cap, stored.floorToDouble() + 1),
    );
    final hoursToFull = _hoursUntilStoredAtLeast(
      state: state,
      allStates: allStates,
      config: config,
      founderRealmIndex: founderRealmIndex,
      targetStored: cap,
    );

    final noProgress = hoursToNext == null && hoursToFull == null;
    return IslandProductionReadability(
      type: state.type,
      recipeId: recipeId,
      outputItemId: outputItemId,
      pauseReason: noProgress
          ? IslandProductionPauseReason.noProgress
          : IslandProductionPauseReason.none,
      hoursToNextItem: hoursToNext,
      hoursToFull: hoursToFull,
    );
  }

  static double? _hoursUntilStoredAtLeast({
    required IslandBuildingState state,
    required List<IslandBuildingState> allStates,
    required TaohuaIslandConfig config,
    required int founderRealmIndex,
    required double targetStored,
  }) {
    final current = state.stored;
    if (current >= targetStored) return 0;
    if (targetStored <= current) return 0;

    final horizon = config.capHours.toDouble();
    if (horizon <= 0) return null;

    double storedAfter(double hours) {
      final projected = IslandProductionService.settle(
        states: allStates,
        config: config,
        elapsedHours: hours,
        founderRealmIndex: founderRealmIndex,
      );
      for (final s in projected) {
        if (s.type == state.type) return s.stored;
      }
      return state.stored;
    }

    if (storedAfter(horizon) + 1e-9 < targetStored) return null;

    var lo = 0.0;
    var hi = horizon;
    for (var i = 0; i < 32; i++) {
      final mid = (lo + hi) / 2;
      if (storedAfter(mid) + 1e-9 >= targetStored) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return hi;
  }
}
