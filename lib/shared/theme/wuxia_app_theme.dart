import 'package:flutter/material.dart';

import 'colors.dart';
import 'wuxia_tokens.dart';

ThemeData wuxiaAppTheme() {
  final scheme = const ColorScheme.dark(
    primary: WuxiaColors.resultHighlight,
    onPrimary: WuxiaColors.background,
    secondary: WuxiaColors.internalForce,
    onSecondary: WuxiaColors.textPrimary,
    error: WuxiaColors.danger,
    onError: WuxiaColors.textPrimary,
    surface: WuxiaColors.panel,
    onSurface: WuxiaColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: WuxiaColors.background,
    canvasColor: WuxiaColors.background,
    cardColor: WuxiaColors.panel,
    dividerColor: WuxiaColors.border,
    disabledColor: WuxiaColors.buttonDisabled,
    appBarTheme: const AppBarTheme(
      backgroundColor: WuxiaColors.sidebar,
      foregroundColor: WuxiaColors.textPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: WuxiaColors.panel,
      surfaceTintColor: Colors.transparent,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: WuxiaColors.resultHighlight,
      selectionColor: Color(0x55E8C547),
      selectionHandleColor: WuxiaColors.resultHighlight,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: WuxiaColors.resultHighlight,
      linearTrackColor: WuxiaColors.barTrack,
      circularTrackColor: WuxiaColors.barTrack,
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: WuxiaColors.resultHighlight,
      labelColor: WuxiaColors.resultHighlight,
      unselectedLabelColor: WuxiaColors.textMuted,
      dividerColor: WuxiaColors.border,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: WuxiaColors.inkPanelTop,
      contentTextStyle: const TextStyle(
        color: WuxiaColors.textPrimary,
        fontSize: 14,
        letterSpacing: 1,
        fontWeight: FontWeight.w600,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: WuxiaUi.gold),
      ),
    ),
  );
}
