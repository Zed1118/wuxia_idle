import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/zangjuange/application/zangjuange_providers.dart';
import 'package:wuxia_idle/features/zangjuange/domain/archive_clue.dart';
import 'package:wuxia_idle/features/zangjuange/presentation/zangjuange_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

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

  testWidgets('卷中线索标题使用纸面可读金', (tester) async {
    const clue = ArchiveClue(
      category: ArchiveClueCategory.equipment,
      title: '兵器谱缺口',
      summary: '尚有器物未入谱。',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          zangjuangeCluesProvider.overrideWith((ref) async => [clue]),
        ],
        child: const MaterialApp(home: ZangjuangeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.text(clue.title)).style?.color,
      WuxiaUi.goldOnPaper,
    );
  });
}
