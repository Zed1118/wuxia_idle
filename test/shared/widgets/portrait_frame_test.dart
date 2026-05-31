import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/widgets/portrait_frame.dart';

void main() {
  testWidgets('portraitPath 非空 → 渲染 Image', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PortraitFrame(
        portraitPath: 'assets/characters/sect_candidate_bamboo.png',
        size: 48,
        borderColor: WuxiaColors.border,
      ),
    ));
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('portraitPath 为 null → 不渲染 Image(SizedBox.shrink)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PortraitFrame(
        portraitPath: null,
        size: 48,
        borderColor: WuxiaColors.border,
      ),
    ));
    expect(find.byType(Image), findsNothing);
  });
}
