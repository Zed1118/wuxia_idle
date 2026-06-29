import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/baike/presentation/skill_codex_detail_screen.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('心法招详情显示流派继承、熟练收益和普通用途', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def =
        GameRepository.instance.skillDefs['skill_gangmeng_jichu_basic']!;
    final stage = GameRepository.instance.numbers.skillProficiency.stages
        .firstWhere((s) => s.id == 'shuLian');

    await tester.pumpWidget(
      wrap(SkillCodexDetailScreen(def: def, maxStage: stage)),
    );
    await tester.pump();

    expect(find.text(UiStrings.skillCodexManualSection), findsOneWidget);
    expect(find.text(UiStrings.skillCodexSchool), findsOneWidget);
    expect(
      find.textContaining(
        UiStrings.skillCodexSchoolValue(
          EnumL10n.school(
            GameRepository
                .instance
                .techniqueDefs['tech_gangmeng_jichu']!
                .school,
          ),
          true,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(UiStrings.cangjingProficiencyDamageBonus(12)),
      findsWidgets,
    );
    expect(find.text(UiStrings.skillCodexUseNormal), findsOneWidget);
  });

  testWidgets('破招详情显示可打断蓄力和截断用途', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.skillDefs['skill_po_shi']!;
    final stage = GameRepository.instance.numbers.skillProficiency.stages
        .firstWhere((s) => s.id == 'jingTong');

    await tester.pumpWidget(
      wrap(SkillCodexDetailScreen(def: def, maxStage: stage)),
    );
    await tester.pump();

    expect(find.text(UiStrings.skillCodexInterrupt), findsWidgets);
    expect(find.text(UiStrings.skillCodexInterruptCanBreak), findsOneWidget);
    expect(find.text(UiStrings.skillCodexUseInterrupt), findsOneWidget);
    expect(
      find.textContaining(UiStrings.cangjingProficiencyInterruptPower(15)),
      findsWidgets,
    );
  });
}
