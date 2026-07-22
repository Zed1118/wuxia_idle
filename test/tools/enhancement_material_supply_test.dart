// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import '../support/test_data.dart';

const String _outputDir = 'test/tools/output';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
    Directory(_outputDir).createSync(recursive: true);
  });

  test('强化材料供需模拟:首通供给与 +15/+30/+49 期望需求同表输出', () {
    final supply = _firstClearSupply(repo);
    final to15 = _expectedDemand(repo.numbers.enhancement, 15);
    final to30 = _expectedDemand(repo.numbers.enhancement, 30);
    final to49 = _expectedDemand(repo.numbers.enhancement, 49);

    _writeSummary(supply: supply, demands: [to15, to30, to49]);

    expect(supply.mojianshi, closeTo(56.5, 0.01));
    expect(supply.xinxueJiejing, closeTo(1545.0, 0.01));

    expect(to15.guaranteeCrystalCost, 6);
    expect(to30.guaranteeCrystalCost, 112);
    expect(to49.guaranteeCrystalCost, 264);

    expect(supply.xinxueJiejing, greaterThan(to49.guaranteeCrystalCost));
    // 供给随内容规模自然增长:35 关时 515(1.95 件 +49 保底·擦 2 件线),
    // Ch8 扩 40 关后 633(≈2.4 件),Ch9 扩 45 关后 761(≈2.9 件),Ch10 扩 50 关后 932(≈3.6 件),
    // Ch11 扩 55 关后 1115(≈4.2 件),语义线放宽到「不足 5 件」保「非无约束溢出」不变式
    // (一流第二章结晶自然增至 ≈4.2 件·同 Ch10 balance 拍板放宽·spec 已知拍板)。
    // Ch12 扩 60 关后 1308(≈4.95 件·264×5=1320·仍不足 5 件·一流第三章续放宽·spec 已知拍板)。
    // Ch13 扩 65 关后 1545(≈5.85 件·264×6=1584·不足 6 件·绝顶段首章续放宽·沿 Ch12 体例·[balance] 待用户终拍)。
    expect(
      supply.xinxueJiejing,
      lessThan(to49.guaranteeCrystalCost * 6),
      reason: '65 关首通结晶支撑约 5.85 件 +49 保底,不足 6 件,不是无约束溢出',
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

void _writeSummary({required _Supply supply, required List<_Demand> demands}) {
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
