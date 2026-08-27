// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../support/phase2_long_horizon_economy_model.dart';
import '../support/test_data.dart';

const _receiptDirectory = 'build/phase2_wiring_receipts/U05';

void main() {
  late GameRepository repo;
  late Phase2LongHorizonReport report;

  setUpAll(() async {
    repo = await loadTestGameRepository();
    report = buildPhase2LongHorizonEconomyReport(repo);
  });

  test('U05 creates the complete 7-tier by 3-horizon matrix', () {
    expect(
      report.cells,
      hasLength(RealmTier.values.length * phase2LongHorizonDays.length),
    );
    expect(
      {
        for (final cell in report.cells)
          '${cell.tier.name}:${cell.horizonDays}',
      },
      {
        for (final tier in RealmTier.values)
          for (final days in phase2LongHorizonDays) '${tier.name}:$days',
      },
    );
    for (final cell in report.cells) {
      expect(cell.mainlineStageIds, isNotEmpty);
      expect(
        cell.islandDedicatedRecipes.keys,
        report.islandRecipeOutputIds.keys,
      );
      expect(cell.towerRepeat.hasAnyYield, isFalse);
    }
  });

  test('U05 sources are finite, non-negative, and monotonic by horizon', () {
    for (final cell in report.cells) {
      for (final vector in cell.allVectors) {
        expect(
          vector.isFiniteAndNonNegative,
          isTrue,
          reason: '${cell.tier.name}/${cell.horizonDays}',
        );
      }
      expect(
        cell.seclusion.hasAnyYield,
        isTrue,
        reason: 'seclusion must be consumed for ${cell.tier.name}',
      );
    }

    for (final tier in RealmTier.values) {
      final cells = report.cells.where((cell) => cell.tier == tier).toList()
        ..sort((a, b) => a.horizonDays.compareTo(b.horizonDays));
      for (var index = 1; index < cells.length; index++) {
        _expectNotDecreasing(
          cells[index - 1].seclusion,
          cells[index].seclusion,
        );
        _expectNotDecreasing(
          cells[index - 1].mainlineDirect,
          cells[index].mainlineDirect,
        );
        _expectNotDecreasing(
          cells[index - 1].mainlineAllSell,
          cells[index].mainlineAllSell,
        );
        _expectNotDecreasing(
          cells[index - 1].mainlineAllDisassemble,
          cells[index].mainlineAllDisassemble,
        );
        for (final recipeId in report.islandRecipeOutputIds.keys) {
          _expectNotDecreasing(
            cells[index - 1].islandDedicatedRecipes[recipeId]!,
            cells[index].islandDedicatedRecipes[recipeId]!,
          );
        }
      }
    }
  });

  test('U05 production sources cover every tracked audit resource', () {
    final covered = <String>{};
    for (final cell in report.cells) {
      for (final vector in cell.allVectors) {
        for (final entry in vector.values.entries) {
          if (entry.value > 0.0) covered.add(entry.key);
        }
      }
    }
    expect(covered, containsAll(phase2TrackedEconomyResourceIds));

    for (final recipe in report.islandRecipeOutputIds.entries) {
      expect(
        report.cells.any(
          (cell) =>
              cell.islandDedicatedRecipes[recipe.key]!.valueOf(recipe.value) >
              0.0,
        ),
        isTrue,
        reason: '${recipe.key} must consume the production island service',
      );
    }
  });

  test(
    'U05 sink anchors come from production enhancement and forging config',
    () {
      expect(report.enhancementSinks, hasLength(3));
      expect(
        report.enhancementSinks.map((sink) => sink.targetLevel),
        orderedEquals([15, 30, 49]),
      );
      for (var index = 1; index < report.enhancementSinks.length; index++) {
        final before = report.enhancementSinks[index - 1];
        final after = report.enhancementSinks[index];
        expect(after.mojianshi, greaterThanOrEqualTo(before.mojianshi));
        expect(after.duancai, greaterThanOrEqualTo(before.duancai));
        expect(
          after.guaranteeCrystals,
          greaterThanOrEqualTo(before.guaranteeCrystals),
        );
      }
      expect(
        report.forgingFucaiSink,
        repo.numbers.forging.slots.fold(
          0,
          (total, slot) => total + slot.fucaiCost,
        ),
      );
    },
  );

  test('U05 writes an ignored reviewer-readable audit matrix', () {
    final directory = Directory(_receiptDirectory)..createSync(recursive: true);
    final output = File('${directory.path}/long_horizon_economy.md');
    output.writeAsStringSync(_renderReport(report));
    expect(output.existsSync(), isTrue);
    expect(output.readAsStringSync(), contains('matrix_cells: 21'));
    print(
      'U05_ECONOMY_MATRIX cells=${report.cells.length} '
      'tiers=${RealmTier.values.length} horizons=${phase2LongHorizonDays.join(',')} '
      'tracked=${phase2TrackedEconomyResourceIds.length}',
    );
  });
}

void _expectNotDecreasing(
  Phase2EconomyVector before,
  Phase2EconomyVector after,
) {
  for (final resourceId in phase2TrackedEconomyResourceIds) {
    expect(
      after.valueOf(resourceId),
      greaterThanOrEqualTo(before.valueOf(resourceId)),
      reason: '$resourceId must not decrease as the horizon grows',
    );
  }
}

String _renderReport(Phase2LongHorizonReport report) {
  final out = StringBuffer()
    ..writeln('# U05 long-horizon economy diagnostic')
    ..writeln()
    ..writeln('matrix_cells: ${report.cells.length}')
    ..writeln('tiers: ${RealmTier.values.length}')
    ..writeln('horizons: ${phase2LongHorizonDays.join(',')}')
    ..writeln(
      'normalization: tier-average mainline replay samples; not a daily task',
    )
    ..writeln('tower_repeat_policy: zero rewards from production settlement')
    ..writeln(
      'island_policy: each recipe is an independent mutually-exclusive lane',
    )
    ..writeln()
    ..writeln(
      '| tier | days | map | seclusion | island recipes | mainline direct | '
      'all-sell | all-disassemble |',
    )
    ..writeln('|---|---:|---|---|---|---|---|---|');
  for (final cell in report.cells) {
    out.writeln(
      '| ${cell.tier.name} | ${cell.horizonDays} | '
      '${cell.seclusionMapType.name} | ${_compact(cell.seclusion)} | '
      '${cell.islandDedicatedRecipes.entries.map((entry) => '${entry.key}:${_compact(entry.value)}').join('<br>')} | '
      '${_compact(cell.mainlineDirect)} | ${_compact(cell.mainlineAllSell)} | '
      '${_compact(cell.mainlineAllDisassemble)} |',
    );
  }
  out
    ..writeln()
    ..writeln('## Sink anchors')
    ..writeln()
    ..writeln('| target | mojianshi | duancai | guarantee crystals |')
    ..writeln('|---:|---:|---:|---:|');
  for (final sink in report.enhancementSinks) {
    out.writeln(
      '| +${sink.targetLevel} | ${sink.mojianshi} | ${sink.duancai} | '
      '${sink.guaranteeCrystals} |',
    );
  }
  out.writeln('forging_fucai_all_slots: ${report.forgingFucaiSink}');
  return out.toString();
}

String _compact(Phase2EconomyVector vector) => vector.values.entries
    .where((entry) => entry.value > 0.0)
    .map((entry) => '${entry.key}=${entry.value.toStringAsFixed(2)}')
    .join(', ');
