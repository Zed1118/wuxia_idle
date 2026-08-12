import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/metrics/frame_collector.dart';
import 'package:phase0minus_probe/metrics/run_metrics.dart';

final class ResultWriter {
  const ResultWriter();

  Future<Directory> write({
    required String runId,
    required ProbeConfig config,
    required ProbeTier tier,
    required ProbeViewport viewport,
    required List<FrameSample> frames,
    required RunMetrics metrics,
    required Map<String, Object?> poolSnapshot,
    required Map<String, Object?> workloadSnapshot,
    required String outputRoot,
    required String repositoryRoot,
  }) async {
    final directory = Directory('$outputRoot/$runId');
    await directory.create(recursive: true);
    final framesFile = File('${directory.path}/frames.jsonl');
    final framesBuffer = StringBuffer();
    for (final frame in frames) {
      framesBuffer.writeln(jsonEncode(frame.toJson()));
    }
    await framesFile.writeAsString(framesBuffer.toString(), flush: true);

    final memoryFile = File('${directory.path}/memory_gc.jsonl');
    final memoryBuffer = StringBuffer();
    for (final sample in metrics.memory) {
      memoryBuffer.writeln(jsonEncode(sample.toJson()));
    }
    memoryBuffer.writeln(jsonEncode({'status': 'GC_TELEMETRY_MISSING'}));
    await memoryFile.writeAsString(memoryBuffer.toString(), flush: true);

    final view = PlatformDispatcher.instance.views.firstOrNull;
    final dpr = view?.devicePixelRatio ?? 1;
    final actualLogicalWidth = (view?.physicalSize.width ?? 0) / dpr;
    final actualLogicalHeight = (view?.physicalSize.height ?? 0) / dpr;
    final viewportMatches =
        (actualLogicalWidth - viewport.width).abs() < 0.5 &&
        (actualLogicalHeight - viewport.height).abs() < 0.5;
    final frameMetrics = metrics.summarize(frames);
    if (!viewportMatches) {
      frameMetrics['validity'] = 'INVALID_VIEWPORT';
      frameMetrics['timing_gate'] = 'INVALID';
      frameMetrics['viewport_reason'] =
          'Expected ${viewport.width}x${viewport.height}, '
          'measured ${actualLogicalWidth}x$actualLogicalHeight.';
    }
    final summary = <String, Object?>{
      'run_id': runId,
      'tier': tier.id,
      'viewport': viewport.id,
      'scenario_checksum': config.checksum,
      'collision_backend': config.collisionBackend,
      'frame_metrics': frameMetrics,
      'viewport_measurement': {
        'expected_logical_width': viewport.width,
        'expected_logical_height': viewport.height,
        'actual_logical_width': actualLogicalWidth,
        'actual_logical_height': actualLogicalHeight,
        'matches': viewportMatches,
      },
      'pools': poolSnapshot,
      'workload': workloadSnapshot,
    };
    final summaryFile = File('${directory.path}/summary.json');
    await summaryFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(summary),
      flush: true,
    );

    final checksums = <String, String>{};
    for (final file in [framesFile, memoryFile, summaryFile]) {
      checksums[file.uri.pathSegments.last] = await _checksum(file);
    }
    final git = await _gitMetadata(repositoryRoot);
    final manifest = <String, Object?>{
      'run_id': runId,
      'scenario_path': scenarioAssetPath,
      'scenario_checksum': config.checksum,
      'script_version': config.scriptVersion,
      'seed': config.fixedSeed,
      'flutter_build_mode': kReleaseMode
          ? 'release'
          : kProfileMode
          ? 'profile'
          : 'debug',
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'processor_count': Platform.numberOfProcessors,
      'flame_version': '1.38.0',
      'collision_backend': config.collisionBackend,
      'viewport': {
        'id': viewport.id,
        'logical_width': viewport.width,
        'logical_height': viewport.height,
        'device_pixel_ratio': view?.devicePixelRatio,
        'physical_width': view?.physicalSize.width,
        'physical_height': view?.physicalSize.height,
      },
      'renderer': 'COLLECT_MANUALLY',
      'refresh_rate_hz': 'COLLECT_MANUALLY',
      'device_pixel_ratio': 'COLLECT_MANUALLY',
      'gc_collector': 'GC_TELEMETRY_MISSING',
      ...git,
      'files_sha256': checksums,
    };
    await File('${directory.path}/manifest.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );
    return directory;
  }

  Future<String> _checksum(File file) async =>
      sha256.convert(await file.readAsBytes()).toString();

  Future<Map<String, Object?>> _gitMetadata(String repositoryRoot) async {
    try {
      final commit = await Process.run('git', [
        '-C',
        repositoryRoot,
        'rev-parse',
        'HEAD',
      ]);
      final branch = await Process.run('git', [
        '-C',
        repositoryRoot,
        'branch',
        '--show-current',
      ]);
      final dirty = await Process.run('git', [
        '-C',
        repositoryRoot,
        'status',
        '--porcelain',
      ]);
      return {
        'git_commit': (commit.stdout as String).trim(),
        'git_branch': (branch.stdout as String).trim(),
        'git_dirty': (dirty.stdout as String).trim().isNotEmpty,
      };
    } on ProcessException {
      return {
        'git_commit': 'UNKNOWN',
        'git_branch': 'UNKNOWN',
        'git_dirty': true,
      };
    }
  }
}
