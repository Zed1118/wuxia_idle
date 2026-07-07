import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/seclusion/application/online_presence_controller.dart';
import 'package:wuxia_idle/features/seclusion/presentation/online_presence_lifecycle_hook.dart';

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
  });
}
