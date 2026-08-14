import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/gate/windows_gate_validator.dart';

const _commit = '0123456789abcdef';
const _checksum = 'scenario-sha256';
const _hostChecksum = 'host-sha256';

void main() {
  test('accepts an exact two-viewport by three-run physical matrix', () {
    final result = validatePhase0aWindowsGate(
      hostManifest: _host(),
      runs: _matrix(),
      expectedCommit: _commit,
      expectedScenarioChecksum: _checksum,
    );

    expect(result.passed, isTrue, reason: result.errors.join('\n'));
    expect(result.viewportRunCounts, {
      'desktop_1280x720': 3,
      'desktop_1440x900': 3,
    });
  });

  test('rejects a benchmark result that could otherwise look green', () {
    final runs = _matrix();
    final first = runs.first;
    first.summary['workload'] = {
      ...first.summary['workload']! as Map<String, Object?>,
      'mode': 'benchmark',
    };

    final result = validatePhase0aWindowsGate(
      hostManifest: _host(),
      runs: runs,
      expectedCommit: _commit,
      expectedScenarioChecksum: _checksum,
    );

    expect(result.passed, isFalse);
    expect(result.errors.join('\n'), contains('phase0a_replay'));
  });

  test('rejects a discrete GPU masquerading as the minimum-spec integrated', () {
    final host = _host();
    (host['device']! as Map)['gpu_is_integrated'] = false;
    (host['device']! as Map)['gpu_name'] = 'NVIDIA GeForce GTX 1050';

    final result = validatePhase0aWindowsGate(
      hostManifest: host,
      runs: _matrix(),
      expectedCommit: _commit,
      expectedScenarioChecksum: _checksum,
    );

    expect(result.passed, isFalse);
    expect(result.errors.join('\n'), contains('gpu_is_integrated'));
  });

  test('rejects a matrix where one run used a different build commit', () {
    final runs = _matrix();
    runs[3].manifest['git_commit'] = 'different-commit-000000';

    final result = validatePhase0aWindowsGate(
      hostManifest: _host(),
      runs: runs,
      expectedCommit: _commit,
      expectedScenarioChecksum: _checksum,
    );

    expect(result.passed, isFalse);
    expect(result.errors.join('\n'), contains('git_commit'));
  });

  test('rejects remote, unattested, mixed binary, and incomplete evidence', () {
    final host = _host();
    host['session'] = {
      ...host['session']! as Map<String, Object?>,
      'remote_desktop': true,
    };
    host['attestation'] = {
      ...host['attestation']! as Map<String, Object?>,
      'valid_for_minimum_spec_gate': false,
    };
    final runs = _matrix()..removeLast();
    runs.first.manifest['binary_sha256'] = 'different-binary';
    final second = runs[1];
    runs[1] = WindowsGateRun(
      manifest: second.manifest,
      summary: second.summary,
      artifactsValid: false,
      runLogPresent: false,
    );

    final result = validatePhase0aWindowsGate(
      hostManifest: host,
      runs: runs,
      expectedCommit: _commit,
      expectedScenarioChecksum: _checksum,
    );

    final errors = result.errors.join('\n');
    expect(result.passed, isFalse);
    expect(errors, contains('remote_desktop'));
    expect(errors, contains('valid_for_minimum_spec_gate'));
    expect(errors, contains('Expected 6 runs'));
    expect(errors, contains('different Profile binary'));
    expect(errors, contains('checksums'));
    expect(errors, contains('run.log'));
  });
}

List<WindowsGateRun> _matrix() => [
  for (final viewport in phase0aWindowsGateViewports)
    for (var repeat = 1; repeat <= 3; repeat++)
      _run('$viewport-r$repeat', viewport),
];

WindowsGateRun _run(String runId, String viewport) {
  final manifest = <String, Object?>{
    'run_id': runId,
    'platform': 'windows',
    'flutter_build_mode': 'profile',
    'git_commit': _commit,
    'git_dirty': false,
    'scenario_checksum': _checksum,
    'gate_mode': 'phase0a_replay',
    'host_manifest_sha256': _hostChecksum,
    'duration_scale': 1.0,
    'gc_collector': 'GC_TELEMETRY_COLLECTED',
    'gc_event_count': 42,
    'execution_command': 'phase0minus_probe.exe',
    'flutter_version': '3.41.5',
    'dart_version': '3.11.3',
    'renderer': 'Direct3D 11 / Skia',
    'binary_sha256': 'binary-sha256',
    'viewport': {
      'id': viewport,
      'device_pixel_ratio': 1.0,
      'refresh_rate_hz': 60.0,
    },
  };
  final summary = <String, Object?>{
    'run_id': runId,
    'tier': 'target_20_plus_1',
    'scenario_checksum': _checksum,
    'frame_metrics': {'validity': 'VALID', 'gate': 'PASS', 'frames': 3600},
    'display_measurement': {'matches': true},
    'viewport_measurement': {'matches': true},
    'workload': {
      'mode': 'phase0a_replay',
      'replay_script_version': 'phase0a-compressed-12s-v1',
      'gate_eligible_duration': true,
      'overall_preliminary_status':
          'PERFORMANCE_FIXTURE_PASS_GAMEPLAY_GATES_PENDING',
      'gate_breakdown': {
        'timing_gc_gate': 'PASS',
        'resident_pool_gate': 'PASS',
        'workload_coverage_gate': 'PASS',
        'rss_gate': 'PASS',
        'collision_workload_gate': 'PASS',
      },
    },
  };
  return WindowsGateRun(
    manifest: manifest,
    summary: summary,
    artifactsValid: true,
    runLogPresent: true,
  );
}

Map<String, Object?> _host() => {
  'status': 'RECORDED',
  'operator': 'tester',
  'captured_at_utc': '2026-08-13T00:00:00Z',
  'manifest_sha256': _hostChecksum,
  'device': {
    'os_caption': 'Windows 11',
    'os_version': '10.0.26100',
    'cpu_model': 'Intel Core i5-8250U',
    'gpu_name': 'Intel UHD Graphics 620',
    'gpu_driver_version': '31.0.101.2125',
    'gpu_is_integrated': true,
    'ram_gib': 8.0,
    'storage_type': 'SSD',
    'power_mode': 'Best performance',
    'plugged_in': true,
  },
  'display': {
    'refresh_rate_hz': 60,
    'scale_percent': 100,
    'required_logical_viewports': ['1280x720', '1440x900'],
    'local_interactive_session': true,
  },
  'session': {'remote_desktop': false, 'virtual_machine': false},
  'runtime': {
    'renderer': 'Direct3D 11 / Skia',
    'flutter_version': '3.41.5',
    'dart_version': '3.11.3',
  },
  'attestation': {
    'valid_for_minimum_spec_gate': true,
    'cpu_at_or_below_target': true,
    'gpu_at_or_below_target': true,
    'ram_matches_target': true,
    'power_mode_confirmed_best_performance': true,
    'validation_notes': 'Physical minimum-spec machine.',
  },
};
