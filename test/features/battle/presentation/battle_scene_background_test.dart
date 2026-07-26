import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_scene_background.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/utils/asset_framing.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_image.dart';

Widget _wrap(Widget c) => MaterialApp(home: Scaffold(body: c));

void main() {
  test('普通主线遇到 Boss 时升级为 Boss 场景 profile', () {
    expect(
      battleSceneStyleForEncounter(
        BattleSceneBackgroundStyle.mainline,
        hasBoss: true,
      ),
      BattleSceneBackgroundStyle.boss,
    );
    expect(
      battleSceneStyleForEncounter(
        BattleSceneBackgroundStyle.tower,
        hasBoss: true,
      ),
      BattleSceneBackgroundStyle.tower,
    );
  });

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
    expect(
      find.byKey(const ValueKey('battle_scene_image_scrim')),
      findsOneWidget,
    );
  });

  testWidgets('有图山道使用浅暖 scrim 且收束外缘压暗', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const BattleSceneBackground(
          path: WuxiaUi.battleMountainPassStage,
          style: BattleSceneBackgroundStyle.mainline,
        ),
      ),
    );

    final scrim = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('battle_scene_image_scrim')),
    );
    expect(scrim.color.a, lessThanOrEqualTo(0.18));
    expect(scrim.color.r, greaterThan(scrim.color.b));

    final vignette =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('battle_scene_glow_vignette')),
                )
                .decoration
            as BoxDecoration;
    final gradient = vignette.gradient! as RadialGradient;
    expect(gradient.colors.last.a, lessThanOrEqualTo(0.20));
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

  testWidgets('六类有图场景使用受控且不过暗的独立 scrim profile', (tester) async {
    final colors = <Color>{};
    for (final style in const [
      BattleSceneBackgroundStyle.mainline,
      BattleSceneBackgroundStyle.tower,
      BattleSceneBackgroundStyle.boss,
      BattleSceneBackgroundStyle.innerDemon,
      BattleSceneBackgroundStyle.lightFoot,
      BattleSceneBackgroundStyle.massBattle,
    ]) {
      await tester.pumpWidget(
        _wrap(
          BattleSceneBackground(
            path: 'assets/scenes/profile_${style.name}.png',
            style: style,
          ),
        ),
      );
      final scrim = tester.widget<ColoredBox>(
        find.byKey(const ValueKey('battle_scene_image_scrim')),
      );
      colors.add(scrim.color);
      expect(scrim.color.a, lessThanOrEqualTo(0.18), reason: style.name);
      expect(
        find.byKey(ValueKey('battle_scene_profile_${style.name}')),
        findsOneWidget,
      );
    }
    expect(colors, hasLength(6));
  });

  testWidgets('爬塔背景图单独进入冷灰色分级，不染色其他战斗层', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const BattleSceneBackground(
          path: 'assets/scenes/battle_innerrealm.png',
          style: BattleSceneBackgroundStyle.tower,
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('battle_scene_tower_color_grade')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<WuxiaImage>(
            find.byKey(const ValueKey('battle_scene_tower_asset')),
          )
          .assetPath,
      WuxiaUi.battleInnerRealmCool,
    );

    await tester.pumpWidget(
      _wrap(
        const BattleSceneBackground(
          path: 'assets/scenes/battle_citywall.png',
          style: BattleSceneBackgroundStyle.mainline,
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('battle_scene_tower_color_grade')),
      findsNothing,
    );
  });

  testWidgets('主线山道背景进入轻冷灰分级，压制右半区暖黄 glow', (tester) async {
    await tester.pumpWidget(
      _wrap(const BattleSceneBackground(path: WuxiaUi.battleMountainPassStage)),
    );
    expect(
      find.byKey(const ValueKey('battle_scene_mainline_color_grade')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<WuxiaImage>(
            find.byKey(const ValueKey('battle_scene_mainline_asset')),
          )
          .assetPath,
      WuxiaUi.battleMountainPassStageCool,
    );
    expect(
      tester
          .widget<WuxiaImage>(
            find.byKey(const ValueKey('battle_scene_mainline_asset')),
          )
          .alignment,
      assetFramingForScene(WuxiaUi.battleMountainPassStageCool).alignment,
    );
    expect(
      find.byKey(const ValueKey('battle_scene_tower_color_grade')),
      findsNothing,
    );
  });

  testWidgets('断崖瀑布背景消费登记焦点，普通背景仍保持居中', (tester) async {
    const cliffPath = 'assets/scenes/battle_cliffwaterfall.png';
    await tester.pumpWidget(
      _wrap(const BattleSceneBackground(path: cliffPath)),
    );
    expect(
      tester.widget<WuxiaImage>(find.byType(WuxiaImage)).alignment,
      assetFramingForScene(cliffPath).alignment,
    );

    await tester.pumpWidget(
      _wrap(
        const BattleSceneBackground(path: 'assets/scenes/battle_citywall.png'),
      ),
    );
    expect(
      tester.widget<WuxiaImage>(find.byType(WuxiaImage)).alignment,
      Alignment.center,
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
