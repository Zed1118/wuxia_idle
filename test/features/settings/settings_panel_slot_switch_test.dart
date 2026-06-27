import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/features/settings/presentation/settings_panel.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 多存档槽(spec B §3.6):设置面板存「切换存档」入口。
void main() {
  testWidgets('设置面板含「切换存档」入口(可滚动可达)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: SettingsPanel())),
      ),
    );
    await tester.pumpAndSettle();

    final entry = find.text(UiStrings.slotSwitch);
    await tester.scrollUntilVisible(entry, 120);
    expect(entry, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
