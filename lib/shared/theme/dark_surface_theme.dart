import 'package:flutter/material.dart';

import 'colors.dart';
import 'wuxia_tokens.dart';

/// 深墨/暗宣纸表面的 Material 组件主题。
///
/// 与 [paperSurfaceTheme] 对称：共享深色面板不能只靠 `DefaultTextStyle`
/// 猜测前景色，ListTile、表单和弹出菜单也要明确读取深面语义。色值保持现有
/// 全局深色主题，不改变组件几何、密度或页面布局。
ThemeData darkSurfaceTheme(ThemeData baseTheme) {
  final colorScheme = baseTheme.colorScheme.copyWith(
    brightness: Brightness.dark,
    primary: WuxiaColors.resultHighlight,
    onPrimary: WuxiaColors.background,
    secondary: WuxiaColors.internalForce,
    onSecondary: WuxiaColors.textPrimary,
    surface: WuxiaColors.panel,
    onSurface: WuxiaColors.textPrimary,
    error: WuxiaColors.danger,
    onError: WuxiaColors.textPrimary,
    outline: WuxiaColors.inkPanelEdge,
    outlineVariant: WuxiaColors.border,
  );
  final textTheme = baseTheme.textTheme.apply(
    bodyColor: WuxiaColors.textPrimary,
    displayColor: WuxiaColors.textPrimary,
  );
  final disabledText = WuxiaColors.textMuted.withValues(alpha: 0.58);

  return baseTheme.copyWith(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    canvasColor: WuxiaColors.paperUnderlay,
    cardColor: WuxiaColors.panel,
    dividerColor: WuxiaColors.border,
    disabledColor: disabledText,
    focusColor: WuxiaColors.resultHighlight.withValues(alpha: 0.14),
    hoverColor: WuxiaColors.textPrimary.withValues(alpha: 0.06),
    highlightColor: WuxiaColors.resultHighlight.withValues(alpha: 0.08),
    splashColor: Colors.transparent,
    iconTheme: const IconThemeData(color: WuxiaColors.textSecondary),
    listTileTheme: ListTileThemeData(
      iconColor: WuxiaColors.textSecondary,
      textColor: WuxiaColors.textPrimary,
      titleTextStyle: textTheme.bodyLarge?.copyWith(
        color: WuxiaColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(
        color: WuxiaColors.textSecondary,
        height: 1.35,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: WuxiaColors.border,
      thickness: 1,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledText;
        if (states.contains(WidgetState.selected)) {
          return WuxiaColors.background;
        }
        return WuxiaColors.textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return WuxiaColors.buttonDisabled.withValues(alpha: 0.58);
        }
        if (states.contains(WidgetState.selected)) {
          return WuxiaColors.resultHighlight;
        }
        return WuxiaColors.barTrack;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return WuxiaColors.resultHighlight.withValues(alpha: 0.86);
        }
        return WuxiaColors.textMuted.withValues(alpha: 0.68);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledText;
        if (states.contains(WidgetState.selected)) {
          return WuxiaColors.resultHighlight;
        }
        return Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(WuxiaColors.background),
      side: const BorderSide(color: WuxiaColors.textMuted, width: 1.4),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledText;
        if (states.contains(WidgetState.selected)) {
          return WuxiaColors.resultHighlight;
        }
        return WuxiaColors.textMuted;
      }),
    ),
    sliderTheme: baseTheme.sliderTheme.copyWith(
      activeTrackColor: WuxiaColors.resultHighlight,
      inactiveTrackColor: WuxiaColors.barTrack,
      disabledActiveTrackColor: disabledText,
      disabledInactiveTrackColor: WuxiaColors.buttonDisabled,
      thumbColor: WuxiaColors.resultHighlight,
      disabledThumbColor: disabledText,
      overlayColor: WuxiaColors.resultHighlight.withValues(alpha: 0.12),
      valueIndicatorColor: WuxiaUi.paper,
      valueIndicatorTextStyle: const TextStyle(color: WuxiaUi.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WuxiaColors.background.withValues(alpha: 0.46),
      labelStyle: const TextStyle(color: WuxiaColors.textSecondary),
      floatingLabelStyle: const TextStyle(color: WuxiaColors.resultHighlight),
      helperStyle: const TextStyle(color: WuxiaColors.textSecondary),
      hintStyle: const TextStyle(color: WuxiaColors.textMuted),
      prefixStyle: const TextStyle(color: WuxiaColors.textPrimary),
      suffixStyle: const TextStyle(color: WuxiaColors.textPrimary),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: WuxiaColors.inkPanelEdge),
        borderRadius: BorderRadius.circular(4),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: WuxiaColors.resultHighlight,
          width: 1.6,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: disabledText),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: textTheme.bodyMedium?.copyWith(color: WuxiaColors.textPrimary),
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(WuxiaColors.panel),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(
          BorderSide(color: WuxiaColors.inkPanelEdge),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: WuxiaColors.panel,
      surfaceTintColor: Colors.transparent,
      textStyle: textTheme.bodyMedium?.copyWith(color: WuxiaColors.textPrimary),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(WuxiaColors.panel),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: WuxiaUi.paper,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: WuxiaUi.woodDark),
      ),
      textStyle: const TextStyle(color: WuxiaUi.ink),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: WuxiaColors.resultHighlight,
      selectionColor: WuxiaColors.resultHighlight.withValues(alpha: 0.22),
      selectionHandleColor: WuxiaColors.resultHighlight,
    ),
  );
}
