import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:wuxia_idle/features/debug/application/battle_frame_profile.dart';

void main() {
  test('运行时参数只在完整生产采样契约下启用', () {
    expect(BattleFrameProfileRunConfig.tryParse(const <String>[]), isNull);

    final config = BattleFrameProfileRunConfig.tryParse(const <String>[
      '--battle-profile-run-id=run-01',
      '--battle-profile-output=C:\\evidence\\run-01',
      '--battle-profile-sample-seconds=60',
      '--battle-profile-warmup-seconds=12',
      '--battle-profile-cooldown-seconds=30',
      '--battle-profile-viewport=1280x720',
      '--battle-profile-auto-close=true',
    ]);

    expect(config, isNotNull);
    expect(config!.runId, 'run-01');
    expect(config.sample, const Duration(seconds: 60));
    expect(config.total, const Duration(seconds: 102));
    expect(config.warmup, const Duration(seconds: 12));
    expect(config.autoClose, isTrue);
    expect(config.viewportWidth, 1280);
    expect(config.viewportHeight, 720);
    expect(config.nativeContentViewport, isFalse);
    expect(config.diagnostics, isFalse);
  });

  test('diagnostics require explicit true and reset between runs', () {
    const args = <String>[
      '--battle-profile-run-id=diagnostic',
      '--battle-profile-output=out',
      '--battle-profile-sample-seconds=60',
      '--battle-profile-viewport=1280x720',
    ];
    addTearDown(() => BattleFrameProfileProbe.configureFromArgs([]));
    for (final value in ['false', 'TRUE', '1']) {
      BattleFrameProfileProbe.configureFromArgs([
        ...args,
        '--battle-profile-diagnostics=$value',
      ]);
      expect(BattleFrameProfileProbe.diagnosticsEnabled, isFalse);
    }
    BattleFrameProfileProbe.configureFromArgs([
      ...args,
      '--battle-profile-diagnostics=true',
    ]);
    expect(BattleFrameProfileProbe.diagnosticsEnabled, isTrue);
    BattleFrameProfileProbe.configureFromArgs(args);
    expect(BattleFrameProfileProbe.diagnosticsEnabled, isFalse);
  });

  test('character legality is an explicit nullable declaration', () {
    const args = <String>[
      '--battle-profile-scope=production',
      '--battle-profile-content-id=stage_01_01',
      '--battle-profile-run-id=legality',
      '--battle-profile-output=out',
      '--battle-profile-sample-seconds=60',
      '--battle-profile-viewport=1280x720',
    ];
    expect(BattleFrameProfileRunConfig.tryParse(args)!.legalCharacter, isNull);
    for (final value in [true, false]) {
      expect(
        BattleFrameProfileRunConfig.tryParse([
          ...args,
          '--battle-profile-legal-character=$value',
        ])!.legalCharacter,
        value,
      );
    }
    for (final value in ['', 'TRUE', '1', 'yes', 'null']) {
      expect(
        () => BattleFrameProfileRunConfig.tryParse([
          ...args,
          '--battle-profile-legal-character=$value',
        ]),
        throwsFormatException,
      );
    }
  });

  test(
    'keyboard capture requires explicit production and engineering consent',
    () {
      const args = <String>[
        '--battle-profile-run-id=keyboard',
        '--battle-profile-output=out',
        '--battle-profile-sample-seconds=60',
        '--battle-profile-viewport=1280x720',
      ];
      const production = <String>[
        ...args,
        '--battle-profile-scope=production',
        '--battle-profile-content-id=stage_01_01',
      ];
      expect(
        BattleFrameProfileRunConfig.tryParse(production)!.keyboardPolicy,
        isNull,
      );
      expect(
        BattleFrameProfileRunConfig.tryParse([
          ...production,
          '--battle-profile-keyboard-policy=baseline',
        ])!.keyboardPolicy,
        'baseline',
      );
      expect(
        BattleFrameProfileRunConfig.tryParse([
          ...production,
          '--battle-profile-legal-character=false',
          '--battle-profile-keyboard-policy=survive',
        ])!.keyboardPolicy,
        'survive',
      );
      for (final extra in [
        <String>['--battle-profile-keyboard-policy=survive'],
        <String>[
          '--battle-profile-keyboard-policy=survive',
          '--battle-profile-legal-character=true',
        ],
        <String>['--battle-profile-keyboard-policy=unknown'],
        <String>['--battle-profile-keyboard-policy='],
      ]) {
        expect(
          () => BattleFrameProfileRunConfig.tryParse([...production, ...extra]),
          throwsFormatException,
        );
      }
      for (final policy in ['baseline', 'survive']) {
        expect(
          () => BattleFrameProfileRunConfig.tryParse([
            ...args,
            '--battle-profile-legal-character=false',
            '--battle-profile-keyboard-policy=$policy',
          ]),
          throwsFormatException,
        );
      }
    },
  );

  test('optional frame phases preserve scheduling gaps and frame identity', () {
    final timing = FrameTiming(
      vsyncStart: 1000,
      buildStart: 11000,
      buildFinish: 14000,
      rasterStart: 34000,
      rasterFinish: 38000,
      rasterFinishWallTime: 500000,
      frameNumber: 42,
    );
    final profile = BattleFrameProfileAccumulator(warmup: Duration.zero);
    for (final phases in [null, timing]) {
      profile.add(
        elapsed: const Duration(seconds: 10),
        build: timing.buildDuration,
        raster: timing.rasterDuration,
        totalSpan: timing.totalSpan,
        frameTiming: phases,
      );
    }
    expect(
      profile.samples.first.toJson(),
      isNot(contains('phase_timestamps_us')),
    );
    final sample = profile.samples.last.toJson();
    expect(sample['frame_number'], 42);
    expect(sample['vsync_overhead_us'], 10000);
    expect(sample['build_to_raster_gap_us'], 20000);
    expect(sample['total_span_us'], 37000);
    expect(
      (sample['phase_timestamps_us']! as Map)['rasterFinishWallTime'],
      500000,
    );
    expect(profile.summary.p99TotalSpan.inMicroseconds, 37000);
  });

  test(
    'diagnostics preserve raw chunks and restore VM settings before disposal',
    () async {
      final service = _DiagnosticVm();
      final diagnostics = BattleFrameProfileDiagnostics(
        connect: () async => service,
        isolateId: 'isolates/42',
      );
      await diagnostics.start();
      expect(service.profiler, 'true');
      expect(
        service.streams,
        containsAll(['Compiler', 'Dart', 'GC', 'Embedder']),
      );
      expect(service.streams, isNot(contains('Flutter')));
      await diagnostics.capture();
      await diagnostics.capture();
      expect(service.cpuRequests, 0);
      expect(diagnostics.cpuChunks, isEmpty);
      await diagnostics.finish();
      expect(service.cpuRequests, 1);
      expect(service.profiler, 'false');
      expect(service.streams, ['Compiler']);
      expect(service.disposed, isTrue);
      expect(service.sampleIsolate, 'isolates/42');
      expect(diagnostics.status['cpu_status'], 'COLLECTED');
      expect(diagnostics.status['timeline_status'], 'COLLECTED');
      expect(diagnostics.status['baseline_eligible'], isFalse);
      final cpu = diagnostics.cpuChunks.single;
      expect(cpu['requested_extent_us'], greaterThan(0));
      expect((cpu['response']! as Map)['samples'], hasLength(1));
      final directory = await Directory.systemTemp.createTemp(
        'battle_diagnostics_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await diagnostics.writeEvidence(directory);
      final persisted =
          jsonDecode(
                await File(
                  '${directory.path}/diagnostics-status.json',
                ).readAsString(),
              )
              as Map;
      expect(persisted['cpu_sample_count'], 1);
      expect(persisted['timeline_event_count'], 3);
      expect(
        jsonDecode(
          await File('${directory.path}/timeline.json').readAsString(),
        ),
        contains('chunks'),
      );
      expect(
        jsonDecode(
          await File('${directory.path}/cpu-profile.json').readAsString(),
        ),
        contains('chunks'),
      );
      await diagnostics.finish();
      expect(service.disposeCount, 1);
    },
  );

  test(
    'single CPU response exposes partial returned history without claiming full coverage',
    () async {
      final service = _DiagnosticVm()..partialCpu = true;
      final diagnostics = BattleFrameProfileDiagnostics(
        connect: () async => service,
        isolateId: 'isolates/42',
      );
      await diagnostics.start();
      await diagnostics.finish();
      expect(service.cpuRequests, 1);
      expect(diagnostics.status['cpu_status'], 'PARTIAL');
      final coverage = diagnostics.status['cpu_coverage']! as Map;
      expect(coverage['status'], 'PARTIAL_RANGE');
      expect(
        coverage['returned_origin_us'],
        greaterThan(coverage['requested_origin_us'] as int),
      );
      expect(diagnostics.cpuChunks, hasLength(1));
    },
  );

  test(
    'successful but empty RPC responses do not claim collected evidence',
    () async {
      final service = _DiagnosticVm()..empty = true;
      final diagnostics = BattleFrameProfileDiagnostics(
        connect: () async => service,
        isolateId: 'isolates/42',
      );
      await diagnostics.start();
      await diagnostics.finish();
      expect(diagnostics.status['cpu_status'], 'EMPTY');
      expect(diagnostics.status['timeline_status'], 'EMPTY');
    },
  );

  test(
    'failed CPU capture retains timeline and restores profiler settings',
    () async {
      final service = _DiagnosticVm()..failCpu = true;
      final diagnostics = BattleFrameProfileDiagnostics(
        connect: () async => service,
        isolateId: 'isolates/42',
      );
      await diagnostics.start();
      await diagnostics.finish();
      expect(diagnostics.status['cpu_status'], 'MISSING');
      expect(diagnostics.status['timeline_status'], 'COLLECTED');
      expect(diagnostics.errors.single['phase'], 'capture');
      expect(diagnostics.errors.single['requested_extent_us'], greaterThan(0));
      expect(service.profiler, 'false');
      expect(service.streams, ['Compiler']);
      expect(service.disposed, isTrue);
    },
  );

  test(
    'VM connection failure is explicitly missing for both sources',
    () async {
      final diagnostics = BattleFrameProfileDiagnostics(
        connect: () async => throw StateError('VM service unavailable'),
        isolateId: 'isolates/42',
      );
      await diagnostics.start();
      await diagnostics.finish();
      expect(diagnostics.status['cpu_status'], 'MISSING');
      expect(diagnostics.status['timeline_status'], 'MISSING');
      expect(diagnostics.cpuChunks, isEmpty);
      expect(diagnostics.timelineChunks, isEmpty);
    },
  );

  test(
    'macOS runner can delegate exact content viewport sizing to native shell',
    () {
      final config = BattleFrameProfileRunConfig.tryParse(const <String>[
        '--battle-profile-run-id=run-mac',
        '--battle-profile-output=out',
        '--battle-profile-sample-seconds=60',
        '--battle-profile-viewport=1440x900',
        '--battle-profile-native-content-viewport=true',
      ]);

      expect(config?.nativeContentViewport, isTrue);
    },
  );

  test('不允许负采样时长', () {
    expect(
      () => BattleFrameProfileRunConfig.tryParse(const <String>[
        '--battle-profile-run-id=run-01',
        '--battle-profile-output=out',
        '--battle-profile-sample-seconds=-1',
        '--battle-profile-warmup-seconds=12',
        '--battle-profile-viewport=1280x720',
      ]),
      throwsFormatException,
    );
  });

  test('前五秒预热不进入战斗帧性能统计', () {
    final profile = BattleFrameProfileAccumulator(
      warmup: const Duration(seconds: 5),
    );

    profile.add(
      elapsed: const Duration(seconds: 4),
      build: const Duration(milliseconds: 40),
      raster: const Duration(milliseconds: 40),
    );
    profile.add(
      elapsed: const Duration(seconds: 6),
      build: const Duration(milliseconds: 8),
      raster: const Duration(milliseconds: 9),
    );

    expect(profile.summary.sampledFrames, 1);
    expect(profile.summary.maxBuild.inMilliseconds, 8);
    expect(profile.summary.maxRaster.inMilliseconds, 9);
  });

  test('分别记录 build 与 raster 超预算连续帧峰值', () {
    final profile = BattleFrameProfileAccumulator(warmup: Duration.zero);

    for (final (buildMs, rasterMs) in const [
      (18, 8),
      (19, 18),
      (8, 19),
      (20, 20),
      (21, 8),
    ]) {
      profile.add(
        elapsed: const Duration(seconds: 10),
        build: Duration(milliseconds: buildMs),
        raster: Duration(milliseconds: rasterMs),
      );
    }

    expect(profile.summary.maxConsecutiveBuildOverBudget, 2);
    expect(profile.summary.maxConsecutiveRasterOverBudget, 3);
    expect(profile.summary.p99Build.inMilliseconds, 21);
    expect(profile.summary.p99Raster.inMilliseconds, 20);
    expect(profile.summary.passes, isFalse);
  });
}

class _DiagnosticVm extends Fake implements vm.VmService {
  String profiler = 'false';
  List<String> streams = ['Compiler'];
  bool empty = false;
  bool failCpu = false;
  bool partialCpu = false;
  int cpuRequests = 0;
  bool disposed = false;
  int disposeCount = 0;
  String? sampleIsolate;

  @override
  Future<vm.FlagList> getFlagList() async => vm.FlagList(
    flags: [vm.Flag(name: 'profiler', valueAsString: profiler)],
  );

  @override
  Future<vm.Response> setFlag(String name, String value) async {
    expect(disposed, isFalse);
    expect(name, 'profiler');
    profiler = value;
    return vm.Success();
  }

  @override
  Future<vm.TimelineFlags> getVMTimelineFlags() async => vm.TimelineFlags(
    recordedStreams: List.of(streams),
    availableStreams: ['Compiler', 'Dart', 'GC', 'Embedder'],
    recorderName: 'Ring',
  );

  @override
  Future<vm.Success> setVMTimelineFlags(List<String> recordedStreams) async {
    expect(disposed, isFalse);
    if (recordedStreams.any(
      (stream) => !['Compiler', 'Dart', 'GC', 'Embedder'].contains(stream),
    )) {
      throw StateError('Invalid recordedStreams parameter');
    }
    streams = List.of(recordedStreams);
    return vm.Success();
  }

  @override
  Future<vm.CpuSamples> getCpuSamples(
    String isolateId,
    int timeOriginMicros,
    int timeExtentMicros,
  ) async {
    expect(disposed, isFalse);
    cpuRequests++;
    sampleIsolate = isolateId;
    if (failCpu) throw StateError('CPU collection failed');
    return vm.CpuSamples(
      timeOriginMicros: timeOriginMicros + (partialCpu ? 1000 : 0),
      timeExtentMicros: timeExtentMicros,
      sampleCount: empty ? 0 : 1,
      samples: empty
          ? []
          : [vm.CpuSample(timestamp: timeOriginMicros, stack: [])],
    );
  }

  @override
  Future<vm.Timeline> getVMTimeline({
    int? timeOriginMicros,
    int? timeExtentMicros,
  }) async => vm.Timeline(
    timeOriginMicros: timeOriginMicros,
    timeExtentMicros: timeExtentMicros,
    traceEvents: empty
        ? []
        : [
            vm.TimelineEvent.parse({'name': 'Frame', 'ts': timeOriginMicros})!,
          ],
  );

  @override
  Future<void> dispose() async {
    disposed = true;
    disposeCount++;
  }
}
