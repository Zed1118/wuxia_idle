import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/battle_frame_profile.dart';
import 'package:wuxia_idle/features/debug/application/production_battle_frame_profile.dart';

BattleFrameProfileRunConfig config({int sample = 60, int cooldown = 30}) =>
    BattleFrameProfileRunConfig.tryParse([
      '--battle-profile-scope=production',
      '--battle-profile-content-id=stage_01_03',
      '--battle-profile-run-id=contract',
      '--battle-profile-output=unused',
      '--battle-profile-sample-seconds=$sample',
      '--battle-profile-cooldown-seconds=$cooldown',
      '--battle-profile-viewport=1280x720',
    ])!;

ProductionProfileWindow continuous({int sample = 60, int cooldown = 30}) {
  final window = ProductionProfileWindow(
    config(sample: sample, cooldown: cooldown),
  );
  for (var second = 0; second < 12 + sample + cooldown; second++) {
    final elapsed = Duration(seconds: second);
    window.workload(elapsed, {
      'tick': second * 60,
      'active_enemies': 12,
      'combat_ongoing': true,
    });
    window.viewport(elapsed, 1280, 720, 2);
    window.activity(
      elapsed,
      paused: false,
      foreground: true,
      combatOngoing: true,
    );
  }
  return window;
}

Set<String> finished(ProductionProfileWindow window) => window.reasonsAtEnd(
  elapsed: window.config.total,
  reason: 'sample_complete',
  sampledFrames: window.config.sample.inSeconds * 60,
);

void main() {
  group('capture identity', () {
    late Directory output;
    late _ObservedOwner owner;
    late BattleFrameProfileRunConfig requested;

    setUp(() {
      output = Directory.systemTemp.createTempSync('production_identity_');
      owner = _ObservedOwner();
      requested = BattleFrameProfileProbe.configureFromArgs([
        '--battle-profile-scope=production',
        '--battle-profile-content-id=stage_01_03',
        '--battle-profile-run-id=identity',
        '--battle-profile-output=${output.path}',
        '--battle-profile-warmup-seconds=0',
        '--battle-profile-sample-seconds=60',
        '--battle-profile-viewport=1280x720',
      ])!;
      BattleFrameProfileProbe.recordEntryOrigin(visual: false);
    });

    tearDown(() async {
      await ProductionBattleFrameProfile.flushPendingEvidence();
      owner.dispose();
      BattleFrameProfileProbe.configureFromArgs([]);
      output.deleteSync(recursive: true);
    });

    Widget tree(
      Map<String, Object?> scene, {
      ValueNotifier<bool>? replacementOwner,
      BattleFrameProfileRunConfig? replacementConfig,
      BattleFrameProfileDiagnostics Function()? diagnosticsFactory,
      Widget child = const SizedBox.shrink(),
    }) => MediaQuery(
      data: const MediaQueryData(size: Size(1280, 720), devicePixelRatio: 2),
      child: ProductionBattleFrameProfile(
        owner: replacementOwner ?? owner,
        config: replacementConfig ?? requested,
        scene: scene,
        diagnosticsFactory: diagnosticsFactory,
        isCombatOngoing: () => (replacementOwner ?? owner).value,
        readWorkload: () => {
          'tick': 1,
          'active_enemies': 12,
          'combat_ongoing': (replacementOwner ?? owner).value,
        },
        child: child,
      ),
    );

    Future<Map<String, dynamic>> finish(WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await ProductionBattleFrameProfile.flushPendingEvidence();
      });
      return jsonDecode(File('${output.path}/summary.json').readAsStringSync())
          as Map<String, dynamic>;
    }

    testWidgets('nested scene changes remain rejected after restoring values', (
      tester,
    ) async {
      final effects = <String, Object?>{'reduce_effects': false};
      final layers = <Object?>['ink', 'warning'];
      final scene = <String, Object?>{
        'content_id': 'stage_01_03',
        'configuration': {'effects': effects, 'layers': layers},
      };
      await tester.runAsync(() => tester.pumpWidget(tree(scene)));
      try {
        effects['reduce_effects'] = true;
        layers.removeLast();
        await tester.runAsync(() => tester.pumpWidget(tree(scene)));
        effects['reduce_effects'] = false;
        layers.add('warning');
        await tester.runAsync(() => tester.pumpWidget(tree(scene)));
      } finally {
        final evidence = await finish(tester);
        expect(
          evidence['invalid_reasons'],
          contains('scene_configuration_changed'),
        );
        expect(evidence['scene'], scene);
        expect(evidence['scene_at_capture_end'], scene);
        expect(evidence['composite_gate'], isFalse);
      }
    });

    testWidgets(
      'equivalent rebuilt configuration does not reject the capture',
      (tester) async {
        await tester.runAsync(
          () => tester.pumpWidget(
            tree({
              'content_id': 'stage_01_03',
              'configuration': {
                'effects': {'reduce_effects': false, 'reduce_flashing': true},
                'layers': ['ink', 'warning'],
              },
            }),
          ),
        );
        try {
          // Fresh maps, nested key order and equal config values are not drift.
          await tester.runAsync(
            () => tester.pumpWidget(
              tree({
                'configuration': {
                  'layers': ['ink', 'warning'],
                  'effects': {'reduce_flashing': true, 'reduce_effects': false},
                },
                'content_id': 'stage_01_03',
              }, replacementConfig: _copyConfig(requested)),
            ),
          );
          expect(ProductionBattleFrameProfile.isCapturing, isTrue);
        } finally {
          final evidence = await finish(tester);
          expect(
            evidence['invalid_reasons'],
            isNot(contains('scene_configuration_changed')),
          );
          expect(
            evidence['invalid_reasons'],
            isNot(contains('profile_config_changed')),
          );
        }
      },
    );

    testWidgets('owner replacement stops capture and detaches the old owner', (
      tester,
    ) async {
      final replacement = _ObservedOwner();
      addTearDown(replacement.dispose);
      await tester.runAsync(() => tester.pumpWidget(tree(const {})));
      try {
        expect(owner.isObserved, isTrue);
        await tester.runAsync(
          () =>
              tester.pumpWidget(tree(const {}, replacementOwner: replacement)),
        );
        expect(owner.isObserved, isFalse);
        expect(replacement.isObserved, isFalse);
        expect(ProductionBattleFrameProfile.isCapturing, isFalse);
        owner.value = false;
        replacement.value = false;
      } finally {
        final evidence = await finish(tester);
        expect(evidence['invalid_reasons'], contains('battle_owner_changed'));
        expect(evidence['capture_end_reason'], 'profile_identity_changed');
        expect(evidence['composite_gate'], isFalse);
      }
    });

    testWidgets('changing the legality declaration invalidates capture', (
      tester,
    ) async {
      await tester.runAsync(() => tester.pumpWidget(tree(const {})));
      try {
        await tester.runAsync(
          () => tester.pumpWidget(
            tree(
              const {},
              replacementConfig: _copyConfig(requested, legalCharacter: false),
            ),
          ),
        );
      } finally {
        final evidence = await finish(tester);
        expect(evidence['capture_end_reason'], 'profile_identity_changed');
        expect(evidence['invalid_reasons'], contains('profile_config_changed'));
        expect(evidence['capture_window_valid'], isFalse);
      }
    });

    for (final diagnosticsEnabled in [false, true]) {
      testWidgets(
        'production diagnostics are opt-in and flushed: $diagnosticsEnabled',
        (tester) async {
          requested = BattleFrameProfileProbe.configureFromArgs([
            '--battle-profile-scope=production',
            '--battle-profile-content-id=stage_01_03',
            '--battle-profile-run-id=identity',
            '--battle-profile-output=${output.path}',
            '--battle-profile-sample-seconds=60',
            '--battle-profile-viewport=1280x720',
            '--battle-profile-diagnostics=$diagnosticsEnabled',
          ])!;
          BattleFrameProfileProbe.recordEntryOrigin(visual: false);
          var created = 0;
          var connectionAttempts = 0;
          await tester.runAsync(
            () => tester.pumpWidget(
              tree(
                const {},
                diagnosticsFactory: () {
                  created++;
                  return BattleFrameProfileDiagnostics(
                    connect: () async {
                      connectionAttempts++;
                      throw StateError('No VM service in this widget test');
                    },
                  );
                },
              ),
            ),
          );
          final evidence = await finish(tester);
          expect(created, diagnosticsEnabled ? 1 : 0);
          expect(connectionAttempts, diagnosticsEnabled ? 1 : 0);
          expect(evidence['diagnostics_enabled'], diagnosticsEnabled);
          expect(evidence['capture_window_valid'], isFalse);
          for (final name in [
            'timeline.json',
            'cpu-profile.json',
            'diagnostics-status.json',
          ]) {
            expect(
              File('${output.path}/$name').existsSync(),
              diagnosticsEnabled,
            );
          }
          if (diagnosticsEnabled) {
            expect(
              evidence['invalid_reasons'],
              contains('diagnostic_run_not_baseline'),
            );
            final diagnostics = evidence['diagnostics'] as Map;
            expect(diagnostics['timeline_status'], 'MISSING');
            expect(diagnostics['cpu_status'], 'MISSING');
            expect(diagnostics['baseline_eligible'], isFalse);
          } else {
            expect(evidence, isNot(contains('diagnostics')));
          }
        },
      );
    }

    testWidgets('async write preserves start and capture-end snapshots', (
      tester,
    ) async {
      final effects = <String, Object?>{'reduce_effects': false};
      final layers = <Object?>['ink', 'warning'];
      final scene = <String, Object?>{
        'configuration': {'effects': effects, 'layers': layers},
      };
      await tester.runAsync(() => tester.pumpWidget(tree(scene)));
      try {
        effects['reduce_effects'] = true;
        layers.removeAt(0);
        await tester.runAsync(
          () => tester.pumpWidget(
            tree(
              scene,
              replacementConfig: _copyConfig(
                requested,
                outputDirectory: '${output.path}/wrong-output',
                runId: 'wrong-run',
              ),
              child: Builder(
                // Build runs after didUpdateWidget has ended the capture, but
                // before its awaited telemetry/write can complete.
                builder: (_) {
                  effects['reduce_effects'] = false;
                  layers.clear();
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      } finally {
        final evidence = await finish(tester);
        expect(evidence['run_id'], 'identity');
        expect(evidence['scene'], {
          'configuration': {
            'effects': {'reduce_effects': false},
            'layers': ['ink', 'warning'],
          },
        });
        expect(evidence['scene_at_capture_end'], {
          'configuration': {
            'effects': {'reduce_effects': true},
            'layers': ['warning'],
          },
        });
        expect(
          evidence['invalid_reasons'],
          containsAll([
            'scene_configuration_changed',
            'profile_config_changed',
          ]),
        );
        expect(Directory('${output.path}/wrong-output').existsSync(), isFalse);
        expect(evidence['composite_gate'], isFalse);
      }
    });
  });

  testWidgets(
    'initial background, owner notifications and pause survive disposal',
    (tester) async {
      final output = Directory.systemTemp.createTempSync(
        'production_activity_',
      );
      final owner = ValueNotifier<bool>(true);
      addTearDown(owner.dispose);
      addTearDown(() => output.deleteSync(recursive: true));
      addTearDown(() => BattleFrameProfileProbe.configureFromArgs([]));
      final requested = BattleFrameProfileProbe.configureFromArgs([
        '--battle-profile-scope=production',
        '--battle-profile-content-id=stage_01_03',
        '--battle-profile-run-id=activity',
        '--battle-profile-output=${output.path}',
        '--battle-profile-warmup-seconds=0',
        '--battle-profile-sample-seconds=60',
        '--battle-profile-viewport=1280x720',
      ])!;
      BattleFrameProfileProbe.recordEntryOrigin(visual: false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(1280, 720),
              devicePixelRatio: 2,
            ),
            child: ProductionBattleFrameProfile(
              owner: owner,
              config: requested,
              scene: const {},
              isCombatOngoing: () => owner.value,
              readWorkload: () => {
                'tick': 1,
                'active_enemies': 12,
                'combat_ongoing': owner.value,
              },
              child: const SizedBox.shrink(),
            ),
          ),
        );
      });
      expect(ProductionBattleFrameProfile.isCapturing, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      ProductionBattleFrameProfile.recordActivity(
        owner,
        paused: true,
        foreground: true,
        combatOngoing: true,
      );
      // There is no frame pump after this notification: the controller/owner
      // callback must record terminal immediately, before a periodic sample.
      owner.value = false;
      owner.value =
          true; // Restore before disposal: only the listener saw terminal.
      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await ProductionBattleFrameProfile.flushPendingEvidence();
      });
      final evidence =
          jsonDecode(File('${output.path}/summary.json').readAsStringSync())
              as Map;
      expect(
        evidence['invalid_reasons'],
        containsAll([
          'backgrounded_during_sample',
          'paused_during_sample',
          'combat_finished_during_sample',
          'capture_ended_early',
        ]),
      );
      expect(evidence['composite_gate'], isFalse);
      expect(evidence['device_pixel_ratio'], 2);
      expect(ProductionBattleFrameProfile.isCapturing, isFalse);
    },
  );

  test('complete continuously advancing 60s window is eligible', () {
    expect(finished(continuous()), isEmpty);
  });

  test(
    'battle input focus loss in the sample remains invalid after returning',
    () {
      final window = continuous();
      window.inputFocus(const Duration(seconds: 30), hasPrimaryFocus: false);
      window.inputFocus(const Duration(seconds: 31), hasPrimaryFocus: true);
      expect(finished(window), contains('battle_input_focus_lost'));
      final outsideSample = continuous();
      outsideSample.inputFocus(
        const Duration(seconds: 3),
        hasPrimaryFocus: false,
      );
      outsideSample.inputFocus(
        const Duration(seconds: 75),
        hasPrimaryFocus: false,
      );
      expect(finished(outsideSample), isEmpty);
    },
  );

  test(
    'fast raw frames do not certify short, early or missing battle samples',
    () {
      expect(
        finished(continuous(sample: 5)),
        contains('sample_shorter_than_60s'),
      );
      expect(
        finished(continuous(cooldown: 0)),
        contains('cooldown_shorter_than_30s'),
      );
      final window = continuous();
      expect(
        window.reasonsAtEnd(
          elapsed: const Duration(seconds: 18),
          reason: 'host_disposed',
          sampledFrames: 3600,
        ),
        contains('capture_ended_early'),
      );
      expect(
        finished(ProductionProfileWindow(config())),
        contains('incomplete_workload_coverage'),
      );
      expect(
        window.reasonsAtEnd(
          elapsed: window.config.total,
          reason: 'sample_complete',
          sampledFrames: 1,
        ),
        contains('insufficient_frames'),
      );
      for (final frames in [0, 2880, 2999]) {
        expect(
          window.reasonsAtEnd(
            elapsed: window.config.total,
            reason: 'sample_complete',
            sampledFrames: frames,
          ),
          contains('insufficient_frames'),
        );
      }
      expect(
        window.reasonsAtEnd(
          elapsed: window.config.total,
          reason: 'sample_complete',
          sampledFrames: 3000,
        ),
        isEmpty,
      );
      expect(
        window.reasonsAtEnd(
          elapsed: const Duration(seconds: 72),
          reason: 'sample_complete',
          sampledFrames: 3600,
        ),
        contains('capture_ended_early'),
      );
    },
  );

  test(
    'pause, background and terminal in the final subsecond cannot be hidden',
    () {
      for (final reason in [
        'paused_during_sample',
        'backgrounded_during_sample',
        'combat_finished_during_sample',
      ]) {
        final window = continuous();
        window.activity(
          const Duration(milliseconds: 71950),
          paused: reason == 'paused_during_sample',
          foreground: reason != 'backgrounded_during_sample',
          combatOngoing: reason != 'combat_finished_during_sample',
        );
        expect(finished(window), contains(reason));
      }
    },
  );

  test(
    'warmup and cooldown activities do not contaminate the combat interval',
    () {
      final window = continuous();
      for (final second in [3, 75]) {
        window.activity(
          Duration(seconds: second),
          paused: true,
          foreground: false,
          combatOngoing: false,
        );
      }
      expect(finished(window), isEmpty);
    },
  );

  test('stalled simulation with rendered frames is rejected', () {
    final window = ProductionProfileWindow(config());
    for (var second = 0; second < 102; second++) {
      window.workload(Duration(seconds: second), {
        'tick': 600,
        'active_enemies': 12,
        'combat_ongoing': true,
      });
    }
    expect(finished(window), contains('simulation_not_advancing'));
  });

  test('resizing back at the end cannot conceal smaller sample viewport', () {
    final window = continuous();
    window.viewport(const Duration(seconds: 40), 640, 360, 2);
    window.viewport(const Duration(seconds: 90), 1280, 720, 2);
    expect(finished(window), contains('viewport_mismatch'));
    final dpr = continuous();
    dpr.viewport(const Duration(seconds: 40), 1280, 720, 1);
    dpr.viewport(const Duration(seconds: 90), 1280, 720, 2);
    expect(finished(dpr), contains('device_pixel_ratio_changed'));
  });

  test('normal root, exact content and a single claim are required', () {
    addTearDown(() => BattleFrameProfileProbe.configureFromArgs([]));
    const args = [
      '--battle-profile-scope=production',
      '--battle-profile-content-id=stage_01_03',
      '--battle-profile-run-id=selection',
      '--battle-profile-output=unused',
      '--battle-profile-sample-seconds=60',
      '--battle-profile-viewport=1280x720',
    ];
    final requested = BattleFrameProfileProbe.configureFromArgs(args)!;
    expect(BattleFrameProfileProbe.productionConfigFor('stage_01_03'), isNull);
    expect(
      () => BattleFrameProfileProbe.recordEntryOrigin(visual: true),
      throwsStateError,
    );
    expect(BattleFrameProfileProbe.productionConfigFor('stage_01_03'), isNull);
    BattleFrameProfileProbe.recordEntryOrigin(visual: false);
    expect(BattleFrameProfileProbe.productionConfigFor('stage_01_01'), isNull);
    expect(
      BattleFrameProfileProbe.productionConfigFor('stage_01_03'),
      same(requested),
    );
    expect(BattleFrameProfileProbe.claimProductionRun(config()), isFalse);
    expect(BattleFrameProfileProbe.claimProductionRun(requested), isTrue);
    expect(BattleFrameProfileProbe.claimProductionRun(requested), isFalse);
    BattleFrameProfileProbe.configureFromArgs([]);
    expect(BattleFrameProfileProbe.productionConfigFor('stage_01_03'), isNull);
    for (final replacement in [
      '--battle-profile-scope=visual',
      '--battle-profile-scope=unknown',
      '--battle-profile-content-id=',
    ]) {
      final key = replacement.split('=').first;
      expect(
        () => BattleFrameProfileRunConfig.tryParse([
          ...args.where((arg) => !arg.startsWith('$key=')),
          replacement,
        ]),
        throwsFormatException,
      );
    }
  });
}

class _ObservedOwner extends ValueNotifier<bool> {
  _ObservedOwner() : super(true);

  bool get isObserved => hasListeners;
}

BattleFrameProfileRunConfig _copyConfig(
  BattleFrameProfileRunConfig source, {
  String? runId,
  String? outputDirectory,
  bool? legalCharacter,
}) => BattleFrameProfileRunConfig(
  runId: runId ?? source.runId,
  outputDirectory: outputDirectory ?? source.outputDirectory,
  sample: source.sample,
  warmup: source.warmup,
  cooldown: source.cooldown,
  autoClose: source.autoClose,
  viewportWidth: source.viewportWidth,
  viewportHeight: source.viewportHeight,
  nativeContentViewport: source.nativeContentViewport,
  diagnostics: source.diagnostics,
  scope: source.scope,
  contentId: source.contentId,
  legalCharacter: legalCharacter ?? source.legalCharacter,
  keyboardPolicy: source.keyboardPolicy,
);
