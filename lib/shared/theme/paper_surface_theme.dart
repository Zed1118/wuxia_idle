import 'package:flutter/material.dart';

import 'wuxia_tokens.dart';

/// 浅宣纸表面的 Material 组件主题。
///
/// 全局应用使用深色主题；ListTile、Switch、Slider、Dropdown 等组件不会
/// 继承 [DefaultTextStyle] 的墨色，因此凡坐在浅宣纸上的 Material 组件都应
/// 通过此主题取得稳定的前景色、禁用态和交互态。
ThemeData paperSurfaceTheme(ThemeData baseTheme) {
  final colorScheme = baseTheme.colorScheme.copyWith(
    brightness: Brightness.light,
    primary: WuxiaUi.jiang,
    onPrimary: WuxiaUi.paper,
    secondary: WuxiaUi.qing,
    onSecondary: WuxiaUi.paper,
    surface: WuxiaUi.paper,
    onSurface: WuxiaUi.ink,
    error: const Color(0xFF8B2D25),
    onError: WuxiaUi.paper,
    outline: WuxiaUi.woodDark,
    outlineVariant: WuxiaUi.muted,
  );
  final textTheme = baseTheme.textTheme.apply(
    bodyColor: WuxiaUi.ink,
    displayColor: WuxiaUi.ink,
  );
  final disabledInk = WuxiaUi.muted.withValues(alpha: 0.54);

  return baseTheme.copyWith(
    brightness: Brightness.light,
    colorScheme: colorScheme,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    canvasColor: WuxiaUi.paper,
    cardColor: WuxiaUi.paper2,
    dividerColor: WuxiaUi.ink.withValues(alpha: 0.18),
    disabledColor: disabledInk,
    focusColor: WuxiaUi.jiang.withValues(alpha: 0.14),
    hoverColor: WuxiaUi.ink.withValues(alpha: 0.06),
    highlightColor: WuxiaUi.jiang.withValues(alpha: 0.08),
    splashColor: Colors.transparent,
    iconTheme: const IconThemeData(color: WuxiaUi.ink2),
    listTileTheme: ListTileThemeData(
      iconColor: WuxiaUi.ink2,
      textColor: WuxiaUi.ink,
      titleTextStyle: textTheme.bodyLarge?.copyWith(
        color: WuxiaUi.ink,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(
        color: WuxiaUi.muted,
        height: 1.35,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: WuxiaUi.ink.withValues(alpha: 0.18),
      thickness: 1,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledInk;
        if (states.contains(WidgetState.selected)) return WuxiaUi.paper;
        return WuxiaUi.paper2;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return WuxiaUi.muted.withValues(alpha: 0.22);
        }
        if (states.contains(WidgetState.selected)) return WuxiaUi.jiang;
        return WuxiaUi.ink.withValues(alpha: 0.24);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return WuxiaUi.jiang.withValues(alpha: 0.86);
        }
        return WuxiaUi.muted.withValues(alpha: 0.58);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledInk;
        if (states.contains(WidgetState.selected)) return WuxiaUi.jiang;
        return Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(WuxiaUi.paper),
      side: const BorderSide(color: WuxiaUi.woodDark, width: 1.4),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledInk;
        if (states.contains(WidgetState.selected)) return WuxiaUi.jiang;
        return WuxiaUi.muted;
      }),
    ),
    sliderTheme: baseTheme.sliderTheme.copyWith(
      activeTrackColor: WuxiaUi.jiang,
      inactiveTrackColor: WuxiaUi.ink.withValues(alpha: 0.20),
      disabledActiveTrackColor: disabledInk,
      disabledInactiveTrackColor: WuxiaUi.muted.withValues(alpha: 0.16),
      thumbColor: WuxiaUi.jiang,
      disabledThumbColor: disabledInk,
      overlayColor: WuxiaUi.jiang.withValues(alpha: 0.12),
      valueIndicatorColor: WuxiaUi.ink,
      valueIndicatorTextStyle: const TextStyle(color: WuxiaUi.paper),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WuxiaUi.paper2.withValues(alpha: 0.42),
      labelStyle: const TextStyle(color: WuxiaUi.ink2),
      floatingLabelStyle: const TextStyle(color: WuxiaUi.jiang),
      helperStyle: const TextStyle(color: WuxiaUi.ink2),
      hintStyle: const TextStyle(color: WuxiaUi.muted),
      prefixStyle: const TextStyle(color: WuxiaUi.ink),
      suffixStyle: const TextStyle(color: WuxiaUi.ink),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: WuxiaUi.woodDark),
        borderRadius: BorderRadius.circular(4),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: WuxiaUi.jiang, width: 1.6),
        borderRadius: BorderRadius.circular(4),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: disabledInk),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: textTheme.bodyMedium?.copyWith(color: WuxiaUi.ink),
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(WuxiaUi.paper),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide(color: WuxiaUi.woodDark)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: WuxiaUi.paper,
      surfaceTintColor: Colors.transparent,
      textStyle: textTheme.bodyMedium?.copyWith(color: WuxiaUi.ink),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(WuxiaUi.paper),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: WuxiaUi.ink,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: WuxiaUi.woodLight),
      ),
      textStyle: const TextStyle(color: WuxiaUi.paper),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: WuxiaUi.jiang,
      selectionColor: WuxiaUi.jiang.withValues(alpha: 0.22),
      selectionHandleColor: WuxiaUi.jiang,
    ),
  );
}
