import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/projectile_trail.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

void main() {
  testWidgets('ProjectileTrail 渲染 CustomPaint 且随 animation 推进', (tester) async {
    final ctrl = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 260));
    addTearDown(ctrl.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ProjectileTrail(
                animation: ctrl,
                color: WuxiaColors.gangMeng,
                strokeWidth: 3,
                start: const Offset(0, 0),
                end: const Offset(100, 0)))));
    expect(find.byType(CustomPaint), findsWidgets);
    ctrl.forward();
    await tester.pump(const Duration(milliseconds: 130));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle(); // 收尾动画，避免 ticker 残留
  });
}
