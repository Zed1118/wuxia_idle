import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/features/settings/presentation/settings_panel.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// L1-2 回归:1280×720 下设置面板（含显示设置段后内容变高）底部 overflow
/// （Codex 验收 `RenderFlex overflowed by 4.0 pixels`）。窄高度应可滚动不溢出。
void main() {
  testWidgets('窄高度（模拟 720p dialog 可用区）下设置面板可滚动、无 overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    // 360 宽 = PaperDialog body 宽;500 高 = 720p 窗口扣 insets 后偏紧的可用高度。
    await tester.binding.setSurfaceSize(const Size(360, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: SettingsPanel())),
      ),
    );
    await tester.pumpAndSettle();

    // 无 RenderFlex overflow 异常。
    expect(tester.takeException(), isNull);
    // 完整内容仍在(显示设置段 + 末尾退出游戏均可达,经滚动)。
    expect(find.text(UiStrings.settingsFullscreen), findsOneWidget);
  });
}
