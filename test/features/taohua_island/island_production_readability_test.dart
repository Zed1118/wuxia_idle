import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_production_readability.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_state.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  IslandBuildingState state(
    BuildingType type, {
    int level = 1,
    double stored = 0,
    String? recipe,
  }) => IslandBuildingState()
    ..type = type
    ..level = level
    ..stored = stored
    ..activeRecipeId = recipe;

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
}
