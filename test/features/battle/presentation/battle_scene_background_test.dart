import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_scene_background.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

Widget _wrap(Widget c) => MaterialApp(home: Scaffold(body: c));

void main() {
  testWidgets('path 非空保留背景 Image + scrim,并叠加水墨层次', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const BattleSceneBackground(path: 'assets/scenes/battle_citywall.png'),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(
      find.byKey(const ValueKey('battle_scene_ink_fallback')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('battle_scene_distant_mountains')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('battle_scene_mist_layers')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('battle_scene_ground_texture')),
      findsOneWidget,
    );
    final scrim = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == WuxiaColors.battleSceneScrim,
    );
    expect(scrim, findsOneWidget);
  });

  testWidgets('path null 仍有非空水墨兜底,且不创建背景 Image', (tester) async {
    await tester.pumpWidget(_wrap(const BattleSceneBackground(path: null)));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(
      find.byKey(const ValueKey('battle_scene_ink_fallback')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('battle_scene_distant_mountains')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('battle_scene_mist_layers')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('battle_scene_ground_texture')),
      findsOneWidget,
    );
    final scrim = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == WuxiaColors.battleSceneScrim,
    );
    expect(scrim, findsNothing);
  });

  testWidgets('style 会改变兜底基底色,用于区分关卡类型氛围', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const BattleSceneBackground(
          path: null,
          style: BattleSceneBackgroundStyle.innerDemon,
        ),
      ),
    );
    final innerDemonDecoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('battle_scene_ink_fallback')),
                )
                .decoration
            as BoxDecoration;
    final innerDemonGradient = innerDemonDecoration.gradient! as LinearGradient;

    await tester.pumpWidget(
      _wrap(
        const BattleSceneBackground(
          path: null,
          style: BattleSceneBackgroundStyle.lightFoot,
        ),
      ),
    );
    final lightFootDecoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('battle_scene_ink_fallback')),
                )
                .decoration
            as BoxDecoration;
    final lightFootGradient = lightFootDecoration.gradient! as LinearGradient;

    expect(
      innerDemonGradient.colors.first,
      isNot(lightFootGradient.colors.first),
    );
  });

  testWidgets('无图兜底覆盖常规桌面视口', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(_wrap(const BattleSceneBackground(path: null)));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('battle_scene_ink_fallback')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle_scene_glow_vignette')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
