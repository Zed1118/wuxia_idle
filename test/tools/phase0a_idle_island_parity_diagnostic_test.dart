// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/island_building_state.dart';
import 'package:wuxia_idle/core/domain/island_building_type.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/defs/taohua_island_config.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_production_service.dart';

const _recipes = ['brew_ningshen', 'brew_peiyuan', 'brew_liaoshang'];
const _levels = [1, 3, 5];
const _windows = [1.0, 8.0, 24.0, 72.0, 100.0];
const _segments = 4;
const _epsilon = 1e-9;

class _Observation {
  final String recipeId;
  final int level;
  final double requestedHours;
  final double settledHours;
  final String scenario;
  final double oneShotOutput;
  final double segmentedOutput;
  final double oneShotHerb;
  final double segmentedHerb;
  final double oneShotSpring;
  final double segmentedSpring;
  final double oneShotCap;
  final double difference;
  final String bottleneck;

  const _Observation({
    required this.recipeId,
    required this.level,
    required this.requestedHours,
    required this.settledHours,
    required this.scenario,
    required this.oneShotOutput,
    required this.segmentedOutput,
    required this.oneShotHerb,
    required this.segmentedHerb,
    required this.oneShotSpring,
    required this.segmentedSpring,
    required this.oneShotCap,
    required this.difference,
    required this.bottleneck,
  });

  String csv() => [
    recipeId,
    level,
    requestedHours,
    settledHours,
    scenario,
    oneShotOutput,
    segmentedOutput,
    oneShotHerb,
    segmentedHerb,
    oneShotSpring,
    segmentedSpring,
    oneShotCap,
    difference,
    bottleneck,
  ].join(',');
}

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test('Phase 0A 丹房在线/离线 parity diagnostic', () {
    final config = repo.numbers.taohuaIsland;
    final observations = <_Observation>[];

    for (final recipeId in _recipes) {
      final recipe = config.buildingOf(BuildingType.danFang).recipeById(recipeId)!;
      for (final level in _levels) {
        for (final hours in _windows) {
          observations.add(
            _observe(
              config: config,
              recipeId: recipeId,
              level: level,
              requestedHours: hours,
              recipe: recipe,
              scenario: 'normal',
            ),
          );
        }
        final cap = config.buildingOf(BuildingType.danFang).capFor(level);
        observations.add(
          _observe(
            config: config,
            recipeId: recipeId,
            level: level,
            requestedHours: 8,
            recipe: recipe,
            scenario: 'prefilled_cap_minus_0.5',
            initialProduct: cap - 0.5,
          ),
        );
      }
    }

    expect(observations, hasLength(3 * 3 * 6));
    for (final row in observations) {
      expect(row.difference, lessThanOrEqualTo(_epsilon), reason: row.csv());
      expect(row.oneShotOutput, closeTo(row.segmentedOutput, _epsilon));
      expect(row.oneShotHerb, closeTo(row.segmentedHerb, _epsilon));
      expect(row.oneShotSpring, closeTo(row.segmentedSpring, _epsilon));
    }

    print('recipe_id,level,requested_hours,settled_hours,scenario,'
        'one_shot_output,segmented_output,one_shot_herb,segmented_herb,'
        'one_shot_spring,segmented_spring,one_shot_cap,difference,bottleneck');
    for (final row in observations) {
      print(row.csv());
    }
  });
}

_Observation _observe({
  required TaohuaIslandConfig config,
  required String recipeId,
  required int level,
  required double requestedHours,
  required RecipeDef recipe,
  required String scenario,
  double initialProduct = 0,
}) {
  List<IslandBuildingState> seed() => [
    IslandBuildingState()
      ..type = BuildingType.caoYaoYuan
      ..level = level,
    IslandBuildingState()
      ..type = BuildingType.lingQuan
      ..level = level,
    IslandBuildingState()
      ..type = BuildingType.danFang
      ..level = level
      ..stored = initialProduct
      ..activeRecipeId = recipeId,
  ];

  final settledHours = requestedHours.clamp(0.0, config.capHours.toDouble());
  final once = IslandProductionService.settle(
    states: seed(),
    config: config,
    elapsedHours: requestedHours,
    founderRealmIndex: 6,
  );
  var segmented = seed();
  for (var i = 0; i < _segments; i++) {
    segmented = IslandProductionService.settle(
      states: segmented,
      config: config,
      elapsedHours: settledHours / _segments,
      founderRealmIndex: 6,
    );
  }

  double stored(List<IslandBuildingState> states, BuildingType type) =>
      states.firstWhere((state) => state.type == type).stored;
  final oneOutput = stored(once, BuildingType.danFang);
  final segmentedOutput = stored(segmented, BuildingType.danFang);
  final difference = [
    (oneOutput - segmentedOutput).abs(),
    (stored(once, BuildingType.caoYaoYuan) -
            stored(segmented, BuildingType.caoYaoYuan))
        .abs(),
    (stored(once, BuildingType.lingQuan) -
            stored(segmented, BuildingType.lingQuan))
        .abs(),
  ].reduce((a, b) => a > b ? a : b);
  final cap = config.buildingOf(BuildingType.danFang).capFor(level).toDouble();
  final bottleneck = initialProduct >= cap - 0.5 ? 'product_cap' : 'none';

  return _Observation(
    recipeId: recipeId,
    level: level,
    requestedHours: requestedHours,
    settledHours: settledHours,
    scenario: scenario,
    oneShotOutput: oneOutput - initialProduct,
    segmentedOutput: segmentedOutput - initialProduct,
    oneShotHerb: stored(once, BuildingType.caoYaoYuan),
    segmentedHerb: stored(segmented, BuildingType.caoYaoYuan),
    oneShotSpring: stored(once, BuildingType.lingQuan),
    segmentedSpring: stored(segmented, BuildingType.lingQuan),
    oneShotCap: cap,
    difference: difference,
    bottleneck: bottleneck,
  );
}
