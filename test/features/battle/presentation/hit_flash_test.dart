import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/hit_flash.dart';

void main() {
  testWidgets('HitFlash 命中时叠半透明色块，淡出无异常', (tester) async {
    final ctrl = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 150));
    addTearDown(ctrl.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: HitFlash(
                animation: ctrl,
                color: const Color(0xFFFFFFFF),
                child: const SizedBox(width: 50, height: 50)))));
    expect(find.byType(HitFlash), findsOneWidget);
    ctrl.forward();
    await tester.pump(const Duration(milliseconds: 75));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });
}
