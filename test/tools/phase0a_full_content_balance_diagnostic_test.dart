// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_proficiency.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../support/isar_test_support.dart';
import '../support/phase0a_ch1_founder_profile.dart';
import '../support/phase0a_profile_harness.dart';
import '../support/phase0a_production_preflight_manifest.dart';

const _schools = ['gang_meng', 'ling_qiao', 'yin_rou'];
const _seeds = [0];
const _writeReport = 'UPDATE_PHASE0A_FULL_CONTENT_BALANCE';
const _csvPath =
    'test/tools/output/phase0a_full_content_balance_diagnostic.csv';
const _mdPath = 'test/tools/output/phase0a_full_content_balance_diagnostic.md';

final class _Run {
  const _Run(this.observation, this.uses, this.stage, this.damageMult);
  final Phase0aProfileRunObservation observation;
  final int uses;
  final String stage;
  final double damageMult;
}

void main() {
  late GameRepository repo;
  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test(
    'Phase 0A full production content proficiency diagnostic',
    () async {
      final stageEntries =
          repo.stageDefs.values
              .where((s) => s.stageType == StageType.mainline)
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
          .where((e) => e.status == Phase0aPreflightStatus.eligible)
          .toList();
      expect(stageEntries, hasLength(105));
      expect(towerEntries, hasLength(49));
      expect(eligible, hasLength(154));

      final proficiencyStages = repo.numbers.skillProficiency.stages;
      expect(proficiencyStages.map((s) => s.minUses).toList(), [
        0,
        30,
        100,
        300,
        800,
      ]);
      final arena = repo.numbers.phase0aArena;
      final rows = <_Run>[];
      final starterProfiles = <String, CombatantSnapshot>{};
      for (final school in _schools) {
        final directory = await Directory.systemTemp.createTemp(
          'phase0a_full_',
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
          starterProfiles[school] = seeded.snapshot;
          for (final proficiencyStage in proficiencyStages) {
            final uses = proficiencyStage.minUses;
            final profile = seeded.snapshot.copyWith(
              skillUses: {
                for (final skill in seeded.snapshot.availableSkills)
                  skill.id: uses,
              },
            );
            for (final entry in eligible) {
              final mapping = switch (entry.kind) {
                Phase0aPreflightContentKind.stage =>
                  Phase0aStageContentMapper.map(
                    stage: repo.stageDefs[entry.id]!,
                    playerSnapshot: profile,
                    numbers: repo.numbers,
                  ),
                Phase0aPreflightContentKind.tower =>
                  Phase0aStageContentMapper.mapTower(
                    floor: repo.towerFloors.firstWhere(
                      (floor) => 'tower_${floor.floorIndex}' == entry.id,
                    ),
                    playerSnapshot: profile,
                    numbers: repo.numbers,
                  ),
              };
              for (final seed in _seeds) {
                rows.add(
                  _Run(
                    runPhase0aProfile(
                      profileId: school,
                      contentId: entry.key,
                      mapping: mapping,
                      numbers: repo.numbers,
                      playerSnapshot: profile,
                      seed: seed,
                      deltaSeconds: arena.fixedDeltaSeconds,
                      maxTicks: arena.maxSimulationTicks,
                    ),
                    uses,
                    proficiencyStage.id,
                    SkillProficiency.damageMultFor(
                      uses,
                      repo.numbers.skillProficiency,
                    ),
                  ),
                );
              }
            }
          }
        } finally {
          await IsarSetup.close();
          await directory.delete(recursive: true);
        }
      }

      final expected =
          _schools.length * eligible.length * proficiencyStages.length;
      expect(rows, hasLength(expected));
      expect(
        rows
            .map(
              (r) =>
                  '${r.observation.profileId}/${r.observation.contentId}/${r.uses}/${r.observation.seed}',
            )
            .toSet(),
        hasLength(expected),
      );
      for (final run in rows) {
        final r = run.observation;
        expect(['victory', 'defeat', 'timeout'], contains(r.outcome));
        expect(r.numericCasts, hasLength(6));
        expect(r.numericHits, hasLength(6));
        expect(r.numericDamage, hasLength(6));
        expect(r.ticks, lessThanOrEqualTo(arena.maxSimulationTicks));
        expect(r.maxResolvedDamage, lessThan(1000000));
      }

      final csv = _csv(rows);
      final md = _markdown(
        rows,
        starterProfiles,
        manifest.length,
        expected,
        proficiencyStages,
      );
      if (Platform.environment[_writeReport] == '1') {
        File(_csvPath).writeAsStringSync(csv);
        File(_mdPath).writeAsStringSync(md);
      } else {
        final header = File(_csvPath).readAsLinesSync().first;
        expect(header, contains('proficiency_uses'));
        expect(header, contains('proficiency_stage'));
        expect(header, contains('proficiency_damage_mult'));
        expect(File(_mdPath).readAsStringSync(), contains('熟练度'));
      }
      print(
        'phase0a full content: content=${manifest.length}; proficiencyStages=${proficiencyStages.length}; '
        'runs=${rows.length}; wins=${rows.where((r) => r.observation.outcome == 'victory').length}; '
        'defeats=${rows.where((r) => r.observation.outcome == 'defeat').length}; '
        'timeouts=${rows.where((r) => r.observation.outcome == 'timeout').length}; '
        'maxDamage=${rows.map((r) => r.observation.maxResolvedDamage).reduce((a, b) => a > b ? a : b)}',
      );
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

String _csv(List<_Run> rows) {
  final out = StringBuffer()
    ..writeln(
      'content_kind,content_id,school,seed,outcome,ticks,seconds,proficiency_uses,proficiency_stage,proficiency_damage_mult,hp_start,hp_end,qi_start,qi_max,qi_end,basic_casts,basic_hits,basic_damage,numeric_casts,numeric_hits,numeric_damage,max_damage',
    );
  for (final run in rows) {
    final r = run.observation;
    final split = r.contentId.split('/');
    out.writeln(
      [
        split.first,
        split.last,
        r.profileId,
        r.seed,
        r.outcome,
        r.ticks,
        r.seconds.toStringAsFixed(3),
        run.uses,
        run.stage,
        run.damageMult.toStringAsFixed(2),
        r.hpStart,
        r.hpEnd,
        r.qiStart,
        r.qiMax,
        r.qiEnd,
        r.basicCasts,
        r.basicHits,
        r.basicDamage,
        r.numericCasts.join('|'),
        r.numericHits.join('|'),
        r.numericDamage.join('|'),
        r.maxResolvedDamage,
      ].join(','),
    );
  }
  return out.toString();
}

String _markdown(
  List<_Run> rows,
  Map<String, CombatantSnapshot> starterProfiles,
  int contentCount,
  int runCount,
  List<SkillProficiencyStageConfig> stages,
) {
  final out = StringBuffer()
    ..writeln('# Phase 0A 全内容熟练度战斗画像诊断')
    ..writeln()
    ..writeln(
      '基线内容：105 条主线关 + 49 层塔；3 个生产流派；固定 seeds=${_seeds.join(',')}；熟练度 uses=${stages.map((s) => s.minUses).join(',')}；共 $runCount 次 headless bot 运行。',
    )
    ..writeln()
    ..writeln(
      '自动画像不等于真人体验，不支持直接调值。starter profile 是生产创建页的起手熟练度/装备构筑，不是连续成长或换装档；其跨章节大量失败不能直接写成平衡结论。',
    )
    ..writeln()
    ..writeln(
      'profile：${starterProfiles.keys.join(', ')}；内容总数：$contentCount。熟练度阶段与倍率直接读取 production `numbers.skill_proficiency.stages`，每个 profile 的全部已知招式 usage 设置为该阈值。',
    )
    ..writeln()
    ..writeln(
      '| school | uses | stage | multiplier | runs | wins | defeats | win rate | mean ticks | mean HP end | mean Qi end | basic casts | numeric casts | max damage |',
    )
    ..writeln(
      '|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|',
    );
  for (final school in _schools) {
    for (final stage in stages) {
      final rs = rows
          .where(
            (r) => r.observation.profileId == school && r.uses == stage.minUses,
          )
          .map((r) => r.observation)
          .toList();
      final a = Phase0aProfileAggregate(rs);
      out.writeln(
        '| $school | ${stage.minUses} | ${stage.id} | ${stage.damageMult.toStringAsFixed(2)} | ${rs.length} | ${a.wins} | ${a.defeats} | ${a.winRate.toStringAsFixed(3)} | ${a.meanTicks.toStringAsFixed(1)} | ${(a.meanHpEndRatio * 100).toStringAsFixed(1)}% | ${(a.meanQiEndRatio * 100).toStringAsFixed(1)}% | ${a.totalBasicCasts} | ${a.totalNumericCasts().reduce((x, y) => x + y)} | ${a.maxResolvedDamage} |',
      );
    }
  }
  out
    ..writeln()
    ..writeln('## 同内容同流派：uses=0 → 最高档')
    ..writeln()
    ..writeln(
      '| school | content | low win | high win | low damage | high damage | low max hit | high max hit | low ticks | high ticks | low numeric casts | high numeric casts |',
    )
    ..writeln('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
  for (final school in _schools) {
    final contents =
        rows
            .where(
              (r) =>
                  r.observation.profileId == school &&
                  r.uses == stages.first.minUses,
            )
            .map((r) => r.observation.contentId)
            .toSet()
            .toList()
          ..sort();
    for (final content in contents) {
      final low = rows
          .where(
            (r) =>
                r.observation.profileId == school &&
                r.observation.contentId == content &&
                r.uses == stages.first.minUses,
          )
          .map((r) => r.observation)
          .toList();
      final high = rows
          .where(
            (r) =>
                r.observation.profileId == school &&
                r.observation.contentId == content &&
                r.uses == stages.last.minUses,
          )
          .map((r) => r.observation)
          .toList();
      final la = Phase0aProfileAggregate(low),
          ha = Phase0aProfileAggregate(high);
      out.writeln(
        '| $school | $content | ${la.winRate.toStringAsFixed(3)} | ${ha.winRate.toStringAsFixed(3)} | ${la.totalPlayerDamage} | ${ha.totalPlayerDamage} | ${la.maxResolvedDamage} | ${ha.maxResolvedDamage} | ${la.meanTicks.toStringAsFixed(1)} | ${ha.meanTicks.toStringAsFixed(1)} | ${la.totalNumericCasts().reduce((x, y) => x + y)} | ${ha.totalNumericCasts().reduce((x, y) => x + y)} |',
      );
    }
  }
  out
    ..writeln()
    ..writeln(
      '字段明细见同名 CSV：包含 proficiency uses/stage/multiplier、内容、流派、seed、胜负、ticks、HP/Qi 起止、普攻与数字技能 casts/hits/damage、maxDamage。',
    )
    ..writeln()
    ..writeln(
      '运行命令：`UPDATE_PHASE0A_FULL_CONTENT_BALANCE=1 flutter test test/tools/phase0a_full_content_balance_diagnostic_test.dart -r expanded`。',
    )
    ..writeln()
    ..writeln(
      '复跑命令：`flutter test test/tools/phase0a_full_content_balance_diagnostic_test.dart -r expanded`（不刷新报告，但会核对已提交证据 header）。',
    );
  return out.toString();
}
