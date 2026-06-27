import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/zangjuange/presentation/zangjuange_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('藏卷阁 hub renders four archive entries', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ZangjuangeScreen())),
    );

    expect(find.text(UiStrings.zangjuangeTitle), findsOneWidget);
    expect(find.text(UiStrings.mainMenuBattleRecord), findsOneWidget);
    expect(find.text(UiStrings.mainMenuWeaponCodex), findsOneWidget);
    expect(find.text(UiStrings.mainMenuBaike), findsOneWidget);
    expect(find.text(UiStrings.mainMenuSkillLibrary), findsOneWidget);
  });
}
