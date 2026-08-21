// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../support/isar_test_support.dart';
import '../support/phase0a_ch1_founder_profile.dart';
import '../support/phase0a_production_preflight_manifest.dart';
import '../support/phase0a_profile_harness.dart';

const _schools = ['gang_meng', 'ling_qiao', 'yin_rou'];
const _fullSeedCountVariable = 'PHASE0A_PREFLIGHT_FULL';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test(
    'Phase 0A production migration preflight',
    () async {
      final seedCount = Platform.environment[_fullSeedCountVariable] == '1'
          ? 10
          : 1;
      final stageEntries =
          repo.stageDefs.values
              .where(
                (stage) =>
                    stage.stageType == StageType.mainline &&
                    (stage.chapterIndex ?? 0) >= 2,
              )
              .map(Phase0aProductionPreflightManifest.classifyStage)
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      final towerEntries =
          repo.towerFloors
              .map(Phase0aProductionPreflightManifest.classifyTower)
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      final manifest = [...stageEntries, ...towerEntries];
      final eligible = manifest
          .where((entry) => entry.status == Phase0aPreflightStatus.eligible)
          .toList();

      expect(manifest, hasLength(149));
      expect(manifest.map((entry) => entry.key).toSet(), hasLength(149));
      // charge/破招纵切(2026-08-22):24 条 phase/charge 内容转 eligible。
      expect(stageEntries.where(_isEligible), hasLength(92));
      expect(towerEntries.where(_isEligible), hasLength(46));

      final arena = repo.numbers.phase0aArena;
      final delta = arena.fixedDeltaSeconds;
      final maxTicks = arena.maxSimulationTicks;
      final runs = <Phase0aProfileRunObservation>[];
      final profiles = <String, CombatantSnapshot>{};

      for (final school in _schools) {
        final directory = await Directory.systemTemp.createTemp(
          'phase0a_preflight_',
        );
        try {
          await IsarSetup.init(directory: directory, inspector: false);
          final seeded = await seedPhase0aCh1FounderProfile(
            isar: IsarSetup.instance,
            schoolId: school,
            originId: 'mountain_wanderer',
            fateId: 'balanced_seed',
            rngSeed: 20260820,
          );
          profiles[school] = seeded.snapshot;
          for (final entry in eligible) {
            final mapping = switch (entry.kind) {
              Phase0aPreflightContentKind.stage =>
                Phase0aStageContentMapper.map(
                  stage: repo.stageDefs[entry.id]!,
                  playerSnapshot: seeded.snapshot,
                  numbers: repo.numbers,
                ),
              Phase0aPreflightContentKind.tower =>
                Phase0aStageContentMapper.mapTower(
                  floor: repo.towerFloors.firstWhere(
                    (floor) => 'tower_${floor.floorIndex}' == entry.id,
                  ),
                  playerSnapshot: seeded.snapshot,
                  numbers: repo.numbers,
                ),
            };
            for (var seed = 0; seed < seedCount; seed++) {
              runs.add(
                runPhase0aProfile(
                  profileId: school,
                  contentId: entry.key,
                  mapping: mapping,
                  numbers: repo.numbers,
                  playerSnapshot: seeded.snapshot,
                  seed: seed,
                  deltaSeconds: delta,
                  maxTicks: maxTicks,
                ),
              );
            }
          }
        } finally {
          await IsarSetup.close();
          await directory.delete(recursive: true);
        }
      }

      final expectedRuns = _schools.length * eligible.length * seedCount;
      expect(runs, hasLength(expectedRuns));
      expect(
        runs
            .map((run) => '${run.profileId}/${run.contentId}/${run.seed}')
            .toSet(),
        hasLength(expectedRuns),
      );
      for (final run in runs) {
        expect(['victory', 'defeat', 'timeout'], contains(run.outcome));
        expect(run.ticks, lessThanOrEqualTo(maxTicks));
        expect(run.numericCasts, hasLength(6));
        expect(run.numericHits, hasLength(6));
        expect(run.numericDamage, hasLength(6));
        expect(run.maxResolvedDamage, lessThan(1000000));
      }

      final canonicalEntry = eligible.first;
      final canonicalProfile = profiles[_schools.first]!;
      final canonicalMapping = Phase0aStageContentMapper.map(
        stage: repo.stageDefs[canonicalEntry.id]!,
        playerSnapshot: canonicalProfile,
        numbers: repo.numbers,
      );
      final canonical = runPhase0aProfile(
        profileId: _schools.first,
        contentId: canonicalEntry.key,
        mapping: canonicalMapping,
        numbers: repo.numbers,
        playerSnapshot: canonicalProfile,
        seed: 0,
        deltaSeconds: delta,
        maxTicks: maxTicks,
      );
      expect(canonical, runs.first, reason: 'canonical 内容必须全字段可重放');

      final aggregate = Phase0aProfileAggregate(runs);
      final skipCounts = <String, int>{};
      for (final entry in manifest.where(
        (entry) => entry.status == Phase0aPreflightStatus.skipped,
      )) {
        skipCounts.update(
          entry.skipReason!,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      // 硬断言:剩余 skip 精确为 vulnerability 8 + guardian 2 +
      // unsupported_win_condition 1,不得出现第四种原因。
      expect(skipCounts, {
        'unsupported_vulnerability_window': 8,
        'unsupported_guardian_ward': 2,
        'unsupported_win_condition': 1,
      });
      print(
        'phase0a production preflight: manifest=${manifest.length}; '
        'eligible=${eligible.length}; skipped=${manifest.length - eligible.length}; '
        'runs=${runs.length}; wins=${aggregate.wins}; '
        'defeats=${aggregate.defeats}; timeouts=${aggregate.timeouts}; '
        'maxDamage=${aggregate.maxResolvedDamage}; skipReasons=$skipCounts',
      );
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

bool _isEligible(Phase0aPreflightManifestEntry entry) =>
    entry.status == Phase0aPreflightStatus.eligible;
