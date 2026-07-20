// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

import '../support/progression_battle_probe.dart';
import '../support/test_data.dart';

const _seedCount = 50;
// 主线关总数(10 章 × 5 关 = 50·2026-07-20 Ch10 中州一流首章扩;新增主线章时改此一处)。
const _mainlineStageCount = 50;
const _csvPath =
    'test/tools/output/progression_attribute_playtest_2026-07-13.csv';
const _updateEvidenceEnvironment = 'UPDATE_PROGRESSION_PLAYTEST_EVIDENCE';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test(
    'progression playtest: $_mainlineStageCount mainline × 3 profiles × $_seedCount seeds',
    () {
      final evidenceFile = File(_csvPath);
      expect(evidenceFile.existsSync(), isTrue);
      final evidenceBytesBefore = evidenceFile.readAsBytesSync();
      final evidenceModifiedBefore = evidenceFile.lastModifiedSync();
      final stages =
          repository.stageDefs.values
              .where(
                (stage) =>
                    stage.stageType == StageType.mainline &&
                    stage.enemyTeam.isNotEmpty,
              )
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      expect(stages.length, _mainlineStageCount);

      final rows = <ProgressionBattleObservation>[];
      for (final stage in stages) {
        for (final profile in ProgressionBuildProfile.values) {
          for (var seed = 0; seed < _seedCount; seed++) {
            rows.add(
              probeMainlineStage(
                repository: repository,
                stage: stage,
                profile: profile,
                seed: seed,
              ),
            );
          }
        }
      }

      expect(rows.length, _mainlineStageCount * 3 * _seedCount);
      final csv = _encodeCsv(rows);
      _validateCsvStructure(csv);
      final maxTick = rows
          .map((row) => row.ticks)
          .reduce((left, right) => left > right ? left : right);

      if (Platform.environment[_updateEvidenceEnvironment] == '1') {
        _writeAtomically(evidenceFile, csv);
        print('updated evidence: $_csvPath (${rows.length} rows)');
      } else {
        final tempDirectory = Directory.systemTemp.createTempSync(
          'progression_playtest_',
        );
        try {
          final temporaryCsv = File('${tempDirectory.path}/playtest.csv');
          _writeAtomically(temporaryCsv, csv);
          _validateCsvStructure(temporaryCsv.readAsStringSync());
          print(
            'progression playtest validated ${rows.length} rows in '
            '${temporaryCsv.path}; tracked evidence unchanged',
          );
        } finally {
          tempDirectory.deleteSync(recursive: true);
        }
        expect(
          evidenceFile.readAsBytesSync(),
          orderedEquals(evidenceBytesBefore),
        );
        expect(evidenceFile.lastModifiedSync(), evidenceModifiedBefore);
      }

      print('progression playtest observed maxTick=$maxTick');
      print('PROFILE_SUMMARY');
      for (final profile in ProgressionBuildProfile.values) {
        final profileRows = rows
            .where((row) => row.profile == profile)
            .toList();
        print(_summarize(profile.name, profileRows));
      }
      print('STAGE_SUMMARY');
      for (final stage in stages) {
        for (final profile in ProgressionBuildProfile.values) {
          final stageRows = rows
              .where((row) => row.stageId == stage.id && row.profile == profile)
              .toList();
          print(_summarize('${stage.id}/${profile.name}', stageRows));
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

String _encodeCsv(List<ProgressionBattleObservation> rows) {
  final buffer = StringBuffer()
    ..writeln(
      'stage_id,profile,seed,result,ticks,player_hp_start,'
      'player_hp_end,player_qi_start,player_qi_end,action_rows',
    );
  for (final row in rows) {
    buffer.writeln(
      [
        row.stageId,
        row.profile.name,
        row.seed,
        row.result.name,
        row.ticks,
        row.playerHpStart,
        row.playerHpEnd,
        row.playerQiStart,
        row.playerQiEnd,
        row.actionRows,
      ].join(','),
    );
  }
  return buffer.toString();
}

void _validateCsvStructure(String csv) {
  const header =
      'stage_id,profile,seed,result,ticks,player_hp_start,player_hp_end,'
      'player_qi_start,player_qi_end,action_rows';
  final lines = const LineSplitter().convert(csv);
  expect(
    lines,
    hasLength(
      1 +
          _mainlineStageCount *
              ProgressionBuildProfile.values.length *
              _seedCount,
    ),
  );
  expect(lines.first, header);

  final combinations = <String>{};
  final stages = <String>{};
  final profileCounts = <String, int>{};
  final seeds = <int>{};
  for (final line in lines.skip(1)) {
    final fields = line.split(',');
    expect(fields, hasLength(10));
    stages.add(fields[0]);
    profileCounts.update(fields[1], (count) => count + 1, ifAbsent: () => 1);
    final seed = int.parse(fields[2]);
    seeds.add(seed);
    expect(combinations.add('${fields[0]}/${fields[1]}/$seed'), isTrue);
    int.parse(fields[4]);
    for (final index in [5, 6, 7, 8, 9]) {
      int.parse(fields[index]);
    }
  }
  expect(stages, hasLength(_mainlineStageCount));
  expect(profileCounts, {
    for (final profile in ProgressionBuildProfile.values)
      profile.name: _mainlineStageCount * _seedCount,
  });
  expect(seeds, Set<int>.from(List<int>.generate(_seedCount, (seed) => seed)));
  expect(
    combinations,
    hasLength(
      _mainlineStageCount * ProgressionBuildProfile.values.length * _seedCount,
    ),
  );
}

void _writeAtomically(File destination, String contents) {
  destination.parent.createSync(recursive: true);
  final temporary = File(
    '${destination.path}.tmp.$pid.${DateTime.now().microsecondsSinceEpoch}',
  );
  try {
    temporary.writeAsStringSync(contents, flush: true);
    temporary.renameSync(destination.path);
  } finally {
    if (temporary.existsSync()) {
      temporary.deleteSync();
    }
  }
}

String _summarize(String label, List<ProgressionBattleObservation> rows) {
  final leftWins = rows
      .where((row) => row.result == BattleResult.leftWin)
      .length;
  final rightWins = rows
      .where((row) => row.result == BattleResult.rightWin)
      .length;
  final draws = rows.where((row) => row.result == BattleResult.draw).length;
  double average(num Function(ProgressionBattleObservation row) value) =>
      rows.fold<double>(0, (sum, row) => sum + value(row)) / rows.length;

  return [
    label,
    'samples=${rows.length}',
    'leftWin=$leftWins',
    'rightWin=$rightWins',
    'draw=$draws',
    'winRate=${(leftWins / rows.length * 100).toStringAsFixed(2)}%',
    'avgTicks=${average((row) => row.ticks).toStringAsFixed(3)}',
    'avgActionRows=${average((row) => row.actionRows).toStringAsFixed(2)}',
    'avgHpEndRatio=${average((row) => row.playerHpEnd / row.playerHpStart).toStringAsFixed(4)}',
    'avgQiStart=${average((row) => row.playerQiStart).toStringAsFixed(2)}',
    'avgQiEnd=${average((row) => row.playerQiEnd).toStringAsFixed(2)}',
    'avgQiDelta=${average((row) => row.playerQiEnd - row.playerQiStart).toStringAsFixed(2)}',
  ].join(' ');
}
