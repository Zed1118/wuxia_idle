import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/image_test_helpers.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/features/encounter/presentation/encounter_dialog.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

/// showEncounterOutcomeBanner widget 测试(W15 C-2 收尾)。
///
/// 覆盖 4 个 OutcomeApplied case:
/// - UnlockSkillApplied(已注册 skill) → 显 SkillDef.name 中文招名(非 raw id)
/// - UnlockSkillApplied(未注册 skill) → 降级显 raw skillId
/// - AttributeBonusApplied → 显属性中文标签 + delta
/// - NoneOutcome → 显默念前行文本
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Widget wrap(WidgetBuilder body) {
    return MaterialApp(
      home: Scaffold(body: Builder(builder: body)),
    );
  }

  Finder assetImage(String path) => find.byWidgetPredicate(
    (w) =>
        w is Image &&
        assetNameOf(w.image) == path,
  );

  testWidgets('UnlockSkillApplied 显 SkillDef.name 中文招名', (tester) async {
    await tester.pumpWidget(
      wrap(
        (ctx) => ElevatedButton(
          onPressed: () => showEncounterOutcomeBanner(
            context: ctx,
            applied: const UnlockSkillApplied('skill_encounter_ting_yu_jian'),
          ),
          child: const Text('trigger'),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text(UiStrings.encounterOutcomeSkillTitle), findsOneWidget);
    expect(find.text('领悟新招:听雨剑'), findsOneWidget);
    expect(assetImage(WuxiaUi.ceremonyInsightBamboo), findsOneWidget);
    expect(find.textContaining('skill_encounter_ting_yu_jian'), findsNothing);
  });

  testWidgets('UnlockSkillApplied 未注册 skillId 降级显 raw id', (tester) async {
    await tester.pumpWidget(
      wrap(
        (ctx) => ElevatedButton(
          onPressed: () => showEncounterOutcomeBanner(
            context: ctx,
            applied: const UnlockSkillApplied('skill_encounter_does_not_exist'),
          ),
          child: const Text('trigger'),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text(UiStrings.encounterOutcomeSkillTitle), findsOneWidget);
    expect(find.text('领悟新招:skill_encounter_does_not_exist'), findsOneWidget);
  });

  testWidgets('AttributeBonusApplied 显属性 + delta', (tester) async {
    await tester.pumpWidget(
      wrap(
        (ctx) => ElevatedButton(
          onPressed: () => showEncounterOutcomeBanner(
            context: ctx,
            applied: const AttributeBonusApplied(AttributeKey.enlightenment, 1),
          ),
          child: const Text('trigger'),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text(UiStrings.encounterOutcomeAttributeTitle), findsOneWidget);
    expect(find.text('悟性 +1'), findsOneWidget);
  });

  testWidgets('NoneOutcome 显默念前行', (tester) async {
    await tester.pumpWidget(
      wrap(
        (ctx) => ElevatedButton(
          onPressed: () => showEncounterOutcomeBanner(
            context: ctx,
            applied: const NoneOutcome(),
          ),
          child: const Text('trigger'),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text(UiStrings.encounterOutcomeNoneTitle), findsOneWidget);
    expect(find.text('心中默念,继续前行'), findsOneWidget);
  });
}
