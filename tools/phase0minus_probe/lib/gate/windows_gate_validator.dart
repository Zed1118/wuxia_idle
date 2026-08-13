import 'dart:convert';

const phase0aWindowsGateViewports = <String>{
  'desktop_1280x720',
  'desktop_1440x900',
};

final class WindowsGateRun {
  const WindowsGateRun({
    required this.manifest,
    required this.summary,
    required this.artifactsValid,
    required this.runLogPresent,
  });

  final Map<String, Object?> manifest;
  final Map<String, Object?> summary;
  final bool artifactsValid;
  final bool runLogPresent;
}

final class WindowsGateValidation {
  const WindowsGateValidation({
    required this.errors,
    required this.viewportRunCounts,
    required this.runIds,
  });

  final List<String> errors;
  final Map<String, int> viewportRunCounts;
  final List<String> runIds;

  bool get passed => errors.isEmpty;

  Map<String, Object?> toJson() => {
    'gate': passed ? 'PASS' : 'FAIL',
    'errors': errors,
    'viewport_run_counts': viewportRunCounts,
    'run_ids': runIds,
  };
}

WindowsGateValidation validatePhase0aWindowsGate({
  required Map<String, Object?> hostManifest,
  required List<WindowsGateRun> runs,
  required String expectedCommit,
  required String expectedScenarioChecksum,
  int repeatsPerViewport = 3,
}) {
  final errors = <String>[];
  final counts = <String, int>{
    for (final viewport in phase0aWindowsGateViewports) viewport: 0,
  };
  final runIds = <String>[];
  final seenRunIds = <String>{};

  _validateHost(hostManifest, errors);
  final expectedHostChecksum = _string(hostManifest, 'manifest_sha256');
  final expectedRunCount =
      phase0aWindowsGateViewports.length * repeatsPerViewport;
  if (runs.length != expectedRunCount) {
    errors.add('Expected $expectedRunCount runs, found ${runs.length}.');
  }

  String? expectedBinaryChecksum;
  String? expectedReplayScriptVersion;
  for (var index = 0; index < runs.length; index++) {
    final run = runs[index];
    final prefix = 'run[$index]';
    final manifest = run.manifest;
    final summary = run.summary;
    final runId = _string(manifest, 'run_id');
    runIds.add(runId);
    if (runId.isEmpty || !seenRunIds.add(runId)) {
      errors.add('$prefix has an empty or duplicate run_id.');
    }
    _expect(manifest, 'platform', 'windows', prefix, errors);
    _expect(manifest, 'flutter_build_mode', 'profile', prefix, errors);
    _expect(manifest, 'git_commit', expectedCommit, prefix, errors);
    _expect(manifest, 'git_dirty', false, prefix, errors);
    _expect(
      manifest,
      'scenario_checksum',
      expectedScenarioChecksum,
      prefix,
      errors,
    );
    _expect(manifest, 'gate_mode', 'phase0a_replay', prefix, errors);
    _expect(
      manifest,
      'host_manifest_sha256',
      expectedHostChecksum,
      prefix,
      errors,
    );
    _expect(manifest, 'duration_scale', 1, prefix, errors);
    _expect(manifest, 'gc_collector', 'GC_TELEMETRY_COLLECTED', prefix, errors);
    final gcEventCount = manifest['gc_event_count'];
    if (gcEventCount is! num || gcEventCount <= 0) {
      errors.add('$prefix.gc_event_count must be greater than zero.');
    }
    _requireText(manifest, 'execution_command', prefix, errors);
    _requireText(manifest, 'flutter_version', prefix, errors);
    _requireText(manifest, 'dart_version', prefix, errors);
    _requireText(manifest, 'renderer', prefix, errors);
    _rejectPlaceholder(manifest, 'renderer', prefix, errors);

    final binaryChecksum = _string(manifest, 'binary_sha256');
    if (binaryChecksum.isEmpty) {
      errors.add('$prefix.binary_sha256 is missing.');
    } else if (expectedBinaryChecksum == null) {
      expectedBinaryChecksum = binaryChecksum;
    } else if (binaryChecksum != expectedBinaryChecksum) {
      errors.add('$prefix used a different Profile binary.');
    }
    if (!run.artifactsValid) {
      errors.add('$prefix result checksums do not match files_sha256.');
    }
    if (!run.runLogPresent) {
      errors.add('$prefix run.log is missing.');
    }

    final viewport = _map(manifest, 'viewport');
    final viewportId = _string(viewport, 'id');
    if (!phase0aWindowsGateViewports.contains(viewportId)) {
      errors.add('$prefix has unsupported viewport $viewportId.');
    } else {
      counts[viewportId] = counts[viewportId]! + 1;
    }
    _expect(viewport, 'device_pixel_ratio', 1, '$prefix.viewport', errors);
    _expect(viewport, 'refresh_rate_hz', 60, '$prefix.viewport', errors);

    _expect(summary, 'run_id', runId, '$prefix.summary', errors);
    _expect(summary, 'tier', 'target_20_plus_1', '$prefix.summary', errors);
    _expect(
      summary,
      'scenario_checksum',
      expectedScenarioChecksum,
      '$prefix.summary',
      errors,
    );
    final frameMetrics = _map(summary, 'frame_metrics');
    _expect(frameMetrics, 'validity', 'VALID', '$prefix.frame_metrics', errors);
    _expect(frameMetrics, 'gate', 'PASS', '$prefix.frame_metrics', errors);
    final frameCount = frameMetrics['frames'];
    if (frameCount is! num || frameCount < 3000) {
      errors.add('$prefix.frame_metrics.frames must be at least 3000.');
    }
    final display = _map(summary, 'display_measurement');
    _expect(display, 'matches', true, '$prefix.display_measurement', errors);
    final viewportMeasurement = _map(summary, 'viewport_measurement');
    _expect(
      viewportMeasurement,
      'matches',
      true,
      '$prefix.viewport_measurement',
      errors,
    );

    final workload = _map(summary, 'workload');
    _expect(workload, 'mode', 'phase0a_replay', '$prefix.workload', errors);
    _expect(
      workload,
      'gate_eligible_duration',
      true,
      '$prefix.workload',
      errors,
    );
    _expect(
      workload,
      'overall_preliminary_status',
      'PERFORMANCE_FIXTURE_PASS_GAMEPLAY_GATES_PENDING',
      '$prefix.workload',
      errors,
    );
    final replayVersion = _string(workload, 'replay_script_version');
    if (replayVersion.isEmpty) {
      errors.add('$prefix.workload.replay_script_version is missing.');
    } else if (expectedReplayScriptVersion == null) {
      expectedReplayScriptVersion = replayVersion;
    } else if (replayVersion != expectedReplayScriptVersion) {
      errors.add('$prefix used a different deterministic replay script.');
    }
    final breakdown = _map(workload, 'gate_breakdown');
    for (final gate in const [
      'timing_gc_gate',
      'resident_pool_gate',
      'workload_coverage_gate',
      'rss_gate',
      'collision_workload_gate',
    ]) {
      _expect(breakdown, gate, 'PASS', '$prefix.gate_breakdown', errors);
    }
  }

  for (final entry in counts.entries) {
    if (entry.value != repeatsPerViewport) {
      errors.add(
        '${entry.key} requires $repeatsPerViewport valid runs, found ${entry.value}.',
      );
    }
  }
  return WindowsGateValidation(
    errors: List.unmodifiable(errors),
    viewportRunCounts: Map.unmodifiable(counts),
    runIds: List.unmodifiable(runIds),
  );
}

void _validateHost(Map<String, Object?> host, List<String> errors) {
  _expect(host, 'status', 'RECORDED', 'host', errors);
  _requireText(host, 'operator', 'host', errors);
  _rejectPlaceholder(host, 'operator', 'host', errors);
  _requireText(host, 'captured_at_utc', 'host', errors);
  _rejectPlaceholder(host, 'captured_at_utc', 'host', errors);
  _requireText(host, 'manifest_sha256', 'host', errors);
  final device = _map(host, 'device');
  for (final key in const [
    'os_caption',
    'os_version',
    'cpu_model',
    'gpu_name',
    'gpu_driver_version',
    'storage_type',
    'power_mode',
  ]) {
    _requireText(device, key, 'host.device', errors);
    _rejectPlaceholder(device, key, 'host.device', errors);
  }
  final ramGib = device['ram_gib'];
  if (ramGib is! num || ramGib < 7 || ramGib > 8.5) {
    errors.add('host.device.ram_gib must describe the 8GB target machine.');
  }
  _expect(device, 'gpu_is_integrated', true, 'host.device', errors);
  _expect(device, 'plugged_in', true, 'host.device', errors);

  final display = _map(host, 'display');
  _expect(display, 'refresh_rate_hz', 60, 'host.display', errors);
  _expect(display, 'scale_percent', 100, 'host.display', errors);
  _expect(display, 'local_interactive_session', true, 'host.display', errors);
  final requiredViewports = display['required_logical_viewports'];
  const expectedViewports = {'1280x720', '1440x900'};
  if (requiredViewports is! List ||
      requiredViewports.map((value) => value.toString()).toSet().length != 2 ||
      !requiredViewports
          .map((value) => value.toString())
          .toSet()
          .containsAll(expectedViewports)) {
    errors.add(
      'host.display.required_logical_viewports must contain both Gate viewports.',
    );
  }

  final session = _map(host, 'session');
  _expect(session, 'remote_desktop', false, 'host.session', errors);
  _expect(session, 'virtual_machine', false, 'host.session', errors);

  final runtime = _map(host, 'runtime');
  for (final key in const ['renderer', 'flutter_version', 'dart_version']) {
    _requireText(runtime, key, 'host.runtime', errors);
    _rejectPlaceholder(runtime, key, 'host.runtime', errors);
  }
  final attestation = _map(host, 'attestation');
  _expect(
    attestation,
    'valid_for_minimum_spec_gate',
    true,
    'host.attestation',
    errors,
  );
  _expect(
    attestation,
    'cpu_at_or_below_target',
    true,
    'host.attestation',
    errors,
  );
  _expect(
    attestation,
    'gpu_at_or_below_target',
    true,
    'host.attestation',
    errors,
  );
  _expect(attestation, 'ram_matches_target', true, 'host.attestation', errors);
  _expect(
    attestation,
    'power_mode_confirmed_best_performance',
    true,
    'host.attestation',
    errors,
  );
  _requireText(attestation, 'validation_notes', 'host.attestation', errors);
  _rejectPlaceholder(
    attestation,
    'validation_notes',
    'host.attestation',
    errors,
  );
}

Map<String, Object?> _map(Map<String, Object?> source, String key) {
  final value = source[key];
  return value is Map<String, Object?> ? value : const <String, Object?>{};
}

String _string(Map<String, Object?> source, String key) {
  final value = source[key];
  return value is String ? value.trim() : '';
}

void _expect(
  Map<String, Object?> source,
  String key,
  Object expected,
  String prefix,
  List<String> errors,
) {
  final actual = source[key];
  final matches =
      actual == expected ||
      (actual is num &&
          expected is num &&
          actual.toDouble() == expected.toDouble());
  if (!matches) {
    errors.add(
      '$prefix.$key expected ${jsonEncode(expected)}, found ${jsonEncode(actual)}.',
    );
  }
}

void _requireText(
  Map<String, Object?> source,
  String key,
  String prefix,
  List<String> errors,
) {
  if (_string(source, key).isEmpty) {
    errors.add('$prefix.$key is missing.');
  }
}

void _rejectPlaceholder(
  Map<String, Object?> source,
  String key,
  String prefix,
  List<String> errors,
) {
  final value = _string(source, key).toUpperCase();
  if (value.contains('FILL_') ||
      value.contains('COLLECT_MANUALLY') ||
      value == 'UNKNOWN') {
    errors.add('$prefix.$key still contains a placeholder.');
  }
}
