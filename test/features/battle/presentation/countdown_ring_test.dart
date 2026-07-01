import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/countdown_ring.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget w) async {
    await t.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: w))));
  }

  testWidgets('中心数字 = remaining.ceil()', (t) async {
    await pump(
      t,
      const CountdownRing(
        remaining: 2.3,
        total: 3,
        color: Colors.amber,
        size: 40,
      ),
    );
    expect(find.text('3'), findsOneWidget); // ceil(2.3)=3
  });

  testWidgets('remaining 整数直接显示', (t) async {
    await pump(
      t,
      const CountdownRing(
        remaining: 1,
        total: 3,
        color: Colors.amber,
        size: 40,
      ),
    );
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('remaining<=0 不渲染数字', (t) async {
    await pump(
      t,
      const CountdownRing(
        remaining: 0,
        total: 3,
        color: Colors.amber,
        size: 40,
      ),
    );
    expect(find.byType(CustomPaint).evaluate().isNotEmpty, isTrue);
    expect(find.text('0'), findsNothing);
  });
}
