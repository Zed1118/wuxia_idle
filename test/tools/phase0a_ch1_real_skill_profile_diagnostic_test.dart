// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import '../support/isar_test_support.dart';
import '../support/phase0a_ch1_founder_profile.dart';
import '../support/phase0a_ch1_skill_profile.dart';

const _stages = [
  'stage_01_01',
  'stage_01_02',
  'stage_01_03',
  'stage_01_04',
  'stage_01_05',
];
const _schools = ['gang_meng', 'ling_qiao', 'yin_rou'];
const _evidenceSeedCount = 100;
const _smokeSeedCount = 2;
const _update = 'UPDATE_PHASE0A_CH1_PROFILE_EVIDENCE';
const _csvPath =
    'test/tools/output/phase0a_ch1_real_skill_profile_2026-08-20.csv';
const _mdPath =
    'test/tools/output/phase0a_ch1_real_skill_profile_2026-08-20.md';

void main() {
  late GameRepository repo;
  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await GameRepository.loadAllDefs(
      loader: (p) => File(p).readAsString(),
    );
  });
  test(
    'Phase 0A Ch1 real-skill profile diagnostic',
    () async {
      final updateEvidence = Platform.environment[_update] == '1';
      final seedCount = updateEvidence ? _evidenceSeedCount : _smokeSeedCount;
      final arena = repo.numbers.phase0aArena;
      final delta = arena.fixedDeltaSeconds;
      final maxTicks = (arena.maxBattleSeconds / delta).ceil();
      final rows = <Phase0aCh1RunObservation>[];
      final profiles = <String, CombatantSnapshot>{};
      final loadouts = <String, String>{};
      for (final school in _schools) {
        final dir = await Directory.systemTemp.createTemp('phase0a_profile_');
        try {
          await IsarSetup.init(directory: dir, inspector: false);
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
              '${slot.name}='
                  '${seeded.snapshot.skillLoadout.skillFor(slot)?.id ?? '-'}',
          ].join('; ');
          for (final stageId in _stages) {
            final stage = repo.stageDefs[stageId]!;
            for (var seed = 0; seed < seedCount; seed++) {
              rows.add(
                runPhase0aCh1Profile(
                  profileId: school,
                  stage: stage,
                  playerSnapshot: seeded.snapshot,
                  numbers: repo.numbers,
                  seed: seed,
                  deltaSeconds: delta,
                  maxTicks: maxTicks,
                ),
              );
            }
          }
        } finally {
          await IsarSetup.close();
          await dir.delete(recursive: true);
        }
      }
      final expectedRuns = _schools.length * _stages.length * seedCount;
      expect(rows, hasLength(expectedRuns));
      expect(
        rows.map((r) => '${r.profileId}/${r.stageId}/${r.seed}').toSet(),
        hasLength(expectedRuns),
      );
      for (final school in _schools) {
        for (final stageId in _stages) {
          expect(
            rows
                .where(
                  (run) => run.profileId == school && run.stageId == stageId,
                )
                .length,
            seedCount,
          );
        }
      }
      for (final r in rows) {
        expect(['victory', 'defeat', 'timeout'], contains(r.outcome));
        expect(r.numericCasts, hasLength(6));
        expect(r.numericHits, hasLength(6));
        expect(r.numericDamage, hasLength(6));
        expect(r.maxResolvedDamage, lessThan(1000000));
      }
      final canonical = runPhase0aCh1Profile(
        profileId: _schools.first,
        stage: repo.stageDefs[_stages.first]!,
        playerSnapshot: profiles[_schools.first]!,
        numbers: repo.numbers,
        seed: 0,
        deltaSeconds: delta,
        maxTicks: maxTicks,
      );
      expect(canonical, rows.first, reason: 'canonical seed 必须全字段可重放');
      final csv = _csv(rows);
      final md = _markdown(rows, loadouts, delta, maxTicks);
      final csvFile = File(_csvPath), mdFile = File(_mdPath);
      if (updateEvidence) {
        csvFile.parent.createSync(recursive: true);
        csvFile.writeAsStringSync(csv);
        mdFile.writeAsStringSync(md);
      } else {
        expect(csvFile.existsSync(), isTrue);
        expect(mdFile.existsSync(), isTrue);
        _checkHeader(csvFile.readAsStringSync());
        _checkHeader(csv);
      }
      print(
        'phase0a Ch1 profile: ${rows.length} runs '
        '(${updateEvidence ? 'evidence' : 'smoke'}); '
        'maxTicks=$maxTicks; delta=${delta}s',
      );
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

String _csv(List<Phase0aCh1RunObservation> rs) {
  final b = StringBuffer(
    'profile,stage,seed,outcome,ticks,seconds,hp_end_pct,qi_end_pct,basic_casts,basic_damage,gather_casts,gather_damage,clear_casts,clear_damage',
  );
  for (var i = 1; i <= 6; i++) {
    b.write(',skill${i}_casts,skill${i}_damage');
  }
  b.writeln(',max_resolved_damage');
  for (final r in rs) {
    b.writeln(
      [
        r.profileId,
        r.stageId,
        r.seed,
        r.outcome,
        r.ticks,
        r.seconds.toStringAsFixed(6),
        r.hpEndRatio.toStringAsFixed(6),
        r.qiEndRatio.toStringAsFixed(6),
        r.basicCasts,
        r.basicDamage,
        r.gatherCasts,
        r.gatherDamage,
        r.clearCasts,
        r.clearDamage,
        for (var i = 0; i < 6; i++) ...[r.numericCasts[i], r.numericDamage[i]],
        r.maxResolvedDamage,
      ].join(','),
    );
  }
  return b.toString();
}

void _checkHeader(String s) => expect(
  const LineSplitter().convert(s).first,
  startsWith('profile,stage,seed,outcome'),
);
String _markdown(
  List<Phase0aCh1RunObservation> rs,
  Map<String, String> loadouts,
  double delta,
  int maxTicks,
) {
  final b = StringBuffer('# Phase 0A Ch1 real-skill profile · 2026-08-20\n\n');
  b.writeln(
    'headless bot ≠ 真人；三个 profile 来自生产创建页，origin=mountain_wanderer，fate=balanced_seed，固定 rngSeed=20260820。',
  );
  b.writeln(
    '当前 Ch1 autoFill 槽事实由生产 snapshot 生成；无数值调整。delta=${delta}s，maxTicks=$maxTicks。\n',
  );
  b.writeln('## Production loadout\n');
  for (final school in _schools) {
    b.writeln('- `$school`: ${loadouts[school]}');
  }
  b.writeln();
  b.writeln(
    '| profile | stage | runs | wins | defeats | timeouts | winRate | mean ticks | p50 | p90 | mean HP% | mean Qi% | max damage |',
  );
  b.writeln('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
  for (final p in _schools) {
    for (final s in _stages) {
      final a = Phase0aCh1ProfileAggregate(
        rs.where((r) => r.profileId == p && r.stageId == s).toList(),
      );
      b.writeln(
        '|$p|$s|${a.runs.length}|${a.wins}|${a.defeats}|${a.timeouts}|${(a.winRate * 100).toStringAsFixed(1)}%|${a.meanTicks.toStringAsFixed(1)}|${a.p50Ticks}|${a.p90Ticks}|${(a.meanHpEndRatio * 100).toStringAsFixed(1)}%|${(a.meanQiEndRatio * 100).toStringAsFixed(1)}%|${a.maxResolvedDamage}|',
      );
    }
  }
  b.writeln('\n## Skill usage totals\n');
  b.writeln(
    '| profile | basic c/d | Q c/d | R c/d | 1 c/d | 2 c/d | 3 c/d | 4 c/d | 5 c/d | 6 c/d |',
  );
  b.writeln('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
  for (final school in _schools) {
    final aggregate = Phase0aCh1ProfileAggregate(
      rs.where((run) => run.profileId == school).toList(),
    );
    final casts = aggregate.totalNumericCasts();
    final damage = aggregate.totalNumericDamage();
    b.writeln(
      '|$school|${aggregate.totalBasicCasts}/${aggregate.totalBasicDamage}|'
      '${aggregate.totalGatherCasts}/${aggregate.totalGatherDamage}|'
      '${aggregate.totalClearCasts}/${aggregate.totalClearDamage}|'
      '${[for (var i = 0; i < 6; i++) '${casts[i]}/${damage[i]}'].join('|')}|',
    );
  }
  final allAggregate = Phase0aCh1ProfileAggregate(rs);
  final numericCastTotal = allAggregate.totalNumericCasts().fold(
    0,
    (sum, value) => sum + value,
  );
  final stageAggregates = [
    for (final school in _schools)
      for (final stage in _stages)
        (
          school,
          stage,
          Phase0aCh1ProfileAggregate(
            rs
                .where((run) => run.profileId == school && run.stageId == stage)
                .toList(),
          ),
        ),
  ];
  stageAggregates.sort((a, b) => a.$3.winRate.compareTo(b.$3.winRate));
  final weakest = stageAggregates.first;
  b.writeln('\n## Automatic observations\n');
  b.writeln('- timeout: ${allAggregate.timeouts}/${rs.length}.');
  b.writeln('- numeric 1–6 casts: $numericCastTotal.');
  b.writeln(
    '- lowest bot win rate: `${weakest.$1}/${weakest.$2}` '
    '${(weakest.$3.winRate * 100).toStringAsFixed(1)}%.',
  );
  b.writeln(
    '- max resolved damage: ${allAggregate.maxResolvedDamage} (< 1,000,000).',
  );
  return b.toString();
}
