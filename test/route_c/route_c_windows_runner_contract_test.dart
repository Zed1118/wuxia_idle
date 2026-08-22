import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Windows runner measures the root production app and rejects old probe',
    () {
      final runner = File(
        'tools/route_c_gate/run_route_c_windows_profile.ps1',
      ).readAsStringSync();
      expect(runner, contains('wuxia_idle.exe'));
      expect(runner, contains('phase0a_battle_profile'));
      expect(runner, contains('data/phase0a_debug_battle.yaml'));
      expect(runner, contains('sample-seconds=60'));
      expect(runner, contains('warmup-seconds=12'));
      expect(runner, contains('cooldown-seconds=30'));
      expect(runner, isNot(contains('phase0minus_probe.exe')));
      expect(runner, isNot(contains('probe_scenarios.yaml')));
      expect(runner, contains('GC_TELEMETRY_COLLECTED'));
      expect(runner, contains('sampled_frames -ge 3000'));
      expect(runner, contains('p99_total_span_ms -lt 16.6'));
    },
  );

  test(
    'matrix is exactly two viewports times three runs and remains fail closed',
    () {
      final matrix = File(
        'tools/route_c_gate/run_route_c_windows_matrix.ps1',
      ).readAsStringSync();
      expect(RegExp(r'-Repeat 3').allMatches(matrix), hasLength(2));
      expect(matrix, contains('-Viewport "1280x720"'));
      expect(matrix, contains('-Viewport "1440x900"'));
      expect(matrix, contains('route_c_gate_preflight.dart'));
      expect(matrix, contains('wuxia_idle.exe'));
      expect(matrix, contains('phase0a_debug_battle.yaml'));
      expect(matrix, contains('Copy-Item -Force'));
      expect(matrix, contains('SHA256SUMS.txt'));
    },
  );

  test('preflight hashing supports the Windows matrix host', () {
    final source = File('tool/route_c_gate_preflight.dart').readAsStringSync();

    expect(source, contains('Platform.isWindows'));
    expect(source, contains("Process.run('certutil'"));
    expect(source, contains("'-hashfile'"));
    expect(source, contains("Process.run('shasum'"));
  });

  test(
    'macOS runner measures the same root production app and raw contract',
    () {
      final runner = File(
        'tools/route_c_gate/run_route_c_macos_profile.sh',
      ).readAsStringSync();

      expect(runner, contains('wuxia_idle.app/Contents/MacOS/wuxia_idle'));
      expect(runner, contains('phase0a_battle_profile'));
      expect(runner, contains('data/phase0a_debug_battle.yaml'));
      expect(runner, contains('sample-seconds=60'));
      expect(runner, contains('warmup-seconds=12'));
      expect(runner, contains('cooldown-seconds=30'));
      expect(runner, contains('GC_TELEMETRY_COLLECTED'));
      expect(runner, contains('.sampled_frames >= 3000'));
      expect(runner, contains('.p99_total_span_ms < 16.6'));
      expect(runner, contains('Library/Containers/com.pen.wuxia.wuxiaIdle'));
      expect(runner, contains('cp -R "\$app_run_dir/." "\$run_dir/"'));
      expect(runner, isNot(contains('phase0minus_probe.app')));
    },
  );

  test('macOS matrix is exactly two viewports times three production runs', () {
    final matrix = File(
      'tools/route_c_gate/run_route_c_macos_matrix.sh',
    ).readAsStringSync();

    expect(matrix, contains('1280x720 3'));
    expect(matrix, contains('1440x900 3'));
    expect(matrix, contains('ROUTE_C_SKIP_BUILD=true'));
    expect(matrix, contains('wuxia_idle.app/Contents/MacOS/wuxia_idle'));
    expect(matrix, contains('phase0a_debug_battle.yaml'));
    expect(matrix, contains('SHA256SUMS.txt'));
  });
}
