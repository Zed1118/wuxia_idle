// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';

import '../support/isar_test_support.dart';
import '../support/phase0a_full_build_profile.dart';
import '../support/phase0a_profile_harness.dart';
import '../support/phase0a_production_preflight_manifest.dart';

/// 满 build × 真实 Phase 0A reducer × 全生产内容 × 最大周目 极值探针（派单包 B 目标 2）。
///
/// 补 CLAUDE.md §5.4 / GDD 记录的缺口：既有守卫要么用 [DamageCalculator] 测满 build
/// 单点（`test/balance/full_build_damage_redline_test.dart`，未经 reducer），要么跑真实
/// reducer 但只用 Ch1 起手画像（`phase0a_full_content_balance_diagnostic_test.dart`）。
/// 本探针把**满 build 画像**（`phase0a_full_build_profile.dart`）喂进真实 reducer，横扫
/// 全部 154 条生产内容 × 周目 {1, 上限}，硬断言每次结算单点伤害 `< 1,000,000`。
///
/// 周目上限读 `numbers.cycle_evolution`（主线/爬塔分别），熟练度取最高档，均不硬编码。
/// 报告仅在 `PROBE_REPORT=1` 时落盘（默认不写文件，只跑断言）。
const _schools = [
  TechniqueSchool.gangMeng,
  TechniqueSchool.lingQiao,
  TechniqueSchool.yinRou,
];
const _seed = 0;
const _writeReport = 'PROBE_REPORT';
const _reportPath = 'docs/audit/phase0a_full_build_extreme_probe_2026-09-19.md';
const _damageRedLine = 1000000;

// 实测值取自 2026-09-19 运行 test/balance/full_build_damage_redline_test.dart 的打印
// 输出（非誊写派单近似值）：满 build 单点 calculator 探针，未经 Phase 0A reducer。
const _calcWeaknessNonCrit = 72378; // 满build普攻 × 克制1.25 × 弱点1.25 非暴击
const _calcWeaknessCrit = 108567; // 同上暴击
const _calcPierceFinal = 134121; // 满破甲 Σpierce0.60 finalDamage
const _calcBreakWindowFinal = 136261; // 破绽窗口 effDef0.175 finalDamage
const _calcTotalEqAtk = 17255; // calculator 探针装备攻击（无心法相生）

final class _Run {
  const _Run(this.observation, this.school, this.kind, this.cycleIndex);
  final Phase0aProfileRunObservation observation;
  final TechniqueSchool school;
  final Phase0aPreflightContentKind kind;
  final int cycleIndex;
}

void main() {
  late GameRepository repo;
  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test('Phase 0A 满 build 真实路径全内容极值探针', () async {
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

    final cycleCfg = repo.numbers.cycleEvolution;
    final arena = repo.numbers.phase0aArena;
    final proficiencyStages = repo.numbers.skillProficiency.stages;
    final topStage = proficiencyStages.last; // 最高熟练度档（huaJing/800/1.30）

    final rows = <_Run>[];
    final profiles = <TechniqueSchool, Phase0aFullBuildProfile>{};
    final stopwatch = Stopwatch()..start();

    for (final school in _schools) {
      final directory = await Directory.systemTemp.createTemp('phase0a_fb_');
      try {
        await IsarSetup.init(directory: directory, inspector: false);
        final profile = await seedPhase0aFullBuildProfile(
          isar: IsarSetup.instance,
          school: school,
        );
        profiles[school] = profile;
        // 最高熟练度档：全部已知招式 usage 拉到该档阈值。
        final maxProfile = profile.snapshot.copyWith(
          skillUses: {
            for (final skill in profile.snapshot.availableSkills)
              skill.id: topStage.minUses,
          },
        );

        for (final entry in eligible) {
          final isStage = entry.kind == Phase0aPreflightContentKind.stage;
          final maxCycle = isStage
              ? cycleCfg.maxCycleMainline
              : cycleCfg.maxCycleTower;
          for (final cycleIndex in [1, maxCycle]) {
            final mapping = isStage
                ? Phase0aStageContentMapper.map(
                    stage: repo.stageDefs[entry.id]!,
                    playerSnapshot: maxProfile,
                    numbers: repo.numbers,
                    cycleIndex: cycleIndex,
                  )
                : Phase0aStageContentMapper.mapTower(
                    floor: repo.towerFloors.firstWhere(
                      (floor) => 'tower_${floor.floorIndex}' == entry.id,
                    ),
                    playerSnapshot: maxProfile,
                    numbers: repo.numbers,
                    cycleIndex: cycleIndex,
                  );
            final observation = runPhase0aProfile(
              profileId: school.name,
              contentId: '${entry.key}#c$cycleIndex',
              mapping: mapping,
              numbers: repo.numbers,
              playerSnapshot: maxProfile,
              seed: _seed,
              deltaSeconds: arena.fixedDeltaSeconds,
              maxTicks: arena.maxSimulationTicks,
            );
            // 硬红线：每次结算单点伤害不进百万（§5.4 唯一硬线）。
            expect(
              observation.maxResolvedDamage,
              lessThan(_damageRedLine),
              reason:
                  '§5.4 软红线越界：${school.name} ${entry.key} 周目$cycleIndex '
                  '单点结算伤害 ${observation.maxResolvedDamage} ≥ $_damageRedLine',
            );
            expect([
              'victory',
              'defeat',
              'timeout',
            ], contains(observation.outcome));
            expect(
              observation.ticks,
              lessThanOrEqualTo(arena.maxSimulationTicks),
            );
            rows.add(_Run(observation, school, entry.kind, cycleIndex));
          }
        }
      } finally {
        await IsarSetup.close();
        await directory.delete(recursive: true);
      }
    }
    stopwatch.stop();

    // 矩阵规模：3 流派 × (105 主线 × 2 周目 + 49 塔 × 2 周目) = 924。
    final expected =
        _schools.length * (stageEntries.length * 2 + towerEntries.length * 2);
    expect(rows, hasLength(expected));

    // 非超时率 ≥ 既有标准（诊断 2310 轮 0 超时）：满 build 更强，理应 0 超时。
    final timeouts = rows
        .where((r) => r.observation.outcome == 'timeout')
        .length;
    expect(timeouts, 0, reason: '满 build 出现超时局（既有 Ch1 诊断标准为 0），不放宽，逐条登记异常');

    final globalMax = rows.reduce(
      (a, b) =>
          a.observation.maxResolvedDamage >= b.observation.maxResolvedDamage
          ? a
          : b,
    );
    final wallClock = stopwatch.elapsed;

    print(
      'phase0a 满 build 极值探针: rounds=${rows.length}; '
      'wins=${rows.where((r) => r.observation.outcome == "victory").length}; '
      'defeats=${rows.where((r) => r.observation.outcome == "defeat").length}; '
      'timeouts=$timeouts; globalMax=${globalMax.observation.maxResolvedDamage} '
      '@ ${globalMax.school.name}/${globalMax.observation.contentId}; '
      'wallClock=${wallClock.inSeconds}s',
    );

    final markdown = _markdown(
      rows: rows,
      profiles: profiles,
      eligibleCount: eligible.length,
      stageCount: stageEntries.length,
      towerCount: towerEntries.length,
      topStage: topStage,
      cycleCfg: cycleCfg,
      wallClock: wallClock,
      globalMax: globalMax,
    );
    if (Platform.environment[_writeReport] == '1') {
      File(_reportPath).writeAsStringSync(markdown);
      print('已写报告：$_reportPath');
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}

String _markdown({
  required List<_Run> rows,
  required Map<TechniqueSchool, Phase0aFullBuildProfile> profiles,
  required int eligibleCount,
  required int stageCount,
  required int towerCount,
  required SkillProficiencyStageConfig topStage,
  required CycleEvolutionConfig cycleCfg,
  required Duration wallClock,
  required _Run globalMax,
}) {
  final out = StringBuffer()
    ..writeln('# Phase 0A 满 build 真实路径极值探针（2026-09-19）')
    ..writeln()
    ..writeln(
      '补 §5.4 缺口：既有 calculator 探针不经 reducer，既有 reducer 诊断只用 Ch1 起手画像。'
      '本探针把满 build 画像喂进真实 Phase 0A reducer，横扫全部生产内容 × 周目 {1, 上限}，'
      '硬断言每次结算单点伤害 < 1,000,000。自动画像不等于真人体验，不支持直接调值。',
    )
    ..writeln()
    ..writeln('## 夹具构成（程序化选取，无硬编码 id 清单）')
    ..writeln()
    ..writeln(
      '境界武圣·登峰（绝对等级 49）；神物三槽满强化 +49 / 心剑通灵共鸣 / 开锋三槽满；'
      '主修传说神功极境；辅修配满生产上限 3；熟练度最高档 '
      '${topStage.id}（uses=${topStage.minUses}, ×${topStage.damageMult}）。',
    )
    ..writeln()
    ..writeln(
      '| school | weapon | armor | accessory | main | assists | eqAtk | hp | speed |',
    )
    ..writeln('|---|---|---|---|---|---|---:|---:|---:|');
  for (final school in _schools) {
    final p = profiles[school]!;
    final s = p.snapshot;
    out.writeln(
      '| ${school.name} | ${p.weaponDefId} | ${p.armorDefId} | '
      '${p.accessoryDefId} | ${p.mainTechniqueDefId} | '
      '${p.assistTechniqueDefIds.join("<br>")} | ${s.totalEquipmentAttack} | '
      '${s.maxHp} | ${s.speed} |',
    );
  }
  out
    ..writeln()
    ..writeln('## 矩阵规模与 wall clock')
    ..writeln()
    ..writeln(
      '内容 $eligibleCount 条（主线 $stageCount + 爬塔 $towerCount）；周目上限读 '
      '`numbers.cycle_evolution`：主线 ${cycleCfg.maxCycleMainline} / 爬塔 '
      '${cycleCfg.maxCycleTower}；流派 ${_schools.length}；固定 seed=$_seed。'
      '共 ${rows.length} 轮 headless bot 运行，wall clock ${wallClock.inSeconds}s。',
    )
    ..writeln()
    ..writeln('## 汇总（按 流派 × 内容类 × 周目）')
    ..writeln()
    ..writeln(
      '| school | kind | cycle | runs | wins | defeats | win rate | mean ticks | mean HP end | mean Qi end | max damage |',
    )
    ..writeln('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
  for (final school in _schools) {
    for (final kind in Phase0aPreflightContentKind.values) {
      final cycles = (kind == Phase0aPreflightContentKind.stage
          ? cycleCfg.maxCycleMainline
          : cycleCfg.maxCycleTower);
      for (final cycle in [1, cycles]) {
        final rs = rows
            .where(
              (r) =>
                  r.school == school && r.kind == kind && r.cycleIndex == cycle,
            )
            .map((r) => r.observation)
            .toList();
        if (rs.isEmpty) continue;
        final a = Phase0aProfileAggregate(rs);
        out.writeln(
          '| ${school.name} | ${kind.name} | $cycle | ${rs.length} | ${a.wins} | '
          '${a.defeats} | ${a.winRate.toStringAsFixed(3)} | '
          '${a.meanTicks.toStringAsFixed(1)} | '
          '${(a.meanHpEndRatio * 100).toStringAsFixed(1)}% | '
          '${(a.meanQiEndRatio * 100).toStringAsFixed(1)}% | '
          '${a.maxResolvedDamage} |',
        );
      }
    }
  }

  // 全局最大 + 每周目最大。
  out
    ..writeln()
    ..writeln('## 极值定位')
    ..writeln()
    ..writeln(
      '全局最大单点伤害 **${globalMax.observation.maxResolvedDamage}** @ '
      '${globalMax.school.name} / ${globalMax.observation.contentId} / '
      'ticks=${globalMax.observation.ticks}（红线 1,000,000，余量 '
      '${(100 * (1 - globalMax.observation.maxResolvedDamage / _damageRedLine)).toStringAsFixed(1)}%）。',
    )
    ..writeln()
    ..writeln('| cycle | max damage | rounds |')
    ..writeln('|---:|---:|---:|');
  final allCycles = rows.map((r) => r.cycleIndex).toSet().toList()..sort();
  for (final cycle in allCycles) {
    final rs = rows.where((r) => r.cycleIndex == cycle).toList();
    final max = rs
        .map((r) => r.observation.maxResolvedDamage)
        .reduce((a, b) => a > b ? a : b);
    out.writeln('| $cycle | $max | ${rs.length} |');
  }

  // Top 10 伤害轮次。
  final top10 = [...rows]
    ..sort(
      (a, b) => b.observation.maxResolvedDamage.compareTo(
        a.observation.maxResolvedDamage,
      ),
    );
  out
    ..writeln()
    ..writeln('## Top 10 单点伤害轮次')
    ..writeln()
    ..writeln('| # | school | content | max damage | outcome | ticks |')
    ..writeln('|---:|---|---|---:|---|---:|');
  for (var i = 0; i < 10 && i < top10.length; i++) {
    final r = top10[i];
    out.writeln(
      '| ${i + 1} | ${r.school.name} | ${r.observation.contentId} | '
      '${r.observation.maxResolvedDamage} | ${r.observation.outcome} | '
      '${r.observation.ticks} |',
    );
  }

  // 胜负分布。
  final wins = rows.where((r) => r.observation.outcome == 'victory').length;
  final defeats = rows.where((r) => r.observation.outcome == 'defeat').length;
  final timeouts = rows.where((r) => r.observation.outcome == 'timeout').length;
  final meanTicks =
      rows.map((r) => r.observation.ticks).reduce((a, b) => a + b) /
      rows.length;
  out
    ..writeln()
    ..writeln('## 胜负 / 节奏分布')
    ..writeln()
    ..writeln(
      '胜 $wins / 负 $defeats / 超时 $timeouts（共 ${rows.length}）；'
      '胜率 ${(wins / rows.length).toStringAsFixed(3)}；平均 ticks '
      '${meanTicks.toStringAsFixed(1)}。满 build 对全线内容应近乎全胜；'
      '任何败/超时逐条登记于异常段，不据此调值。',
    );

  // calculator 对比。
  out
    ..writeln()
    ..writeln('## 与既有 calculator 探针对比')
    ..writeln()
    ..writeln(
      '既有 `full_build_damage_redline_test`（单点 [DamageCalculator]，装备攻击 '
      '$_calcTotalEqAtk，未经 reducer）2026-09-19 实测：满 build 普攻 × 克制1.25 × '
      '弱点1.25 非暴击 $_calcWeaknessNonCrit / 暴击 $_calcWeaknessCrit；满破甲 '
      '(Σpierce0.60) $_calcPierceFinal；破绽窗口 (effDef0.175) $_calcBreakWindowFinal。',
    )
    ..writeln()
    ..writeln(
      '本探针满 build 含同流派心法相生（装备攻击 '
      '${profiles[_schools.first]!.snapshot.totalEquipmentAttack}，较 calculator 探针 '
      '$_calcTotalEqAtk 更高），且经真实 reducer 全内容 × 周目横扫，全局最大单点 '
      '${globalMax.observation.maxResolvedDamage}——与 calculator 单点同量级、'
      '均远不进百万，两路互为佐证。',
    );

  // 结论。
  final holds = globalMax.observation.maxResolvedDamage < _damageRedLine;
  out
    ..writeln()
    ..writeln('## 结论')
    ..writeln()
    ..writeln(
      holds
          ? '**软红线守住（max ${globalMax.observation.maxResolvedDamage} < 1e6）**：'
                '满 build 经真实 Phase 0A reducer 横扫全部 ${rows.length} 轮，'
                '无任何单点结算伤害触百万，§5.4 唯一硬线成立。'
          : '**触线**：存在单点伤害 ≥ 1e6 的轮次，详见 Top 10 与异常段，立即上报不得削弱断言。',
    );

  // 异常登记。
  final anomalies =
      rows.where((r) => r.observation.outcome != 'victory').toList()..sort(
        (a, b) => a.observation.contentId.compareTo(b.observation.contentId),
      );
  out
    ..writeln()
    ..writeln('## 异常登记（只记录，不建议调值）')
    ..writeln();
  if (anomalies.isEmpty) {
    out.writeln('全 ${rows.length} 轮满 build 全胜，无败/超时异常。');
  } else {
    out.writeln('非全胜轮次 ${anomalies.length} 条（败/超时），逐条列前 20：');
    out.writeln();
    out.writeln('| school | content | outcome | ticks | player max damage |');
    out.writeln('|---|---|---|---:|---:|');
    for (final r in anomalies.take(20)) {
      out.writeln(
        '| ${r.school.name} | ${r.observation.contentId} | '
        '${r.observation.outcome} | ${r.observation.ticks} | '
        '${r.observation.maxResolvedDamage} |',
      );
    }
  }
  out
    ..writeln()
    ..writeln(
      '复跑：`flutter test --no-pub test/tools/phase0a_full_build_extreme_probe_test.dart -r expanded`'
      '（默认不写报告）；生成报告：前置 `PROBE_REPORT=1`。',
    );
  return out.toString();
}
