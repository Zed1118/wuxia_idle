// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

const _updateEvidenceVariable = 'UPDATE_PHASE0A_FRAGMENT_EVIDENCE';
const _csvPath = 'test/tools/output/phase0a_fragment_economy_diagnostic.csv';
const _mdPath = 'test/tools/output/phase0a_fragment_economy_diagnostic.md';

// These are diagnostic controls, not gameplay values. Production threshold and
// probability are always read from GameRepository below.
const _trialCount = 20000;
const _maxRepeatHorizon = 100;
const _randomSeed = 20260823;

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test(
    'Phase 0A fragment economy diagnostic',
    () async {
      final mainlineRows = _mainlineRows(repo);
      final towerRows = _towerRows(repo);
      expect(mainlineRows, isNotEmpty);
      expect(towerRows, isNotEmpty);

      final csv = _csv([...mainlineRows, ...towerRows]);
      final markdown = _markdown(
        repo: repo,
        mainlineRows: mainlineRows,
        towerRows: towerRows,
      );
      final update = Platform.environment[_updateEvidenceVariable] == '1';
      final csvFile = File(_csvPath);
      final mdFile = File(_mdPath);
      if (update) {
        csvFile.parent.createSync(recursive: true);
        csvFile.writeAsStringSync(csv);
        mdFile.writeAsStringSync(markdown);
      } else {
        expect(csvFile.existsSync(), isTrue);
        expect(mdFile.existsSync(), isTrue);
        expect(csvFile.readAsStringSync(), csv);
        expect(mdFile.readAsStringSync(), markdown);
      }

      final unlock = repo.numbers.skillUnlock;
      print(
        'fragment economy diagnostic: mainline=${mainlineRows.length}; '
        'tower=${towerRows.length}; threshold=${unlock.fragmentThreshold}; '
        'probability=${unlock.towerFragmentDropProb}; trials=$_trialCount; '
        'horizon=$_maxRepeatHorizon',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

List<_EvidenceRow> _mainlineRows(GameRepository repo) {
  final stages =
      repo.stageDefs.values
          .where((stage) => stage.dropSkillManualId != null)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  final seen = <String>{};
  return [
    for (final stage in stages)
      if (seen.add(stage.dropSkillManualId!))
        _guaranteedRow(
          repo,
          skillId: stage.dropSkillManualId!,
          location: stage.id,
        ),
  ];
}

List<_EvidenceRow> _towerRows(GameRepository repo) {
  final floors =
      repo.towerFloors
          .where((floor) => floor.dropSkillFragmentId != null)
          .toList()
        ..sort((a, b) => a.floorIndex.compareTo(b.floorIndex));
  final seen = <String>{};
  final unlock = repo.numbers.skillUnlock;
  return [
    for (final floor in floors)
      if (seen.add(floor.dropSkillFragmentId!))
        _simulateTowerSkill(
          repo,
          skillId: floor.dropSkillFragmentId!,
          location: 'tower_${floor.floorIndex}',
          threshold: unlock.fragmentThreshold,
          probability: unlock.towerFragmentDropProb,
          randomSeed: _randomSeed + floor.floorIndex,
        ),
  ];
}

_EvidenceRow _guaranteedRow(
  GameRepository repo, {
  required String skillId,
  required String location,
}) {
  final skill = repo.skillDefs[skillId];
  expect(
    skill,
    isNotNull,
    reason: 'mainline drop skill must be loaded: $skillId',
  );
  expect(skill!.source, SkillSource.mainlineDrop);
  return _EvidenceRow(
    source: 'mainline_first_clear',
    skillId: skillId,
    skillName: skill.name,
    location: location,
    threshold: null,
    probability: null,
    simulations: 1,
    completedRuns: 1,
    meanRepeats: 1,
    p50: 1,
    p90: 1,
    p95: 1,
    uncollectedRate: 0,
  );
}

_EvidenceRow _simulateTowerSkill(
  GameRepository repo, {
  required String skillId,
  required String location,
  required int threshold,
  required double probability,
  required int randomSeed,
}) {
  final skill = repo.skillDefs[skillId];
  expect(
    skill,
    isNotNull,
    reason: 'tower fragment skill must be loaded: $skillId',
  );
  expect(skill!.source, SkillSource.fragment);
  expect(threshold, greaterThan(0));
  expect(probability, inInclusiveRange(0, 1));

  final rng = Random(randomSeed);
  final repeats = <int>[];
  for (var trial = 0; trial < _trialCount; trial++) {
    var collected = 0;
    var repeat = 0;
    while (collected < threshold && repeat < _maxRepeatHorizon) {
      repeat++;
      if (rng.nextDouble() < probability) collected++;
    }
    if (collected == threshold) repeats.add(repeat);
  }
  repeats.sort();
  return _EvidenceRow(
    source: 'tower_probability_fragment',
    skillId: skillId,
    skillName: skill.name,
    location: location,
    threshold: threshold,
    probability: probability,
    simulations: _trialCount,
    completedRuns: repeats.length,
    meanRepeats: repeats.reduce((a, b) => a + b) / repeats.length,
    p50: _percentile(repeats, 0.50),
    p90: _percentile(repeats, 0.90),
    p95: _percentile(repeats, 0.95),
    uncollectedRate: 1 - repeats.length / _trialCount,
  );
}

int _percentile(List<int> sorted, double quantile) {
  final rank = max(1, (sorted.length * quantile).ceil());
  return sorted[rank - 1];
}

String _csv(List<_EvidenceRow> rows) {
  final b = StringBuffer(
    'source,skill_id,skill_name,location,fragment_threshold,'
    'drop_probability,simulations,max_repeat_horizon,completed_runs,'
    'mean_repeats,p50_repeats,p90_repeats,p95_repeats,uncollected_rate\n',
  );
  for (final row in rows) {
    b.writeln(
      [
        row.source,
        row.skillId,
        row.skillName,
        row.location,
        row.threshold?.toString() ?? 'NA',
        row.probability?.toStringAsFixed(6) ?? 'NA',
        row.simulations,
        row.source == 'tower_probability_fragment' ? _maxRepeatHorizon : 'NA',
        row.completedRuns,
        row.meanRepeats.toStringAsFixed(4),
        row.p50,
        row.p90,
        row.p95,
        row.uncollectedRate.toStringAsFixed(6),
      ].map(_csvCell).join(','),
    );
  }
  return b.toString();
}

String _csvCell(Object value) {
  final text = value.toString();
  return text.contains(',') || text.contains('"')
      ? '"${text.replaceAll('"', '""')}"'
      : text;
}

String _markdown({
  required GameRepository repo,
  required List<_EvidenceRow> mainlineRows,
  required List<_EvidenceRow> towerRows,
}) {
  final unlock = repo.numbers.skillUnlock;
  final b = StringBuffer('# Phase 0A 残页经济只读诊断\n\n');
  b.writeln('基线：`44461288`。本证据只读取生产仓储加载后的配置，不修改 `lib/`、`data/`、玩法数值或现有测试。');
  b.writeln(
    '塔残页配置：fragmentThreshold=${unlock.fragmentThreshold}，'
    'towerFragmentDropProb=${unlock.towerFragmentDropProb.toStringAsFixed(6)}。',
  );
  b.writeln(
    'Monte Carlo：固定 seed 基础值 `$_randomSeed`（按塔层偏移）、'
    '每项 `$_trialCount` 次试验、单次最多 `$_maxRepeatHorizon` 次重复刷；'
    '未在上限内集齐计入未集齐率。P50/P90/P95 使用已集齐样本的 nearest-rank。\n',
  );
  _writeTable(b, '主线首通真解（必得，非概率残页）', mainlineRows);
  _writeTable(b, '塔 Boss 概率残页', towerRows);
  b.writeln('## 解释边界\n');
  b.writeln('- 主线首通真解单独列为一次首通必得，不与塔残页的重复刷分布混算。');
  b.writeln('- 塔统计描述按当前配置重复挑战对应 Boss 层的残页经济；不代表普通层奖励、首通经验或其他掉落。');
  b.writeln('- 本诊断不据此自动调节阈值、概率或任何战斗/经济数值。');
  return b.toString();
}

void _writeTable(StringBuffer b, String title, List<_EvidenceRow> rows) {
  b.writeln('## $title\n');
  b.writeln(
    '| skill | location | threshold | probability | runs | completed | mean | P50 | P90 | P95 | uncollected |',
  );
  b.writeln('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
  for (final row in rows) {
    b.writeln(
      '|${row.skillName} (`${row.skillId}`)|${row.location}|'
      '${row.threshold ?? '—'}|${row.probability?.toStringAsFixed(6) ?? '必得'}|'
      '${row.simulations}|${row.completedRuns}|${row.meanRepeats.toStringAsFixed(4)}|'
      '${row.p50}|${row.p90}|${row.p95}|${(row.uncollectedRate * 100).toStringAsFixed(4)}%|',
    );
  }
  b.writeln();
}

class _EvidenceRow {
  final String source;
  final String skillId;
  final String skillName;
  final String location;
  final int? threshold;
  final double? probability;
  final int simulations;
  final int completedRuns;
  final double meanRepeats;
  final int p50;
  final int p90;
  final int p95;
  final double uncollectedRate;

  const _EvidenceRow({
    required this.source,
    required this.skillId,
    required this.skillName,
    required this.location,
    required this.threshold,
    required this.probability,
    required this.simulations,
    required this.completedRuns,
    required this.meanRepeats,
    required this.p50,
    required this.p90,
    required this.p95,
    required this.uncollectedRate,
  });
}
