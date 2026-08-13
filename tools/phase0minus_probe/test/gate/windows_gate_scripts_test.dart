import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final probeRoot = Directory.current.path;

  test('Windows profile runner is pinned to the Phase 0A replay contract', () {
    final source = File(
      '$probeRoot/scripts/run_phase0a_windows_profile.ps1',
    ).readAsStringSync();

    expect(source, contains(r'$env:PROBE_MODE = "phase0a_replay"'));
    expect(source, contains(r'$env:PROBE_EXPECTED_REFRESH_RATE = "60"'));
    expect(source, contains(r'$env:PROBE_EXPECTED_DPR = "1"'));
    expect(source, contains('DurationScale=1.0'));
    expect(source, contains(r'git -C $RepositoryRoot status --porcelain'));
    expect(source, contains('Scenario checksum mismatch'));
    expect(source, contains('host_manifest_sha256'));
    expect(source, contains(r'$HostFacts ='));
    expect(source, isNot(contains(r'$Host =')));
    expect(source, isNot(contains('PROBE_TIER = "stress_30"')));
  });

  test('Windows matrix requires both viewports and three runs each', () {
    final source = File(
      '$probeRoot/scripts/run_phase0a_windows_matrix.ps1',
    ).readAsStringSync();

    expect(source, contains('-Viewport desktop_1280x720 -Repeat 3'));
    expect(source, contains('-Viewport desktop_1440x900 -Repeat 3'));
    expect(source, contains('validate_phase0a_windows_results.dart'));
    expect(source, contains('SHA256SUMS.txt'));
    expect(source, contains('Compress-Archive'));
  });

  test('host capture cannot auto-attest a machine', () {
    final source = File(
      '$probeRoot/scripts/collect_phase0a_windows_host_manifest.ps1',
    ).readAsStringSync();

    expect(source, contains('CAPTURED_NOT_ATTESTED'));
    expect(source, contains(r'valid_for_minimum_spec_gate = $false'));
    expect(source, contains(r'cpu_at_or_below_target = $false'));
    expect(source, contains(r'gpu_at_or_below_target = $false'));
    expect(source, contains(r'power_mode_confirmed_best_performance = $false'));
    expect(source, contains('renderer = "FILL_FROM_FLUTTER_GPU_TRACE"'));
  });

  test('macOS Phase 0A runner foregrounds every exact app bundle', () {
    final source = File(
      '$probeRoot/scripts/run_phase0a_macos_profile.sh',
    ).readAsStringSync();

    expect(source, contains(r'"${run_env[@]}" "$binary" &'));
    expect(source, contains(r'open -a "$app_bundle"'));
    expect(source, contains(r'wait "$probe_pid"'));
    expect(source, isNot(contains('open -a phase0minus_probe')));
  });
}
