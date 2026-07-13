// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

import '../support/progression_battle_probe.dart';
import '../support/test_data.dart';

const _seedCount = 20;
const _csvPath =
    'test/tools/output/progression_attribute_playtest_2026-07-13.csv';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test(
    'progression playtest: 30 mainline × 3 profiles × 20 seeds',
    () {
      final stages =
          repository.stageDefs.values
              .where(
                (stage) =>
                    stage.stageType == StageType.mainline &&
                    stage.enemyTeam.isNotEmpty,
              )
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      expect(stages.length, 30);

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

      expect(rows.length, 30 * 3 * _seedCount);
      expect(
        rows.every((row) => row.ticks < progressionBattleMaxTicks),
        isTrue,
        reason: '诊断样本不得撞 maxTicks=$progressionBattleMaxTicks',
      );

      Directory('test/tools/output').createSync(recursive: true);
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
      File(_csvPath).writeAsStringSync(buffer.toString());

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
      print('progression playtest wrote ${rows.length} rows to $_csvPath');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
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
    'avgTicks=${average((row) => row.ticks).toStringAsFixed(2)}',
    'avgActionRows=${average((row) => row.actionRows).toStringAsFixed(2)}',
    'avgHpEndRatio=${average((row) => row.playerHpEnd / row.playerHpStart).toStringAsFixed(4)}',
    'avgQiStart=${average((row) => row.playerQiStart).toStringAsFixed(2)}',
    'avgQiEnd=${average((row) => row.playerQiEnd).toStringAsFixed(2)}',
    'avgQiDelta=${average((row) => row.playerQiEnd - row.playerQiStart).toStringAsFixed(2)}',
  ].join(' ');
}
