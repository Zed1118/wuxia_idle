import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/utils/asset_framing.dart';
import 'package:wuxia_idle/shared/widgets/portrait_frame.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_image.dart';

void main() {
  testWidgets('portraitPath 非空 → 渲染 Image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PortraitFrame(
          portraitPath: 'assets/characters/sect_candidate_bamboo.png',
          size: 48,
          borderColor: WuxiaColors.border,
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(
      tester.widget<WuxiaImage>(find.byType(WuxiaImage)).alignment,
      assetFramingForPortrait(
        'assets/characters/sect_candidate_bamboo.png',
      ).alignment,
    );
  });

  testWidgets('调用方可覆盖生产肖像焦点，不改变画框尺寸与 fit', (tester) async {
    const alignment = Alignment(0.2, -0.7);
    await tester.pumpWidget(
      const MaterialApp(
        home: PortraitFrame(
          portraitPath: 'assets/characters/sect_candidate_bamboo.png',
          size: 48,
          borderColor: WuxiaColors.border,
          alignment: alignment,
        ),
      ),
    );

    final image = tester.widget<WuxiaImage>(find.byType(WuxiaImage));
    expect(image.alignment, alignment);
    expect(image.fit, BoxFit.cover);
    final frame = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(PortraitFrame),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.constraints?.maxWidth == 48 &&
                  widget.constraints?.maxHeight == 48,
            ),
          )
          .first,
    );
    expect(frame.constraints?.biggest, const Size(48, 48));
  });

  testWidgets('portraitPath 为 null + 无 placeholderText → 不渲染 Image 也不显文字', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PortraitFrame(
          portraitPath: null,
          size: 48,
          borderColor: WuxiaColors.border,
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('portraitPath 为 null + placeholderText → 渲染首字水墨占位(替空框)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PortraitFrame(
          portraitPath: null,
          size: 48,
          borderColor: WuxiaColors.border,
          placeholderText: '云寒青',
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    // 只取首字,不显全名
    expect(find.text('云'), findsOneWidget);
    expect(find.text('云寒青'), findsNothing);
  });

  testWidgets('portraitPath 为 null + shape → 渲染纯墨剪影与小印', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PortraitFrame(
          portraitPath: null,
          size: 48,
          borderColor: WuxiaColors.gangMeng,
          placeholderText: '云寒青',
          placeholderShapePath: 'assets/characters/battle_first_disciple.png',
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('portraitFrame.inkSilhouette')),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('云'), findsOneWidget);
    expect(find.text('云寒青'), findsNothing);
  });

  testWidgets('portraitPath 非空时 placeholderText 被忽略(优先显图)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PortraitFrame(
          portraitPath: 'assets/characters/sect_candidate_bamboo.png',
          size: 48,
          borderColor: WuxiaColors.border,
          placeholderText: '云寒青',
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('云'), findsNothing);
  });

  testWidgets('立绘加载失败时回退到 placeholderText 首字', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PortraitFrame(
          portraitPath: 'assets/characters/not_found.png',
          size: 48,
          borderColor: WuxiaColors.border,
          placeholderText: '云寒青',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('云'), findsOneWidget);
    expect(find.text('云寒青'), findsNothing);
  });
}
