// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

const String _outputDir = 'test/tools/output';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    Directory(_outputDir).createSync(recursive: true);
  });

  test('强化材料供需模拟:首通供给与 +15/+30/+49 期望需求同表输出', () {
    final supply = _firstClearSupply(repo);
    final to15 = _expectedDemand(repo.numbers.enhancement, 15);
    final to30 = _expectedDemand(repo.numbers.enhancement, 30);
    final to49 = _expectedDemand(repo.numbers.enhancement, 49);

    _writeSummary(supply: supply, demands: [to15, to30, to49]);

    expect(supply.mojianshi, closeTo(56.5, 0.01));
    expect(supply.xinxueJiejing, closeTo(408.0, 0.01));

    expect(to15.guaranteeCrystalCost, 6);
    expect(to30.guaranteeCrystalCost, 112);
    expect(to49.guaranteeCrystalCost, 264);

    expect(supply.xinxueJiejing, greaterThan(to49.guaranteeCrystalCost));
    expect(
      supply.xinxueJiejing,
      lessThan(to49.guaranteeCrystalCost * 2),
      reason: '首通结晶足够支撑 1 件 +49 保底,但不足 2 件,不是无约束溢出',
    );
    expect(to49.naturalMojianshiExpected, greaterThan(supply.mojianshi));
    expect(
      to49.guaranteeMojianshiExpected,
      lessThan(supply.mojianshi),
      reason: '保底策略把 +14 以后压力从磨剑石转为心血结晶',
    );
  });
}

_Supply _firstClearSupply(GameRepository repo) {
  var mojianshi = 0.0;
  var xinxue = 0.0;

  for (final stage in repo.stageDefs.values) {
    final expected = _expectedItems(stage.dropTable);
    mojianshi += expected['item_mojianshi'] ?? 0;
    xinxue += expected['item_xinxuejiejing'] ?? 0;
  }
  for (final floor in repo.towerFloors) {
    final expected = _expectedItems(floor.dropTable);
    mojianshi += expected['item_mojianshi'] ?? 0;
    xinxue += expected['item_xinxuejiejing'] ?? 0;
  }

  return _Supply(mojianshi: mojianshi, xinxueJiejing: xinxue);
}

Map<String, double> _expectedItems(List<DropEntry> table) {
  final totals = <String, double>{};
  for (final entry in table) {
    if (entry is! ItemDrop) continue;
    final avgQty = (entry.quantityMin + entry.quantityMax) / 2;
    totals.update(
      entry.inventoryItemDefId,
      (value) => value + avgQty * entry.dropChance,
      ifAbsent: () => avgQty * entry.dropChance,
    );
  }
  return totals;
}

_Demand _expectedDemand(EnhancementConfig config, int targetLevel) {
  var naturalMojianshi = 0.0;
  var naturalCrystalsFromFailures = 0.0;
  var guaranteeMojianshi = 0.0;
  var guaranteeCrystalCost = 0;

  for (var level = 1; level <= targetLevel; level++) {
    final cost = config.mojianshiCostFor(level);
    final rate = config.successRateFor(level);
    final failuresBeforeSuccess = (1 - rate) / rate;
    final penalty = _penaltyCost(cost, config.materialPenaltyFor(level));

    naturalMojianshi += cost + failuresBeforeSuccess * penalty;
    naturalCrystalsFromFailures +=
        failuresBeforeSuccess * config.crystalGainPerFailure;

    final crystalCost = config.crystalCostToGuarantee(level);
    if (crystalCost == null) {
      guaranteeMojianshi += cost + failuresBeforeSuccess * penalty;
    } else {
      guaranteeCrystalCost += crystalCost;
    }
  }

  return _Demand(
    targetLevel: targetLevel,
    naturalMojianshiExpected: naturalMojianshi,
    naturalCrystalsFromFailures: naturalCrystalsFromFailures,
    guaranteeMojianshiExpected: guaranteeMojianshi,
    guaranteeCrystalCost: guaranteeCrystalCost,
  );
}

int _penaltyCost(int cost, MaterialPenalty penalty) => switch (penalty) {
      MaterialPenalty.none => 0,
      MaterialPenalty.half => cost ~/ 2,
      MaterialPenalty.full => cost,
    };

void _writeSummary({
  required _Supply supply,
  required List<_Demand> demands,
}) {
  final buf = StringBuffer()
    ..writeln('# 强化材料供需模拟 · 2026-06-28')
    ..writeln()
    ..writeln('## 首通供给期望')
    ..writeln()
    ..writeln('- 磨剑石: ${supply.mojianshi.toStringAsFixed(1)}')
    ..writeln('- 心血结晶: ${supply.xinxueJiejing.toStringAsFixed(1)}')
    ..writeln()
    ..writeln('## 单件装备强化需求')
    ..writeln()
    ..writeln('| 目标 | 自然强化磨剑石期望 | 自然失败得结晶期望 | 保底策略磨剑石期望 | 保底策略结晶消耗 |')
    ..writeln('|---:|---:|---:|---:|---:|');
  for (final d in demands) {
    buf.writeln(
      '| +${d.targetLevel} | ${d.naturalMojianshiExpected.toStringAsFixed(1)} '
      '| ${d.naturalCrystalsFromFailures.toStringAsFixed(1)} '
      '| ${d.guaranteeMojianshiExpected.toStringAsFixed(1)} '
      '| ${d.guaranteeCrystalCost} |',
    );
  }

  final outPath = '$_outputDir/enhancement_material_supply_2026-06-28.md';
  File(outPath).writeAsStringSync(buf.toString());
  print(buf.toString());
  print('enhancement_material_supply done · summary=$outPath');
}

class _Supply {
  const _Supply({required this.mojianshi, required this.xinxueJiejing});

  final double mojianshi;
  final double xinxueJiejing;
}

class _Demand {
  const _Demand({
    required this.targetLevel,
    required this.naturalMojianshiExpected,
    required this.naturalCrystalsFromFailures,
    required this.guaranteeMojianshiExpected,
    required this.guaranteeCrystalCost,
  });

  final int targetLevel;
  final double naturalMojianshiExpected;
  final double naturalCrystalsFromFailures;
  final double guaranteeMojianshiExpected;
  final int guaranteeCrystalCost;
}
