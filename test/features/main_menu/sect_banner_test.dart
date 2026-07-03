import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/main_menu/presentation/sect_banner.dart';

void main() {
  testWidgets('SectBanner 显示门派名', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SectBanner(sectName: '青城派'))),
    );
    expect(find.text('青城派'), findsOneWidget);
  });
}
