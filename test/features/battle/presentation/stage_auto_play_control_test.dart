import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/stage_auto_play_pref.dart';
import 'package:wuxia_idle/features/battle/presentation/stage_auto_play_control.dart';
import 'package:wuxia_idle/features/settings/application/gameplay_settings_provider.dart';
import 'package:wuxia_idle/features/settings/domain/gameplay_settings.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/auto_play_toggle.dart';

/// 战斗交互重做 Phase 3:选关屏「挂机自动 / 允许拖招」开关接线 widget。
///
/// 用 provider override 喂态。只验 glue 读路径:override + global → toggle 的
/// overrideMode/globalDefault 映射(toggle 永远可切,无 hasRecord 灰显)。写路径
/// 由 stage_auto_play_state_provider_test(plain test)覆盖。
void main() {
  const key = 'stage#stage_01_01#1';

  Widget host({
    required bool? overrideMode,
    required bool globalDefault,
  }) {
    return ProviderScope(
      overrides: [
        stageAutoPlayOverrideProvider(key).overrideWith(
          (ref) async => overrideMode,
        ),
        gameplaySettingsProvider.overrideWith(
          (ref) async => GameplaySettings(autoPlayDefault: globalDefault),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(child: StageAutoPlayControl(battleKey: key)),
        ),
      ),
    );
  }

  testWidgets('无 override + 全局默认 true → 渲染「自动」+「随设置」',
      (tester) async {
    await tester.pumpWidget(host(overrideMode: null, globalDefault: true));
    await tester.pumpAndSettle();
    expect(find.byType(AutoPlayToggle), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayAuto), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayFollowSuffix), findsOneWidget);
  });

  testWidgets('override=false → 渲染「拖招」无「随设置」', (tester) async {
    await tester.pumpWidget(host(overrideMode: false, globalDefault: true));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.stageAutoPlayManual), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayFollowSuffix), findsNothing);
  });

  testWidgets('点击 toggle → 弹三选项菜单(跟随/挂机自动/允许拖招)',
      (tester) async {
    await tester.pumpWidget(host(overrideMode: null, globalDefault: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AutoPlayToggle));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.stageAutoPlayMenuFollow), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayMenuAuto), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayMenuManual), findsOneWidget);
  });

  // 爬塔路径:toggle 嵌在 AlertDialog 内(塔身固定高,走重打 dialog)。验
  // PopupMenuButton 在 dialog 上下文里照常弹三选项菜单。
  testWidgets('toggle 嵌 AlertDialog 内 → 点击照常弹三选项菜单',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        stageAutoPlayOverrideProvider(key).overrideWith((ref) async => null),
        gameplaySettingsProvider.overrideWith(
          (ref) async => const GameplaySettings(autoPlayDefault: true),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => const AlertDialog(
                    content: StageAutoPlayControl(battleKey: key),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(AutoPlayToggle), findsOneWidget);

    await tester.tap(find.byType(AutoPlayToggle));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.stageAutoPlayMenuFollow), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayMenuAuto), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayMenuManual), findsOneWidget);
  });
}
