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

  testWidgets('肖像图必须撑满画框(拿到紧约束),否则焦点裁切静默失效', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        // 必须包 Center 给松约束,画框的 48×48 才真生效——直接挂 home 会被
        // 路由的紧约束撑成全屏,量到的就不是画框尺寸(本测首版即栽在这)。
        home: Center(
          child: PortraitFrame(
            portraitPath: 'assets/characters/sect_candidate_bamboo.png',
            size: 48,
            borderColor: WuxiaColors.border,
          ),
        ),
      ),
    );

    // 画框 48 - 两侧各 1px 描边 = 46。图必须被布局成 46×46 满框,
    // BoxFit.cover 才有溢出可裁、alignment 焦点才生效。
    //
    // 2026-07-26 真机实测:此前 Container 的 alignment 让子 widget 拿到**松约束**,
    // RenderImage 按源图比例(896×1344)自行收缩 → cover 在比例已吻合的盒子里
    // 不裁任何东西,12 张生产肖像的「上半身优先」全程 no-op,左右还留出
    // avatarFill 暗柱。旧断言只验 alignment **参数**传到 widget、不验渲染,
    // 故门禁长绿而功能哑——这里改断言**布局结果**。
    expect(tester.getSize(find.byType(Image)), const Size(46, 46));
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
