import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/presentation/hitbox_debug_overlay.dart';

void main() {
  testWidgets('disabled by default wraps nothing in test env', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HitboxDebugOverlay.maybeWrap(
          const Scaffold(body: TextButton(onPressed: null, child: Text('A'))),
        ),
      ),
    );

    expect(find.byType(HitboxDebugOverlay), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });
}
