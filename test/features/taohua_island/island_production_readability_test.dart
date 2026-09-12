import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_production_readability.dart';
import 'package:wuxia_idle/core/domain/island_building_state.dart';
import 'package:wuxia_idle/core/domain/island_building_type.dart';
import '../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  IslandBuildingState state(
    BuildingType type, {
    int level = 1,
    double stored = 0,
    String? recipe,
  }) {
    final state = IslandBuildingState()
      ..type = type
      ..level = level
      ..activeRecipeId = recipe;
    if (recipe == null) {
      state.stored = stored;
    } else {
      final output = GameRepository.instance.numbers.taohuaIsland
          .buildingOf(type)
          .recipeById(recipe)!
          .outputItem;
      state.setProductStored(output, stored);
    }
    return state;
  }

  test('source 建筑从现有产速派生下一件与满仓时间', () {
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    final states = [state(BuildingType.tieJiangChang, level: 2, stored: 50)];

    final intel = IslandProductionReadability.from(
      state: states.single,
      allStates: states,
      config: cfg,
      founderRealmIndex: 6,
    );

    expect(intel.outputItemId, 'item_jingtie');
    expect(intel.pauseReason, IslandProductionPauseReason.none);
    expect(intel.hoursToNextItem, closeTo(1 / 12, 1e-4));
    expect(intel.hoursToFull, closeTo((900 - 50) / 12, 1e-4));
  });

  test('processor 建筑通过 settle 探测协同后的下一件时间', () {
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    final tie = state(BuildingType.tieJiangChang, level: 2, stored: 50);
    final zao = state(
      BuildingType.daZaoTai,
      stored: 3,
      recipe: 'forge_mojianshi',
    );
    final states = [tie, zao];

    final intel = IslandProductionReadability.from(
      state: zao,
      allStates: states,
      config: cfg,
      founderRealmIndex: 6,
    );

    expect(intel.recipeId, 'forge_mojianshi');
    expect(intel.outputItemId, 'item_mojianshi');
    expect(intel.pauseReason, IslandProductionPauseReason.none);
    expect(intel.hoursToNextItem, closeTo(1 / (1.5 * 1.04), 1e-4));
    expect(intel.hoursToFull, isNull, reason: '当前配置 72h 内不能从 3 件涨到 120 件满仓');
  });

  test('未选配方与满仓状态不估算剩余时间', () {
    final cfg = GameRepository.instance.numbers.taohuaIsland;
    final idleDan = state(BuildingType.danFang);
    final fullTie = state(BuildingType.tieJiangChang, stored: 450);

    final idleIntel = IslandProductionReadability.from(
      state: idleDan,
      allStates: [idleDan],
      config: cfg,
      founderRealmIndex: 6,
    );
    expect(idleIntel.pauseReason, IslandProductionPauseReason.noRecipe);
    expect(idleIntel.hoursToNextItem, isNull);
    expect(idleIntel.hoursToFull, isNull);

    final fullIntel = IslandProductionReadability.from(
      state: fullTie,
      allStates: [fullTie],
      config: cfg,
      founderRealmIndex: 6,
    );
    expect(fullIntel.pauseReason, IslandProductionPauseReason.full);
    expect(fullIntel.hoursToNextItem, isNull);
    expect(fullIntel.hoursToFull, isNull);
  });

  test(
    'next item uses only active product fraction while fullness uses all stock',
    () {
      final cfg = GameRepository.instance.numbers.taohuaIsland;
      final source = state(BuildingType.tieJiangChang, stored: 100);
      final forge = state(BuildingType.daZaoTai, recipe: 'forge_mojianshi')
        ..setProductStored('item_mojianshi', 0.25)
        ..setProductStored('item_xinxuejiejing', 0.6);
      final intel = IslandProductionReadability.from(
        state: forge,
        allStates: [source, forge],
        config: cfg,
        founderRealmIndex: 3,
      );
      expect(intel.hoursToNextItem, closeTo(0.75 / (1.5 * 1.02), 1e-4));
      forge.setProductStored('item_xinxuejiejing', 119.5);
      final nearlyFull = IslandProductionReadability.from(
        state: forge,
        allStates: [source, forge],
        config: cfg,
        founderRealmIndex: 3,
      );
      expect(
        nearlyFull.hoursToNextItem,
        isNull,
        reason: 'Remaining shared capacity cannot fit the next whole item.',
      );
      expect(nearlyFull.hoursToFull, closeTo(0.25 / (1.5 * 1.02), 1e-4));
    },
  );
}
