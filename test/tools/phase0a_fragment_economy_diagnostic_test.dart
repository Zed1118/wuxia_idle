// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

const _updateEvidence = 'UPDATE_PHASE0A_FRAGMENT_ECONOMY_EVIDENCE';
const _trials = 100000;
const _seed = 20260823;
const _notCompleteHorizonRuns = 100;
const _csvPath = 'test/tools/output/phase0a_fragment_economy_diagnostic.csv';
const _mdPath = 'test/tools/output/phase0a_fragment_economy_diagnostic.md';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test('Phase 0A fragment economy diagnostic', () async {
    final threshold = repo.numbers.skillUnlock.fragmentThreshold;
    final probability = repo.numbers.skillUnlock.towerFragmentDropProb;
    expect(threshold, greaterThan(0));
    expect(probability, greaterThan(0));
    expect(probability, lessThanOrEqualTo(1));

    final towerFragments = <String>{
      for (final floor in repo.towerFloors)
        if (floor.isBoss && floor.dropSkillFragmentId != null)
          floor.dropSkillFragmentId!,
    }.toList()..sort();
    expect(towerFragments, isNotEmpty);

    final mainlineManuals = <String>{
      for (final stage in repo.stageDefs.values)
        if (stage.stageType.name == 'mainline' &&
            stage.dropSkillManualId != null)
          stage.dropSkillManualId!,
    }.toList()..sort();

    final stats = <String, _MonteCarloStats>{};
    for (final skillId in towerFragments) {
      stats[skillId] = _simulate(
        threshold: threshold,
        probability: probability,
        trials: _trials,
        seed: _seed ^ _stableHash(skillId),
        notCompleteHorizonRuns: _notCompleteHorizonRuns,
      );
    }

    final setStats = _simulateSet(
      skillIds: towerFragments,
      threshold: threshold,
      probability: probability,
      trials: _trials,
      seed: _seed,
      notCompleteHorizonRuns: _notCompleteHorizonRuns,
    );

    final csv = StringBuffer()
      ..writeln(
        'kind,id,name,source,threshold,drop_probability,mean_runs,p50_runs,p90_runs,p95_runs,not_complete_rate',
      );
    for (final skillId in mainlineManuals) {
      final skill = repo.skillDefs[skillId];
      csv.writeln(
        _csv([
          'mainline_first_clear',
          skillId,
          skill?.name ?? skillId,
          'mainline Boss first clear',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
        ]),
      );
    }
    for (final skillId in towerFragments) {
      final skill = repo.skillDefs[skillId];
      final s = stats[skillId]!;
      csv.writeln(
        _csv([
          'tower_fragment',
          skillId,
          skill?.name ?? skillId,
          'tower Boss repeat clear',
          threshold,
          probability,
          s.mean,
          s.p50,
          s.p90,
          s.p95,
          s.notCompleteRate,
        ]),
      );
    }
    csv.writeln(
      _csv([
        'tower_fragment_set',
        'ALL_TOWER_FRAGMENT_SKILLS',
        '全部塔残页技能集齐',
        'tower Boss repeat clear; one run per mapped Boss',
        threshold,
        probability,
        setStats.mean,
        setStats.p50,
        setStats.p90,
        setStats.p95,
        setStats.notCompleteRate,
      ]),
    );

    final md = StringBuffer()
      ..writeln('# Phase 0A 残页经济只读诊断')
      ..writeln()
      ..writeln(
        '基线：`44461288`；固定 Monte Carlo seed：`$_seed`；试验次数：`$_trials`；未集齐率观察窗口：`$_notCompleteHorizonRuns` 次重复刷。',
      )
      ..writeln()
      ..writeln(
        '生产读取值：`fragment_threshold=$threshold`，`tower_fragment_drop_prob=$probability`。',
      )
      ..writeln(
        '来源：`GameRepository.loadAllDefs()` → `data/numbers.yaml`、`data/towers.yaml`、`data/stages.yaml`。',
      )
      ..writeln()
      ..writeln('## 主线首通真解')
      ..writeln()
      ..writeln('主线 Boss 首通真解是必得，不进入概率 Monte Carlo；重复刷均值、分位数和未集齐率不适用。')
      ..writeln()
      ..writeln('| 技能 ID | 名称 | 来源 |')
      ..writeln('|---|---|---|');
    for (final skillId in mainlineManuals) {
      final skill = repo.skillDefs[skillId];
      md.writeln('| `$skillId` | ${skill?.name ?? skillId} | 主线 Boss 首通真解 |');
    }
    md
      ..writeln()
      ..writeln('## 爬塔残页')
      ..writeln()
      ..writeln('每个技能按其映射塔 Boss 的重复胜利次数统计；每次胜利以生产概率独立投掷，集齐阈值从生产配置读取。')
      ..writeln()
      ..writeln('| 技能 ID | 名称 | 均值 | P50 | P90 | P95 | 未集齐率 |')
      ..writeln('|---|---|---:|---:|---:|---:|---:|');
    for (final skillId in towerFragments) {
      final skill = repo.skillDefs[skillId];
      final s = stats[skillId]!;
      md.writeln(
        '| `$skillId` | ${skill?.name ?? skillId} | ${s.mean} | ${s.p50} | ${s.p90} | ${s.p95} | ${s.notCompleteRate} |',
      );
    }
    md
      ..writeln()
      ..writeln('### 全部塔残页技能集齐')
      ..writeln()
      ..writeln('| 均值 | P50 | P90 | P95 | 未集齐率 |')
      ..writeln('|---:|---:|---:|---:|---:|')
      ..writeln(
        '| ${setStats.mean} | ${setStats.p50} | ${setStats.p90} | ${setStats.p95} | ${setStats.notCompleteRate} |',
      )
      ..writeln()
      ..writeln(
        '“全部集齐”按每个塔残页技能分别刷其映射 Boss，并取所有技能完成所需刷数的最大值；不是把不同 Boss 的掉落池错误合并为一个池。',
      );

    if (Platform.environment[_updateEvidence] == '1') {
      await File(_csvPath).writeAsString(csv.toString());
      await File(_mdPath).writeAsString(md.toString());
    }
    expect(csv.toString(), contains('tower_fragment_set'));
    expect(md.toString(), contains('主线首通真解'));
    print(csv);
  });
}

_MonteCarloStats _simulate({
  required int threshold,
  required double probability,
  required int trials,
  required int seed,
  required int notCompleteHorizonRuns,
}) {
  final random = math.Random(seed);
  final runs = <int>[];
  for (var trial = 0; trial < trials; trial++) {
    var fragments = 0;
    var attempts = 0;
    while (fragments < threshold) {
      attempts++;
      if (random.nextDouble() < probability) fragments++;
    }
    runs.add(attempts);
  }
  return _stats(runs, notCompleteHorizonRuns);
}

_MonteCarloStats _simulateSet({
  required List<String> skillIds,
  required int threshold,
  required double probability,
  required int trials,
  required int seed,
  required int notCompleteHorizonRuns,
}) {
  final random = math.Random(seed);
  final runs = <int>[];
  for (var trial = 0; trial < trials; trial++) {
    var maxAttempts = 0;
    for (final _ in skillIds) {
      var fragments = 0;
      var attempts = 0;
      while (fragments < threshold) {
        attempts++;
        if (random.nextDouble() < probability) fragments++;
      }
      if (attempts > maxAttempts) maxAttempts = attempts;
    }
    runs.add(maxAttempts);
  }
  return _stats(runs, notCompleteHorizonRuns);
}

_MonteCarloStats _stats(List<int> values, int notCompleteHorizonRuns) {
  final sorted = List<int>.of(values)..sort();
  double percentile(double p) =>
      sorted[(p * (sorted.length - 1)).round()].toDouble();
  return _MonteCarloStats(
    mean: values.reduce((a, b) => a + b) / values.length,
    p50: percentile(0.50),
    p90: percentile(0.90),
    p95: percentile(0.95),
    notCompleteRate:
        values.where((value) => value > notCompleteHorizonRuns).length /
        values.length,
  );
}

String _csv(List<Object?> values) => values
    .map((value) {
      final text = value?.toString() ?? '';
      return text.contains(',') ? '"${text.replaceAll('"', '""')}"' : text;
    })
    .join(',');

int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

class _MonteCarloStats {
  const _MonteCarloStats({
    required this.mean,
    required this.p50,
    required this.p90,
    required this.p95,
    required this.notCompleteRate,
  });

  final double mean;
  final double p50;
  final double p90;
  final double p95;
  final double notCompleteRate;
}
