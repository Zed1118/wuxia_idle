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
  reason: 'timer_completed',
  sampledFrames: window.config.sample.inSeconds * 60,
);

void main() {
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
          reason: 'timer_completed',
          sampledFrames: 1,
        ),
        contains('insufficient_frames'),
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
