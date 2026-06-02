import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/asset_fallback.dart';

void main() {
  testWidgets('debug:缺图叠角标且 fallback 仍在', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Image.asset(
        'assets/__nonexistent__.png',
        errorBuilder: wuxiaAssetErrorBuilder(() => const Text('FB')),
      ),
    ));
    await tester.pump();
    expect(find.text('FB'), findsOneWidget); // 原 fallback 保留
    expect(find.text('缺图'), findsOneWidget); // debug 角标叠加
  });
}
