import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/features/settings/application/gameplay_settings_service.dart';
import 'package:wuxia_idle/features/settings/presentation/settings_panel.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 半手动战斗 P0 步骤5-G2:设置面板「自动战斗」全局开关。
///
/// 默认 on(autoPlayDefault=true);关闭后经 GameplaySettingsService 持久化,
/// 让玩家全局切回手动(用户拍板#2 全局设置部分)。
void main() {
  testWidgets('设置面板显「自动战斗」开关, 切换持久化', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(420, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: SettingsPanel())),
      ),
    );
    await tester.pumpAndSettle();

    // 默认 on。
    final tile = find.widgetWithText(SwitchListTile, UiStrings.settingsAutoPlayDefault);
    expect(tile, findsOneWidget);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    // 切关 → 持久化为 false。
    await tester.tap(tile);
    await tester.pumpAndSettle();
    final svc = GameplaySettingsService();
    expect((await svc.load()).autoPlayDefault, isFalse);
  });
}
