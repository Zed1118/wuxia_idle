import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('主 CI 四片保留全量 coverage 并汇总后执行 ratchet', () async {
    final ci = await File('.github/workflows/ci.yml').readAsString();
    final workflow = loadYaml(ci) as YamlMap;
    final jobs = workflow['jobs'] as YamlMap;
    final testJob = jobs['test'] as YamlMap;
    final strategy = testJob['strategy'] as YamlMap;
    final steps = (testJob['steps'] as YamlList).cast<YamlMap>();
    final testStep = steps.singleWhere(
      (step) =>
          '${step['run']}'.startsWith('dart run tool/run_test_shard.dart '),
    );

    expect(strategy['matrix']['shard'], orderedEquals([0, 1, 2, 3]));
    expect(strategy['fail-fast'], isFalse);
    expect(testJob['timeout-minutes'], 25);
    expect(
      testStep['run'],
      r'dart run tool/run_test_shard.dart 4 ${{ matrix.shard }}',
    );
    expect(testStep['if'], isNull);
    expect(testStep['continue-on-error'], isNull);
    for (final command in [
      'dart format --output=none --set-exit-if-changed lib test docs',
      'flutter analyze --no-pub lib test tool',
    ]) {
      expect(
        steps.singleWhere((step) => step['run'] == command)['if'],
        'matrix.shard == 0',
      );
    }

    final upload = steps.singleWhere(
      (step) => step['uses'] == 'actions/upload-artifact@v4',
    );
    expect(
      upload['with']['name'],
      r'flutter-coverage-shard-${{ matrix.shard }}',
    );
    expect((upload['with']['path'] as String).trim().split('\n'), [
      'coverage/lcov.info',
      'coverage/test-shard-manifest.json',
      'coverage/test-results.json',
    ]);
    expect(upload['with']['if-no-files-found'], 'error');

    final coverage = jobs['coverage'] as YamlMap;
    expect(coverage['needs'], 'test');
    expect(coverage['if'], isNull);
    final coverageSteps = (coverage['steps'] as YamlList).cast<YamlMap>();
    final download = coverageSteps.singleWhere(
      (step) => step['uses'] == 'actions/download-artifact@v4',
    );
    expect(download['with']['pattern'], 'flutter-coverage-shard-*');
    expect(download['with']['path'], 'coverage/shards');
    expect(download['with']['merge-multiple'], isFalse);
    final mergeIndex = coverageSteps.indexWhere(
      (step) => step['name'] == 'Merge shard coverage reports',
    );
    final ratchetIndex = coverageSteps.indexWhere(
      (step) => step['run'] == 'dart run tool/coverage_ratchet.dart',
    );
    expect(mergeIndex, greaterThanOrEqualTo(0));
    expect(ratchetIndex, greaterThan(mergeIndex));
    expect(coverageSteps[ratchetIndex]['if'], isNull);
    expect(coverageSteps[ratchetIndex]['continue-on-error'], isNull);
    expect(ci, isNot(contains('--exclude-tags')));
    expect(jobs['macos-build']['timeout-minutes'], 30);
    expect(workflow['concurrency']['cancel-in-progress'], isTrue);
  });

  test('CI 依赖解析锁定 lockfile 且主分析覆盖根应用工具边界', () async {
    final ci = await File('.github/workflows/ci.yml').readAsString();
    final windows = await File(
      '.github/workflows/windows-release.yml',
    ).readAsString();

    expect(
      RegExp(r'flutter pub get --enforce-lockfile').allMatches(ci).length,
      3,
    );
    expect(windows, contains('flutter pub get --enforce-lockfile'));
    expect(ci, contains('run: flutter analyze --no-pub lib test tool'));
    expect(ci, isNot(contains('run: flutter analyze lib/ test/')));
    expect(ci, isNot(contains('run: flutter analyze --no-pub\n')));
  });

  test('覆盖率基线是带采样信息的正数', () async {
    final json =
        jsonDecode(await File('.github/coverage-ratchet.json').readAsString())
            as Map<String, dynamic>;

    expect(json['lineCoverageMinimum'], isA<num>());
    expect(json['lineCoverageMinimum'] as num, greaterThan(0));
    expect(json['sampledAt'], '2026-07-12');
    expect(json['note'], isA<String>());
  });

  test('Windows release workflow 仅手动/定时构建并上传未签名产物', () async {
    final workflow = await File(
      '.github/workflows/windows-release.yml',
    ).readAsString();

    expect(workflow, contains('workflow_dispatch:'));
    expect(workflow, contains('schedule:'));
    expect(workflow, isNot(contains('pull_request:')));
    // windows-latest(=Server 2025/VS2026)下 audioplayers_windows 6.x STL1011
    // 硬错,钉 windows-2022 止血;audioplayers 升级后此断言随 workflow 一起改回。
    expect(workflow, contains('runs-on: windows-2022'));
    expect(workflow, isNot(contains('runs-on: windows-latest')));
    expect(workflow, contains('flutter-version: 3.41.5'));
    expect(workflow, contains('dart run build_runner build'));
    expect(workflow, contains('flutter analyze --no-pub'));
    expect(workflow, contains('run: flutter analyze --no-pub lib test tool'));
    expect(
      RegExp(
        r'^\s*run: flutter analyze --no-pub lib test tool\s*$',
        multiLine: true,
      ).allMatches(workflow).length,
      1,
    );
    expect(workflow, isNot(contains('run: flutter analyze --no-pub\n')));
    expect(workflow, contains('flutter build windows --release --no-pub'));
    expect(workflow, contains('actions/upload-artifact@v4'));
    expect(workflow, contains('build/windows/x64/runner/Release/'));
    expect(workflow, contains('retention-days: 14'));
    expect(workflow.toLowerCase(), contains('unsigned'));
  });
}
