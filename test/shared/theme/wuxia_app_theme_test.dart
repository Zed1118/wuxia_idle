import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_app_theme.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

void main() {
  test('SnackBar theme uses floating ink panel treatment', () {
    final theme = wuxiaAppTheme().snackBarTheme;

    expect(theme.behavior, SnackBarBehavior.floating);
    expect(theme.backgroundColor, WuxiaColors.inkPanelTop);
    expect(theme.contentTextStyle?.color, WuxiaColors.textPrimary);
    expect(theme.contentTextStyle?.fontWeight, FontWeight.w600);
    expect(theme.elevation, 8);

    final shape = theme.shape;
    expect(shape, isA<RoundedRectangleBorder>());
    final rounded = shape as RoundedRectangleBorder;
    expect(rounded.side.color, WuxiaUi.gold);
  });
}
