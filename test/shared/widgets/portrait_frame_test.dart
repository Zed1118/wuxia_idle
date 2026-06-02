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

  testWidgets('portraitPath 为 null + 无 placeholderText → 不渲染 Image 也不显文字',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PortraitFrame(
        portraitPath: null,
        size: 48,
        borderColor: WuxiaColors.border,
      ),
    ));
    expect(find.byType(Image), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('portraitPath 为 null + placeholderText → 渲染首字水墨占位(替空框)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PortraitFrame(
        portraitPath: null,
        size: 48,
        borderColor: WuxiaColors.border,
        placeholderText: '云寒青',
      ),
    ));
    expect(find.byType(Image), findsNothing);
    // 只取首字,不显全名
    expect(find.text('云'), findsOneWidget);
    expect(find.text('云寒青'), findsNothing);
  });

  testWidgets('portraitPath 非空时 placeholderText 被忽略(优先显图)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PortraitFrame(
        portraitPath: 'assets/characters/sect_candidate_bamboo.png',
        size: 48,
        borderColor: WuxiaColors.border,
        placeholderText: '云寒青',
      ),
    ));
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('云'), findsNothing);
  });
}
