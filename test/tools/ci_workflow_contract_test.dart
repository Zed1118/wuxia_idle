import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('主 CI 保留全量 coverage 并在其后执行 ratchet', () async {
    final ci = await File('.github/workflows/ci.yml').readAsString();

    final coverageIndex = ci.indexOf('flutter test --coverage --no-pub');
    final ratchetIndex = ci.indexOf('dart run tool/coverage_ratchet.dart');
    expect(coverageIndex, greaterThanOrEqualTo(0));
    expect(ratchetIndex, greaterThan(coverageIndex));
    expect(ci, isNot(contains('--exclude-tags')));
  });

  test('覆盖率基线是带采样信息的正数', () async {
    final json = jsonDecode(
      await File('.github/coverage-ratchet.json').readAsString(),
    ) as Map<String, dynamic>;

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
    expect(workflow, contains('runs-on: windows-latest'));
    expect(workflow, contains('flutter-version: 3.41.5'));
    expect(workflow, contains('dart run build_runner build'));
    expect(workflow, contains('flutter analyze --no-pub'));
    expect(workflow, contains('flutter build windows --release --no-pub'));
    expect(workflow, contains('actions/upload-artifact@v4'));
    expect(workflow, contains('build/windows/x64/runner/Release/'));
    expect(workflow, contains('retention-days: 14'));
    expect(workflow.toLowerCase(), contains('unsigned'));
  });
}
