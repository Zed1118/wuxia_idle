// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/island_building_state.dart';
import 'package:wuxia_idle/core/domain/island_building_type.dart';
import 'package:wuxia_idle/data/defs/taohua_island_config.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_production_service.dart';

const _recipes = ['brew_ningshen', 'brew_peiyuan', 'brew_liaoshang'];
const _levels = [1, 3, 5];
const _windows = [1.0, 8.0, 24.0, 72.0, 100.0];
const _segments = 4;
const _epsilon = 1e-9;
const _csvPath = 'test/tools/output/phase0a_idle_island_parity_diagnostic.csv';
const _mdPath = 'test/tools/output/phase0a_idle_island_parity_diagnostic.md';
const _updateEnv = 'UPDATE_PHASE0A_IDLE_ISLAND_PARITY_EVIDENCE';
const _header = 'recipe_id,level,requested_hours,settled_hours,scenario,'
    'one_shot_output,segmented_output,one_shot_herb,segmented_herb,'
    'one_shot_spring,segmented_spring,one_shot_cap,theoretical_output,'
    'difference,bottleneck';

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
  final double theoreticalOutput;
  final double difference;
  final String bottleneck;

  const _Observation({
    required this.recipeId, required this.level, required this.requestedHours,
    required this.settledHours, required this.scenario,
    required this.oneShotOutput, required this.segmentedOutput,
    required this.oneShotHerb, required this.segmentedHerb,
    required this.oneShotSpring, required this.segmentedSpring,
    required this.oneShotCap, required this.theoreticalOutput,
    required this.difference, required this.bottleneck,
  });

  String csv() => [
    recipeId, level, requestedHours, settledHours, scenario,
    oneShotOutput, segmentedOutput, oneShotHerb, segmentedHerb,
    oneShotSpring, segmentedSpring, oneShotCap, theoreticalOutput,
    difference, bottleneck,
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
    final observations = _collect(repo.numbers.taohuaIsland);
    expect(observations, hasLength(54 + 9 + 3));
    for (final row in observations) {
      expect(row.difference, lessThanOrEqualTo(_epsilon), reason: row.csv());
      expect(row.oneShotOutput, closeTo(row.segmentedOutput, _epsilon));
      expect(row.oneShotHerb, closeTo(row.segmentedHerb, _epsilon));
      expect(row.oneShotSpring, closeTo(row.segmentedSpring, _epsilon));
      expect(row.oneShotOutput, closeTo(row.theoreticalOutput, _epsilon));
    }
    final csv = '$_header\n${observations.map((row) => row.csv()).join('\n')}\n';
    final md = _markdown(observations);
    if (Platform.environment[_updateEnv] == '1') {
      File(_csvPath).writeAsStringSync(csv);
      File(_mdPath).writeAsStringSync(md);
    } else {
      expect(File(_csvPath).readAsStringSync(), csv,
          reason: '提交 CSV 与当前 observations 不一致，请用 UPDATE...=1 刷新');
      expect(File(_mdPath).readAsStringSync(), md,
          reason: '提交 MD 与当前 observations 不一致，请用 UPDATE...=1 刷新');
    }
  });
}

List<_Observation> _collect(TaohuaIslandConfig config) {
  final rows = <_Observation>[];
  for (final recipeId in _recipes) {
    final recipe = config.buildingOf(BuildingType.danFang).recipeById(recipeId)!;
    for (final level in _levels) {
      for (final hours in _windows) {
        rows.add(_observe(config: config, recipeId: recipeId, level: level,
            requestedHours: hours, recipe: recipe, scenario: 'normal'));
      }
      final cap = config.buildingOf(BuildingType.danFang).capFor(level);
      rows.add(_observe(config: config, recipeId: recipeId, level: level,
          requestedHours: 8, recipe: recipe,
          scenario: 'prefilled_cap_minus_0.5', initialProduct: cap - 0.5));
      rows.add(_observe(config: config, recipeId: recipeId, level: level,
          requestedHours: 8, recipe: recipe, scenario: 'herb_starved',
          omitHerbSource: true));
      if (recipeId == 'brew_liaoshang') {
        rows.add(_observe(config: config, recipeId: recipeId, level: level,
            requestedHours: 8, recipe: recipe, scenario: 'spring_starved',
            omitSpringSource: true));
      }
    }
  }
  return rows;
}

_Observation _observe({
  required TaohuaIslandConfig config,
  required String recipeId,
  required int level,
  required double requestedHours,
  required RecipeDef recipe,
  required String scenario,
  double initialProduct = 0,
  bool omitHerbSource = false,
  bool omitSpringSource = false,
}) {
  List<IslandBuildingState> seed() => [
    if (!omitHerbSource) (IslandBuildingState()
      ..type = BuildingType.caoYaoYuan ..level = 1),
    if (!omitSpringSource) (IslandBuildingState()
      ..type = BuildingType.lingQuan ..level = 1),
    IslandBuildingState() ..type = BuildingType.danFang ..level = level
      ..stored = initialProduct ..activeRecipeId = recipeId,
  ];
  final settledHours = requestedHours.clamp(0.0, config.capHours.toDouble());
  final once = IslandProductionService.settle(
    states: seed(), config: config, elapsedHours: requestedHours,
    founderRealmIndex: 6);
  var segmented = seed();
  for (var i = 0; i < _segments; i++) {
    segmented = IslandProductionService.settle(
      states: segmented, config: config, elapsedHours: settledHours / _segments,
      founderRealmIndex: 6);
  }
  double stored(List<IslandBuildingState> states, BuildingType type) =>
      states.where((state) => state.type == type)
          .fold(0.0, (sum, state) => sum + state.stored);
  final oneOutput = stored(once, BuildingType.danFang) - initialProduct;
  final segmentedOutput = stored(segmented, BuildingType.danFang) - initialProduct;
  final danCfg = config.buildingOf(BuildingType.danFang);
  final synergy = config.synergies.rateMultiplierFor(
    target: BuildingType.danFang,
    buildingLevels: [
      if (!omitSpringSource)
        const IslandBuildingLevel(type: BuildingType.lingQuan, level: 1),
      IslandBuildingLevel(type: BuildingType.danFang, level: level),
    ], founderRealmIndex: 6, buildings: config.buildings);
  final want = recipe.ratePerHour * synergy * level * settledHours;
  final herbCfg = config.buildingOf(BuildingType.caoYaoYuan);
  final springCfg = config.buildingOf(BuildingType.lingQuan);
  final herbAvailable = omitHerbSource ? 0.0 :
      (herbCfg.baseRatePerHour * settledHours).clamp(0.0, herbCfg.capFor(1).toDouble());
  final springAvailable = omitSpringSource ? 0.0 :
      (springCfg.baseRatePerHour * settledHours).clamp(0.0, springCfg.capFor(1).toDouble());
  final herbLimit = herbAvailable / (recipe.inputPerOutput / synergy);
  final springLimit = recipe.secondaryInputPerOutput > 0
      ? springAvailable / (recipe.secondaryInputPerOutput / synergy)
      : double.infinity;
  final cap = danCfg.capFor(level).toDouble();
  final limits = <String, double>{
    'rate': want, 'herb': herbLimit, 'spring': springLimit,
    'product_cap': cap - initialProduct,
  };
  final minLimit = limits.values.reduce((a, b) => a < b ? a : b);
  final theoretical = minLimit.clamp(0.0, double.infinity);
  final bottleneck = limits.entries.where((entry) =>
      (entry.value - minLimit).abs() <= _epsilon).map((entry) => entry.key).join('|');
  final difference = [
    (oneOutput - segmentedOutput).abs(),
    (stored(once, BuildingType.caoYaoYuan) - stored(segmented, BuildingType.caoYaoYuan)).abs(),
    (stored(once, BuildingType.lingQuan) - stored(segmented, BuildingType.lingQuan)).abs(),
  ].reduce((a, b) => a > b ? a : b);
  return _Observation(
    recipeId: recipeId, level: level, requestedHours: requestedHours,
    settledHours: settledHours, scenario: scenario, oneShotOutput: oneOutput,
    segmentedOutput: segmentedOutput,
    oneShotHerb: stored(once, BuildingType.caoYaoYuan),
    segmentedHerb: stored(segmented, BuildingType.caoYaoYuan),
    oneShotSpring: stored(once, BuildingType.lingQuan),
    segmentedSpring: stored(segmented, BuildingType.lingQuan),
    oneShotCap: cap, theoreticalOutput: theoretical,
    difference: difference, bottleneck: bottleneck);
}

String _markdown(List<_Observation> rows) {
  final groups = <String, List<_Observation>>{};
  for (final row in rows) {
    groups.putIfAbsent(row.recipeId, () => []).add(row);
  }
  final lines = <String>[
    '# Phase 0A 丹房在线/离线一致性诊断', '',
    '本文件由同一组 observations 生成；非更新模式逐字校验此文件与 CSV。', '',
    '- 配方：${_recipes.join('、')}；丹房等级：${_levels.join('、')}。',
    '- 请求窗口：${_windows.join('、')} 小时；分段数：$_segments；场景总数：${rows.length}。', '',
    '| 配方 | 场景数 | 最大差异 | 瓶颈分类 |', '|---|---:|---:|---|',
  ];
  for (final entry in groups.entries) {
    final maxDiff = entry.value.map((r) => r.difference).reduce((a, b) => a > b ? a : b);
    final bottlenecks = entry.value.map((r) => r.bottleneck).toSet().toList()..sort();
    lines.add('| `${entry.key}` | ${entry.value.length} | $maxDiff | ${bottlenecks.join(', ')} |');
  }
  lines.addAll(['', '理论产量由生产配置推导：`min(rate, herb, spring, product_cap)`。',
    '正常场景使用合法最低源建筑等级 1；herb_starved/spring_starved 移除对应源建筑形成零可用量 fixture，丹房等级仍为 1/3/5。',
    '一次结算与等分分段结算差异硬断言 `<= $_epsilon`。']);
  return '${lines.join('\n')}\n';
}
