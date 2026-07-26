import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/wuxia_typography.dart';

void main() {
  test('语义字阶等值收拢既有共享组件尺寸', () {
    expect(WuxiaTypography.pageTitle, 19);
    expect(WuxiaTypography.dialogTitle, 18);
    expect(WuxiaTypography.emptyStateTitle, 17);
    expect(WuxiaTypography.compactTitle, 15);
    expect(WuxiaTypography.sectionTitle, 14);
    expect(WuxiaTypography.body, 13);
    expect(WuxiaTypography.supporting, 12);
    expect(WuxiaTypography.metadata, 11);
  });

  test('标题、正文与状态样式保持既有字重和字距', () {
    final pageTitle = WuxiaTypography.pageTitleStyle(Colors.black);
    final dialogTitle = WuxiaTypography.dialogTitleStyle(Colors.black);
    final sectionTitle = WuxiaTypography.sectionTitleStyle(Colors.black);
    final compactEmpty = WuxiaTypography.emptyTitleStyle(
      Colors.black,
      compact: true,
    );
    final status = WuxiaTypography.statusStyle(Colors.black, dense: false);

    expect(pageTitle.fontWeight, FontWeight.bold);
    expect(pageTitle.letterSpacing, 6);
    expect(dialogTitle.letterSpacing, 4);
    expect(sectionTitle.letterSpacing, 2);
    expect(compactEmpty.fontSize, 15);
    expect(compactEmpty.letterSpacing, 1.2);
    expect(status.fontSize, 12);
    expect(status.height, 1.1);
  });
}
