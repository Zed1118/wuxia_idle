import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/dark_surface_theme.dart';
import 'package:wuxia_idle/shared/theme/paper_surface_theme.dart';
import 'package:wuxia_idle/shared/theme/wuxia_app_theme.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/dark_parchment_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart';

void main() {
  test('浅宣纸主题明确提供墨色组件语义与可辨交互态', () {
    final theme = paperSurfaceTheme(wuxiaAppTheme());
    final selected = <WidgetState>{WidgetState.selected};
    final disabled = <WidgetState>{WidgetState.disabled};

    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.surface, WuxiaUi.paper);
    expect(theme.colorScheme.onSurface, WuxiaUi.ink);
    expect(theme.listTileTheme.textColor, WuxiaUi.ink);
    expect(theme.listTileTheme.iconColor, WuxiaUi.ink2);
    expect(theme.switchTheme.trackColor?.resolve(selected), WuxiaUi.jiang);
    expect(
      theme.switchTheme.trackColor?.resolve(disabled),
      isNot(WuxiaUi.jiang),
    );
    expect(
      _contrastRatio(theme.colorScheme.onSurface, theme.colorScheme.surface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('深墨主题明确提供浅字组件语义与可辨交互态', () {
    final theme = darkSurfaceTheme(wuxiaAppTheme());
    final selected = <WidgetState>{WidgetState.selected};
    final disabled = <WidgetState>{WidgetState.disabled};

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.surface, WuxiaColors.panel);
    expect(theme.colorScheme.onSurface, WuxiaColors.textPrimary);
    expect(theme.listTileTheme.textColor, WuxiaColors.textPrimary);
    expect(theme.listTileTheme.iconColor, WuxiaColors.textSecondary);
    expect(
      theme.switchTheme.trackColor?.resolve(selected),
      WuxiaColors.resultHighlight,
    );
    expect(
      theme.switchTheme.trackColor?.resolve(disabled),
      isNot(WuxiaColors.resultHighlight),
    );
    expect(
      _contrastRatio(theme.colorScheme.onSurface, theme.colorScheme.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(WuxiaUi.qingOnDark, WuxiaColors.panel),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('浅/深共享面板自动向 Material 子组件提供对应 Theme', (tester) async {
    late ThemeData lightTheme;
    late ThemeData darkTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: wuxiaAppTheme(),
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: LightPaperPanel(
                  child: Builder(
                    builder: (context) {
                      lightTheme = Theme.of(context);
                      return const ListTile(title: Text('浅面'));
                    },
                  ),
                ),
              ),
              Expanded(
                child: DarkParchmentPanel(
                  child: Builder(
                    builder: (context) {
                      darkTheme = Theme.of(context);
                      return const ListTile(title: Text('深面'));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(lightTheme.brightness, Brightness.light);
    expect(lightTheme.listTileTheme.textColor, WuxiaUi.ink);
    expect(darkTheme.brightness, Brightness.dark);
    expect(darkTheme.listTileTheme.textColor, WuxiaColors.textPrimary);
    expect(tester.takeException(), isNull);
  });
}

double _contrastRatio(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first
      : second;
  final darker = identical(lighter, first) ? second : first;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
