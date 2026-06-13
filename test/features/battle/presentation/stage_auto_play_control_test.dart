import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/battle_replay_providers.dart';
import 'package:wuxia_idle/features/battle/presentation/stage_auto_play_control.dart';
import 'package:wuxia_idle/features/settings/application/gameplay_settings_provider.dart';
import 'package:wuxia_idle/features/settings/domain/gameplay_settings.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/auto_play_toggle.dart';

/// 半手动战斗 P0 步骤5-G3:选关屏开关接线 widget。
///
/// 用 provider override 喂态(避免 testWidgets 内 Isar writeTxn 死锁,见 memory
/// feedback_isar_widget_test_deadlock)。只验 glue 读路径:provider → toggle 的
/// overrideMode/globalDefault/hasRecord 映射。写路径(选项→setAutoPlayOverride
/// writeTxn)由 stage_auto_play_state_provider_test(plain test)覆盖。
void main() {
  const key = 'stage#stage_01_01#1';

  Widget host({
    required bool? overrideMode,
    required bool hasRecord,
    required bool globalDefault,
  }) {
    return ProviderScope(
      overrides: [
        stageAutoPlayStateProvider(key).overrideWith(
          (ref) async => (overrideMode: overrideMode, hasRecord: hasRecord),
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

  testWidgets('有记录无 override + 全局默认 true → 渲染「自动」+「随设置」',
      (tester) async {
    await tester.pumpWidget(host(
      overrideMode: null,
      hasRecord: true,
      globalDefault: true,
    ));
    await tester.pumpAndSettle();
    expect(find.byType(AutoPlayToggle), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayAuto), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayFollowSuffix), findsOneWidget);
  });

  testWidgets('override=false → 渲染「手动」无「随设置」', (tester) async {
    await tester.pumpWidget(host(
      overrideMode: false,
      hasRecord: true,
      globalDefault: true,
    ));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.stageAutoPlayManual), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayFollowSuffix), findsNothing);
  });

  testWidgets('hasRecord=false(迁移豁免)→ toggle 灰显锁定(点击不弹菜单)',
      (tester) async {
    await tester.pumpWidget(host(
      overrideMode: null,
      hasRecord: false,
      globalDefault: true,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AutoPlayToggle), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.stageAutoPlayMenuManual), findsNothing);
  });

  // 爬塔路径:toggle 嵌在 AlertDialog 内(塔身固定高,走重打 dialog)。验
  // PopupMenuButton 在 dialog 上下文里照常弹三选项菜单(Codex R1 第 7 项 FAIL
  // 实为 tower 验收 route 未种 record → 落禁用态;此测锁 enabled 态 dialog 内可弹)。
  testWidgets('enabled toggle 嵌 AlertDialog 内 → 点击照常弹三选项菜单',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        stageAutoPlayStateProvider(key).overrideWith(
          (ref) async => (overrideMode: null, hasRecord: true),
        ),
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
