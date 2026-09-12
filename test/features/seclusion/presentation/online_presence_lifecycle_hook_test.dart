import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/seclusion/application/online_presence_controller.dart';
import 'package:wuxia_idle/features/seclusion/presentation/offline_recap_gate.dart';
import 'package:wuxia_idle/features/seclusion/presentation/online_presence_lifecycle_hook.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';

class _RecordingController extends OnlinePresenceController {
  _RecordingController(super.ref);
  final calls = <String>[];
  @override
  void onAppFocused() => calls.add('focused');
  @override
  void onAppBlurred() => calls.add('blurred');
}

void main() {
  testWidgets('生命周期状态变化路由到 controller', (tester) async {
    late _RecordingController recorder;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onlinePresenceControllerProvider.overrideWith((ref) {
            recorder = _RecordingController(ref);
            return recorder;
          }),
        ],
        child: const OnlinePresenceLifecycleHook(child: SizedBox()),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(recorder.calls, contains('blurred'));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(recorder.calls, contains('focused'));

    // 合法过渡链:resumed → inactive → hidden(直接 resumed→hidden 断言拦截)。
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(
      recorder.calls.where((c) => c == 'blurred').length,
      greaterThanOrEqualTo(2),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  for (final startsHidden in [false, true]) {
    testWidgets(
      'startup gate preserves background state (starts hidden: $startsHidden)',
      (tester) async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        if (startsHidden) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.hidden,
          );
        }

        late OnlinePresenceController controller;
        late BuildContext gateContext;
        late WidgetRef gateRef;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeRetreatSessionProvider.overrideWith((ref) async => null),
              onlinePresenceControllerProvider.overrideWith((ref) {
                controller = OnlinePresenceController(ref);
                ref.onDispose(controller.dispose);
                return controller;
              }),
            ],
            child: MaterialApp(
              home: OnlinePresenceLifecycleHook(
                child: Consumer(
                  builder: (context, ref, child) {
                    gateContext = context;
                    gateRef = ref;
                    // The production gate reads this lazily after its first await.
                    ref.read(onlinePresenceControllerProvider);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        );
        if (startsHidden) {
          // Hidden apps do not schedule normal frames. Force only this initial
          // test frame while preserving the actual hidden lifecycle state.
          tester.binding.scheduleForcedFrame();
          await tester.pump();
        }
        if (!startsHidden) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.hidden,
          );
        }

        // Real hook -> real controller -> real startup gate. No Isar is open in
        // this widget test; persisted reward coverage lives in controller tests.
        await maybeShowOfflineRecap(context: gateContext, ref: gateRef);
        expect(controller.isHeartbeatActive, isFalse);
        await tester.pump(const Duration(minutes: 2));
        expect(controller.isHeartbeatActive, isFalse);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(controller.isHeartbeatActive, isTrue);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
