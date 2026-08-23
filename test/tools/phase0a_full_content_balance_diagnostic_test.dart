// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';

import '../support/isar_test_support.dart';
import '../support/phase0a_ch1_founder_profile.dart';
import '../support/phase0a_production_preflight_manifest.dart';
import '../support/phase0a_profile_harness.dart';

const _schools = ['gang_meng', 'ling_qiao', 'yin_rou'];
const _evidenceSeedCount = 3;
const _smokeSeedCount = 1;
const _update = 'PHASE0A_FULL_CONTENT_EVIDENCE';
const _csvPath =
    'test/tools/output/phase0a_full_content_balance_diagnostic.csv';
const _mdPath = 'test/tools/output/phase0a_full_content_balance_diagnostic.md';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test(
    'Phase 0A full content balance diagnostic',
    () async {
      final updateEvidence = Platform.environment[_update] == '1';
      final seedCount = updateEvidence ? _evidenceSeedCount : _smokeSeedCount;
      final mainlineEntries =
          repo.stageDefs.values
              .where((stage) => stage.stageType == StageType.mainline)
              .map(Phase0aProductionPreflightManifest.classifyStage)
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      final towerEntries =
          repo.towerFloors
              .map(Phase0aProductionPreflightManifest.classifyTower)
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      final manifest = [...mainlineEntries, ...towerEntries];
      final eligible = manifest
          .where((entry) => entry.status == Phase0aPreflightStatus.eligible)
          .toList();

      expect(mainlineEntries, hasLength(105));
      expect(towerEntries, hasLength(49));
      expect(manifest.map((entry) => entry.key).toSet(), hasLength(154));
      expect(eligible, hasLength(154));

      final arena = repo.numbers.phase0aArena;
      final runs = <Phase0aProfileRunObservation>[];
      final profiles = <String, CombatantSnapshot>{};
      final loadouts = <String, String>{};

      for (final school in _schools) {
        final directory = await Directory.systemTemp.createTemp(
          'phase0a_full_content_',
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
          loadouts[school] = [
            'basic=${seeded.snapshot.skillLoadout.basicAttack?.id ?? '-'}',
            for (final slot in CombatantSkillLoadout.numericSlots)
              '${slot.name}=${seeded.snapshot.skillLoadout.skillFor(slot)?.id ?? '-'}',
          ].join('; ');

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
                  deltaSeconds: arena.fixedDeltaSeconds,
                  maxTicks: arena.maxSimulationTicks,
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
        expect(run.ticks, lessThanOrEqualTo(arena.maxSimulationTicks));
        expect(run.numericCasts, hasLength(6));
        expect(run.numericHits, hasLength(6));
        expect(run.numericDamage, hasLength(6));
        expect(run.maxResolvedDamage, lessThan(1000000));
      }

      final canonicalEntry = eligible.first;
      final canonicalProfile = profiles[_schools.first]!;
      final canonicalMapping =
          canonicalEntry.kind == Phase0aPreflightContentKind.stage
          ? Phase0aStageContentMapper.map(
              stage: repo.stageDefs[canonicalEntry.id]!,
              playerSnapshot: canonicalProfile,
              numbers: repo.numbers,
            )
          : Phase0aStageContentMapper.mapTower(
              floor: repo.towerFloors.firstWhere(
                (floor) => 'tower_${floor.floorIndex}' == canonicalEntry.id,
              ),
              playerSnapshot: canonicalProfile,
              numbers: repo.numbers,
            );
      expect(
        runPhase0aProfile(
          profileId: _schools.first,
          contentId: canonicalEntry.key,
          mapping: canonicalMapping,
          numbers: repo.numbers,
          playerSnapshot: canonicalProfile,
          seed: 0,
          deltaSeconds: arena.fixedDeltaSeconds,
          maxTicks: arena.maxSimulationTicks,
        ),
        runs.first,
        reason: 'canonical 内容必须全字段可重放',
      );

      final csv = _csv(runs);
      final markdown = _markdown(
        runs,
        loadouts,
        seedCount: seedCount,
        deltaSeconds: arena.fixedDeltaSeconds,
        maxTicks: arena.maxSimulationTicks,
      );
      final csvFile = File(_csvPath);
      final mdFile = File(_mdPath);
      if (updateEvidence) {
        csvFile.parent.createSync(recursive: true);
        csvFile.writeAsStringSync(csv);
        mdFile.writeAsStringSync(markdown);
      } else {
        expect(csvFile.existsSync(), isTrue);
        expect(mdFile.existsSync(), isTrue);
        _checkCsvHeader(csvFile.readAsStringSync());
        _checkCsvHeader(csv);
      }
      print(
        'phase0a full content diagnostic: content=${eligible.length}; '
        'schools=${_schools.length}; seeds=$seedCount; runs=${runs.length}; '
        'maxDamage=${Phase0aProfileAggregate(runs).maxResolvedDamage}',
      );
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

String _csv(List<Phase0aProfileRunObservation> runs) {
  final b = StringBuffer(
    'profile,content,seed,outcome,ticks,seconds,hp_start,hp_end,qi_start,qi_max,qi_end,'
    'basic_casts,basic_hits,basic_damage,gather_casts,gather_damage,clear_casts,clear_damage',
  );
  for (var i = 1; i <= 6; i++) {
    b.write(',skill${i}_casts,skill${i}_hits,skill${i}_damage');
  }
  b.writeln(',total_player_damage,critical_hits,max_resolved_damage');
  for (final r in runs) {
    b.writeln(
      [
        r.profileId,
        r.contentId,
        r.seed,
        r.outcome,
        r.ticks,
        r.seconds.toStringAsFixed(6),
        r.hpStart,
        r.hpEnd,
        r.qiStart,
        r.qiMax,
        r.qiEnd,
        r.basicCasts,
        r.basicHits,
        r.basicDamage,
        r.gatherCasts,
        r.gatherDamage,
        r.clearCasts,
        r.clearDamage,
        for (var i = 0; i < 6; i++) ...[
          r.numericCasts[i],
          r.numericHits[i],
          r.numericDamage[i],
        ],
        r.totalPlayerDamage,
        r.criticalHits,
        r.maxResolvedDamage,
      ].join(','),
    );
  }
  return b.toString();
}

void _checkCsvHeader(String content) => expect(
  content.split('\n').first,
  startsWith('profile,content,seed,outcome,ticks'),
);

String _markdown(
  List<Phase0aProfileRunObservation> runs,
  Map<String, String> loadouts, {
  required int seedCount,
  required double deltaSeconds,
  required int maxTicks,
}) {
  final b = StringBuffer(
    '# Phase 0A full-content balance diagnostic · 2026-08-23\n\n',
  );
  b.writeln(
    '范围：105 个主线关 + 49 个塔层，三流派，固定 $seedCount 个种子，'
    '共 ${runs.length} 次 headless bot 运行。delta=${deltaSeconds}s，maxTicks=$maxTicks。',
  );
  b.writeln('这是自动画像证据，不等于真人目检或玩家体验结论；不得据此直接调玩法数值。\n');
  b.writeln('## Production loadout\n');
  for (final school in _schools) {
    b.writeln('- `$school`: ${loadouts[school]}');
  }
  b.writeln();
  b.writeln(
    '| profile | content | runs | wins | defeats | timeouts | winRate | mean ticks | p50 | p90 | mean HP% | mean Qi% | basic casts | numeric casts | max damage |',
  );
  b.writeln(
    '|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|',
  );
  for (final school in _schools) {
    for (final content
        in runs
            .where((run) => run.profileId == school)
            .map((run) => run.contentId)
            .toSet()) {
      final aggregate = Phase0aProfileAggregate(
        runs
            .where((run) => run.profileId == school && run.contentId == content)
            .toList(),
      );
      final numericCasts = aggregate.totalNumericCasts().fold(
        0,
        (a, b) => a + b,
      );
      b.writeln(
        '|$school|$content|${aggregate.runs.length}|${aggregate.wins}|${aggregate.defeats}|${aggregate.timeouts}|'
        '${(aggregate.winRate * 100).toStringAsFixed(1)}%|${aggregate.meanTicks.toStringAsFixed(1)}|'
        '${aggregate.p50Ticks}|${aggregate.p90Ticks}|${(aggregate.meanHpEndRatio * 100).toStringAsFixed(1)}%|'
        '${(aggregate.meanQiEndRatio * 100).toStringAsFixed(1)}%|${aggregate.totalBasicCasts}|$numericCasts|'
        '${aggregate.maxResolvedDamage}|',
      );
    }
  }
  final aggregate = Phase0aProfileAggregate(runs);
  b.writeln('\n## Automatic observations\n');
  b.writeln(
    '- outcomes: wins=${aggregate.wins}, defeats=${aggregate.defeats}, timeouts=${aggregate.timeouts}.',
  );
  b.writeln(
    '- max resolved damage: ${aggregate.maxResolvedDamage} (< 1,000,000).',
  );
  b.writeln(
    '- basic casts: ${aggregate.totalBasicCasts}; numeric casts: ${aggregate.totalNumericCasts().fold(0, (a, b) => a + b)}.',
  );
  b.writeln(
    '- evidence is reproducible from the fixed founder profile and seeds above.',
  );
  return b.toString();
}
