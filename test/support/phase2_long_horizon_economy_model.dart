import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/island_building_state.dart';
import 'package:wuxia_idle/core/domain/island_building_type.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/seclusion_map_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/taohua_island_config.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/equipment/domain/equipment_disposal.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_production_service.dart';

const phase2LongHorizonDays = <int>[7, 14, 30];

const phase2TrackedEconomyResourceIds = <String>{
  'item_mojianshi',
  'item_xinxuejiejing',
  'item_silver',
  'item_liaoshangdan',
  'item_kaifeng_fucai',
  'item_duancai',
};

const _islandRecipeIds = <String>{
  'forge_mojianshi',
  'forge_xinxue',
  'forge_duancai',
  'brew_liaoshang',
  'forge_kaifeng_fucai',
};

/// A small immutable resource vector used only by the U05 diagnostic.
class Phase2EconomyVector {
  Phase2EconomyVector([Map<String, double> values = const {}])
    : values = Map.unmodifiable({
        for (final id in phase2TrackedEconomyResourceIds) id: values[id] ?? 0.0,
      });

  final Map<String, double> values;

  double valueOf(String resourceId) => values[resourceId] ?? 0.0;

  bool get isFiniteAndNonNegative =>
      values.values.every((value) => value.isFinite && value >= 0.0);

  bool get hasAnyYield => values.values.any((value) => value > 0.0);

  Phase2EconomyVector scaled(double factor) => Phase2EconomyVector({
    for (final entry in values.entries) entry.key: entry.value * factor,
  });
}

class Phase2EnhancementSink {
  const Phase2EnhancementSink({
    required this.targetLevel,
    required this.mojianshi,
    required this.duancai,
    required this.guaranteeCrystals,
  });

  final int targetLevel;
  final int mojianshi;
  final int duancai;
  final int guaranteeCrystals;
}

class Phase2LongHorizonCell {
  const Phase2LongHorizonCell({
    required this.tier,
    required this.horizonDays,
    required this.seclusionMapType,
    required this.seclusion,
    required this.islandDedicatedRecipes,
    required this.mainlineStageIds,
    required this.mainlineDirect,
    required this.mainlineAllSell,
    required this.mainlineAllDisassemble,
    required this.towerRepeat,
  });

  final RealmTier tier;
  final int horizonDays;
  final RetreatMapType seclusionMapType;
  final Phase2EconomyVector seclusion;

  /// Each recipe is an independent capacity lane. Values must not be added as
  /// if every mutually exclusive processor recipe ran at the same time.
  final Map<String, Phase2EconomyVector> islandDedicatedRecipes;

  /// A tier-average replay profile normalized to [horizonDays] samples. This is
  /// a comparison load, not a daily-task or calendar-cadence product rule.
  final List<String> mainlineStageIds;
  final Phase2EconomyVector mainlineDirect;
  final Phase2EconomyVector mainlineAllSell;
  final Phase2EconomyVector mainlineAllDisassemble;

  /// Production settlement grants no repeat rewards for tower replay.
  final Phase2EconomyVector towerRepeat;

  Iterable<Phase2EconomyVector> get allVectors sync* {
    yield seclusion;
    yield* islandDedicatedRecipes.values;
    yield mainlineDirect;
    yield mainlineAllSell;
    yield mainlineAllDisassemble;
    yield towerRepeat;
  }
}

class Phase2LongHorizonReport {
  const Phase2LongHorizonReport({
    required this.cells,
    required this.enhancementSinks,
    required this.forgingFucaiSink,
    required this.islandRecipeOutputIds,
  });

  final List<Phase2LongHorizonCell> cells;
  final List<Phase2EnhancementSink> enhancementSinks;
  final int forgingFucaiSink;
  final Map<String, String> islandRecipeOutputIds;
}

Phase2LongHorizonReport buildPhase2LongHorizonEconomyReport(
  GameRepository repo,
) {
  final recipeOutputs = _islandRecipeOutputs(repo);
  final cells = <Phase2LongHorizonCell>[];
  for (final tier in RealmTier.values) {
    for (final days in phase2LongHorizonDays) {
      final mainline = _mainlineReplayProfile(repo, tier, days);
      cells.add(
        Phase2LongHorizonCell(
          tier: tier,
          horizonDays: days,
          seclusionMapType: _seclusionMapFor(repo, tier).mapType,
          seclusion: _seclusionCapacity(repo, tier, days),
          islandDedicatedRecipes: {
            for (final recipeId in recipeOutputs.keys)
              recipeId: _islandRecipeCapacity(repo, tier, days, recipeId),
          },
          mainlineStageIds: mainline.stageIds,
          mainlineDirect: mainline.direct,
          mainlineAllSell: mainline.allSell,
          mainlineAllDisassemble: mainline.allDisassemble,
          towerRepeat: Phase2EconomyVector(),
        ),
      );
    }
  }

  final enhancement = repo.numbers.enhancement;
  final maxTarget = enhancement.successCurve
      .map((bracket) => bracket.maxLevel)
      .reduce((a, b) => a > b ? a : b);
  final sinkTargets = <int>{
    15,
    30,
    maxTarget,
  }.where((target) => target <= maxTarget);

  return Phase2LongHorizonReport(
    cells: List.unmodifiable(cells),
    enhancementSinks: List.unmodifiable([
      for (final target in sinkTargets) _enhancementSink(repo, target),
    ]),
    forgingFucaiSink: repo.numbers.forging.slots.fold(
      0,
      (total, slot) => total + slot.fucaiCost,
    ),
    islandRecipeOutputIds: Map.unmodifiable(recipeOutputs),
  );
}

Phase2EconomyVector _seclusionCapacity(
  GameRepository repo,
  RealmTier tier,
  int horizonDays,
) {
  final config = repo.numbers.retreat;
  final map = _seclusionMapFor(repo, tier);
  var remainingHours = horizonDays * 24;
  final totals = <String, double>{};
  final startedAt = _ordinaryStart(config);

  while (remainingHours > 0) {
    final segmentHours = remainingHours > config.capHours
        ? config.capHours
        : remainingHours;
    final session = RetreatSession()
      ..saveDataId = 1
      ..mapType = map.mapType
      ..realmTierAtStart = tier
      ..startedAt = startedAt
      ..status = RetreatStatus.active;
    final settlement = SeclusionService.computeSettlement(
      session: session,
      config: config,
      passiveConfig: repo.numbers.passiveIdle,
      maps: repo.seclusionMaps,
      now: startedAt.add(Duration(hours: segmentHours)),
    );
    _add(totals, 'item_mojianshi', settlement.retreat.mojianshi.toDouble());
    _add(totals, 'item_silver', settlement.retreat.silver.toDouble());
    for (final reward in settlement.retreat.itemRewards.entries) {
      if (phase2TrackedEconomyResourceIds.contains(reward.key)) {
        _add(totals, reward.key, reward.value.toDouble());
      }
    }
    remainingHours -= segmentHours;
  }

  return Phase2EconomyVector(totals);
}

DateTime _ordinaryStart(RetreatConfig config) {
  for (var day = 1; day <= 31; day++) {
    final candidate = DateTime.utc(2026, 1, day, 12);
    if (!config.isSolarTermDay(candidate)) return candidate;
  }
  throw StateError('retreat config marks every January day as a solar term');
}

SeclusionMapDef _seclusionMapFor(GameRepository repo, RealmTier tier) {
  final unlocked =
      repo.seclusionMaps
          .where((map) => map.requiredRealm.index <= tier.index)
          .toList()
        ..sort(
          (a, b) => a.requiredRealm.index.compareTo(b.requiredRealm.index),
        );
  if (unlocked.isEmpty) {
    throw StateError('no seclusion map is unlocked for ${tier.name}');
  }
  return unlocked.last;
}

Map<String, String> _islandRecipeOutputs(GameRepository repo) {
  final outputs = <String, String>{};
  for (final building in repo.numbers.taohuaIsland.buildings.values) {
    for (final recipe in building.recipes) {
      if (_islandRecipeIds.contains(recipe.recipeId)) {
        outputs[recipe.recipeId] = recipe.outputItem;
      }
    }
  }
  if (outputs.keys.toSet().difference(_islandRecipeIds).isNotEmpty ||
      _islandRecipeIds.difference(outputs.keys.toSet()).isNotEmpty) {
    throw StateError(
      'island recipe coverage drifted: ${outputs.keys.toList()}',
    );
  }
  return outputs;
}

Phase2EconomyVector _islandRecipeCapacity(
  GameRepository repo,
  RealmTier tier,
  int horizonDays,
  String recipeId,
) {
  final config = repo.numbers.taohuaIsland;
  late final BuildingConfig processor;
  late final RecipeDef recipe;
  var found = false;
  for (final building in config.buildings.values) {
    final candidate = building.recipeById(recipeId);
    if (candidate != null) {
      processor = building;
      recipe = candidate;
      found = true;
      break;
    }
  }
  if (!found ||
      processor.realmUnlockIndex > tier.index ||
      recipe.realmUnlockIndex > tier.index) {
    return Phase2EconomyVector();
  }

  var remainingHours = horizonDays * 24;
  var produced = 0.0;
  while (remainingHours > 0) {
    final segmentHours = remainingHours > config.capHours
        ? config.capHours
        : remainingHours;
    final states = <IslandBuildingState>[
      for (final type in BuildingType.values)
        IslandBuildingState()
          ..type = type
          ..level = _maxUnlockedBuildingLevel(config.buildingOf(type), tier)
          ..stored = 0.0
          ..activeRecipeId = type == processor.type ? recipeId : null,
    ];
    final settled = IslandProductionService.settle(
      states: states,
      config: config,
      elapsedHours: segmentHours.toDouble(),
      founderRealmIndex: tier.index,
    );
    produced += settled
        .firstWhere((state) => state.type == processor.type)
        .stored;
    remainingHours -= segmentHours;
  }
  return Phase2EconomyVector({recipe.outputItem: produced});
}

int _maxUnlockedBuildingLevel(BuildingConfig config, RealmTier tier) {
  var level = 1;
  while (level < config.maxLevel &&
      config.upgradeRealmFor(level) <= tier.index) {
    level++;
  }
  return level;
}

({
  List<String> stageIds,
  Phase2EconomyVector direct,
  Phase2EconomyVector allSell,
  Phase2EconomyVector allDisassemble,
})
_mainlineReplayProfile(GameRepository repo, RealmTier tier, int horizonDays) {
  final stages = _mainlineStagesFor(repo, tier);
  final direct = <String, double>{};
  var sellSilver = 0.0;
  var disassembleMojianshi = 0.0;
  var disassembleCrystals = 0.0;

  for (final stage in stages) {
    for (final entry in stage.dropTable) {
      switch (entry) {
        case ItemDrop():
          if (phase2TrackedEconomyResourceIds.contains(
            entry.inventoryItemDefId,
          )) {
            final averageQuantity =
                (entry.quantityMin + entry.quantityMax) / 2.0;
            _add(
              direct,
              entry.inventoryItemDefId,
              averageQuantity * entry.dropChance,
            );
          }
        case EquipmentDrop():
          final equipment = repo.equipmentDefs[entry.equipmentDefId];
          if (equipment == null) {
            throw StateError('missing equipment ${entry.equipmentDefId}');
          }
          final expectedCount = entry.dropChance;
          sellSilver +=
              expectedCount *
              equipmentSellPrice(equipment.tier, 0, repo.numbers.disposal);
          final dismantled = equipmentDisassembleRewards(
            equipment.tier,
            0,
            repo.numbers.disposal,
          );
          disassembleMojianshi += expectedCount * dismantled.mojianshi;
          disassembleCrystals += expectedCount * dismantled.xinxuejiejing;
      }
    }
  }

  final scale = horizonDays / stages.length;
  return (
    stageIds: List.unmodifiable(stages.map((stage) => stage.id)),
    direct: Phase2EconomyVector(direct).scaled(scale),
    allSell: Phase2EconomyVector({'item_silver': sellSilver}).scaled(scale),
    allDisassemble: Phase2EconomyVector({
      'item_mojianshi': disassembleMojianshi,
      'item_xinxuejiejing': disassembleCrystals,
    }).scaled(scale),
  );
}

List<StageDef> _mainlineStagesFor(GameRepository repo, RealmTier tier) {
  final mainline = repo.stageDefs.values
      .where((stage) => stage.stageType == StageType.mainline)
      .toList();
  final exact = mainline.where((stage) => stage.requiredRealm == tier).toList();
  if (exact.isNotEmpty) return exact;

  final unlocked = mainline
      .where((stage) => stage.requiredRealm.index <= tier.index)
      .toList();
  if (unlocked.isEmpty) {
    throw StateError('no mainline stage is unlocked for ${tier.name}');
  }
  final highestTier = unlocked
      .map((stage) => stage.requiredRealm.index)
      .reduce((a, b) => a > b ? a : b);
  return unlocked
      .where((stage) => stage.requiredRealm.index == highestTier)
      .toList();
}

Phase2EnhancementSink _enhancementSink(GameRepository repo, int targetLevel) {
  var mojianshi = 0;
  var duancai = 0;
  var crystals = 0;
  for (var level = 1; level <= targetLevel; level++) {
    mojianshi += repo.numbers.enhancement.mojianshiCostFor(level);
    duancai += repo.numbers.enhancement.duancaiCostFor(level);
    crystals += repo.numbers.enhancement.crystalCostToGuarantee(level) ?? 0;
  }
  return Phase2EnhancementSink(
    targetLevel: targetLevel,
    mojianshi: mojianshi,
    duancai: duancai,
    guaranteeCrystals: crystals,
  );
}

void _add(Map<String, double> values, String key, double delta) {
  values.update(key, (value) => value + delta, ifAbsent: () => delta);
}
