// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

import '../test/support/isar_test_support.dart';
import '../test/support/phase0a_ch1_founder_profile.dart';
import '../test/support/phase0a_production_headless_benchmark.dart';

/// Explicit benchmark entrypoint, intentionally outside test/**/*_test.dart.
/// Run through run_phase0a_headless_benchmark.py for frozen source/hardware facts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'current production mainline and tower headless wall-clock baseline',
    () async {
      final metadataPath = Platform.environment['PHASE0A_BENCHMARK_METADATA'];
      final outputPath = Platform.environment['PHASE0A_BENCHMARK_OUTPUT'];
      if (metadataPath == null || outputPath == null) {
        throw StateError('use tool/run_phase0a_headless_benchmark.py');
      }
      final output = File(outputPath);
      if (output.existsSync()) {
        throw StateError('refusing to overwrite benchmark evidence');
      }
      final metadata =
          jsonDecode(File(metadataPath).readAsStringSync())
              as Map<String, dynamic>;
      final config = metadata['config'] as Map<String, dynamic>;
      final repetitions = config['repetitions'] as int;
      final warmups = config['warmups'] as int;
      final seeds = (config['seeds'] as List<dynamic>).cast<int>();
      if (repetitions < 1 ||
          warmups < 1 ||
          seeds.isEmpty ||
          seeds.toSet().length != seeds.length) {
        throw ArgumentError(
          'repetitions/warmups must be positive; seeds nonempty and unique',
        );
      }
      await initializeTestIsarCore();
      final loadClock = Stopwatch()..start();
      final repository = await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
      loadClock.stop();
      final manifest = productionHeadlessManifest(repository);
      expect(manifest, hasLength(154));
      final arena = repository.numbers.phase0aArena;
      final rows = <Map<String, Object?>>[];
      final profileIds = <String>[];
      final profileValues = <String, Map<String, Object?>>{};
      var comparedPairs = 0;
      var profileSeedUs = 0;
      for (final school in ['gang_meng', 'ling_qiao', 'yin_rou']) {
        final directory = await Directory.systemTemp.createTemp(
          'wuxia_headless_baseline_',
        );
        try {
          final profileClock = Stopwatch()..start();
          await IsarSetup.init(directory: directory, inspector: false);
          final profile = await seedPhase0aCh1FounderProfile(
            isar: IsarSetup.instance,
            schoolId: school,
            originId: 'mountain_wanderer',
            fateId: 'balanced_seed',
            rngSeed: 20260820,
          );
          profileClock.stop();
          profileSeedUs += profileClock.elapsedMicroseconds;
          profileIds.add(profile.profileId);
          profileValues[profile.profileId] = headlessPlayerFacts(
            profile.snapshot,
          );
          for (final content in manifest) {
            for (final seed in seeds) {
              HeadlessBenchmarkRun? reference;
              // Alternate sync/async order to avoid always favoring one mode.
              for (
                var iteration = -warmups;
                iteration < repetitions;
                iteration++
              ) {
                final modes = (iteration + warmups).isEven
                    ? HeadlessBenchmarkMode.values
                    : HeadlessBenchmarkMode.values.reversed;
                for (final mode in modes) {
                  final run = await measureProductionHeadless(
                    repository: repository,
                    content: content,
                    player: profile.snapshot,
                    seed: seed,
                    mode: mode,
                  );
                  if (reference != null) {
                    try {
                      requireSameHeadlessResult(reference, run);
                    } on StateError catch (error) {
                      throw StateError(
                        '${profile.profileId}/${content.contentId}/seed=$seed/'
                        '${mode.name}/iteration=$iteration: $error',
                      );
                    }
                    comparedPairs++;
                  } else {
                    reference = run;
                  }
                  if (iteration >= 0) {
                    rows.add({
                      'profile_id': profile.profileId,
                      'content_id': content.contentId,
                      'seed': seed,
                      'repetition': iteration,
                      ...run.toJson(arena.fixedDeltaSeconds),
                    });
                  }
                }
              }
            }
          }
          print('measured $school: ${manifest.length} production entries');
        } finally {
          await IsarSetup.close();
          // This entrypoint runs under flutter_test with isolated temporary databases.
          // ignore: invalid_use_of_visible_for_testing_member
          IsarSetup.resetForTest();
          await directory.delete(recursive: true);
        }
      }
      expect(
        rows.length,
        manifest.length * profileIds.length * seeds.length * repetitions * 2,
      );
      final grouped = <String, List<Map<String, Object?>>>{};
      for (final row in rows) {
        grouped
            .putIfAbsent('${row['route']}/${row['mode']}', () => [])
            .add(row);
      }
      final groups = [
        for (final id in grouped.keys.toList()..sort())
          _aggregate(id, grouped[id]!),
      ];
      expect(grouped.keys.toSet(), {
        'typed_mainline/sync',
        'typed_mainline/async',
        'typed_tower/sync',
        'typed_tower/async',
        'legacy_tower/sync',
        'legacy_tower/async',
      });
      final report = <String, Object?>{
        'schema_version': 1,
        'run_id': metadata['run_id'],
        'source': metadata['source'],
        'comparison_key': {
          ...metadata['comparison_key'] as Map<String, dynamic>,
          'config': config,
          'profile_ids': profileIds,
          'profile_values': profileValues,
          'manifest': [
            for (final content in manifest)
              '${content.kind.name}/${content.contentId}',
          ],
          'fixed_delta_seconds': arena.fixedDeltaSeconds,
          'max_simulation_ticks': arena.maxSimulationTicks,
          'cycle_index': 1,
          'bot_policy': 'production',
          'yield_every_ticks': 32,
          'clock_scope':
              'runner including event capture; async includes event-loop yield',
        },
        'scope':
            'current mainline/tower production combat factories; founder inputs; no admission/reward persistence',
        'excluded': [
          'light_foot',
          'mass_battle',
          'gauntlet',
          'expedition',
          'boss_gauntlet',
          'inner_demon_manual_only',
          'release_or_profile_performance',
          'sustained_peak_load',
        ],
        'catalog_load_microseconds': loadClock.elapsedMicroseconds,
        'profile_seed_microseconds': profileSeedUs,
        'correctness': {
          'same_seed_equal': true,
          'compared_pairs': comparedPairs,
          'fields': [
            'route',
            'outcome',
            'ticks',
            'full_arena_state',
            'spawn_and_objective_progress',
            'ordered_events',
            'ordered_event_records',
            'all_settlement_fields',
          ],
          'comparison':
              'direct value equality within each fresh-flow seed group; no runtime hashCode digest',
        },
        'regression': {
          'status': 'NOT_EVALUATED',
          'reason':
              'requires a separate compatible baseline and explicit engineering threshold',
        },
        'groups': groups,
        'runs': rows,
      };
      output.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(report)}\n',
      );
      print(
        jsonEncode({
          'groups': groups,
          'compared_pairs': comparedPairs,
          'output': output.path,
        }),
      );
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

Map<String, Object> _aggregate(String id, List<Map<String, Object?>> rows) {
  final ticks = rows.fold<int>(
    0,
    (sum, row) => sum + (row['simulated_ticks'] as int),
  );
  final simulationUs = rows.fold<int>(
    0,
    (sum, row) => sum + (row['simulation_microseconds'] as int),
  );
  final completed = rows.where((row) => row['timed_out'] == false).length;
  if (simulationUs <= 0 || ticks <= 0) {
    throw StateError('unmeasurable benchmark group: $id');
  }
  final sortedUs =
      rows.map((row) => row['simulation_microseconds'] as int).toList()..sort();
  return {
    'id': id,
    'attempts': rows.length,
    'completed_battles': completed,
    'timeouts': rows.length - completed,
    'victories': rows.where((row) => row['outcome'] == 'victory').length,
    'defeats': rows.where((row) => row['outcome'] == 'defeat').length,
    'simulated_ticks': ticks,
    'simulation_microseconds': simulationUs,
    'simulated_ticks_per_second': ticks * 1000000 / simulationUs,
    'completed_battles_per_second': completed * 1000000 / simulationUs,
    'simulation_p50_microseconds': sortedUs[(sortedUs.length * .5).ceil() - 1],
    'simulation_p90_microseconds': sortedUs[(sortedUs.length * .9).ceil() - 1],
    'assembly_microseconds': rows.fold<int>(
      0,
      (sum, row) => sum + (row['assembly_microseconds'] as int),
    ),
    'settlement_microseconds': rows.fold<int>(
      0,
      (sum, row) => sum + (row['settlement_microseconds'] as int),
    ),
  };
}
