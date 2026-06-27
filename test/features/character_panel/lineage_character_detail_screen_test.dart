import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/character_panel/presentation/lineage_character_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  testWidgets('祖师态显祖师身份（名号 + 祖师角色）', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final f = Character()
      ..id = 1
      ..name = '林青崖'
      ..realmTier = RealmTier.wuSheng
      ..realmLayer = RealmLayer.dengFeng
      ..lineageRole = LineageRole.founder
      ..isFounder = true
      ..birthInGameYear = 1
      ..attributes = Attributes();
    await tester.pumpWidget(
      _detailHost(LineageCharacterDetailScreen(character: f)),
    );
    await tester.pumpAndSettle();
    expect(find.text('林青崖'), findsOneWidget);
    expect(
      find.text(EnumL10n.lineageRole(LineageRole.founder)),
      findsOneWidget,
    );
  });

  testWidgets('多代祖师纪事按 generationIndex 显「第 N 代掌门」非「开派太祖」', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final f = Character()
      ..id = 4
      ..name = '陆沉舟'
      ..realmTier = RealmTier.wuSheng
      ..realmLayer = RealmLayer.dengFeng
      ..lineageRole = LineageRole.founder
      ..isFounder = true
      ..birthInGameYear = 30
      ..attributes = Attributes();
    await tester.pumpWidget(
      _detailHost(
        LineageCharacterDetailScreen(character: f, generationIndex: 2),
      ),
    );
    await tester.pumpAndSettle();
    // 第 2 代掌门变体显示，太祖（gen 1）变体不显示。
    expect(
      find.text(UiStrings.lineageCharacterDetailFounderGen(2)),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.lineageCharacterDetailFounderGen(1)),
      findsNothing,
    );
  });

  testWidgets('弟子态不显祖师恩泽', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final d = Character()
      ..id = 2
      ..name = '叶清'
      ..realmTier = RealmTier.sanLiu
      ..realmLayer = RealmLayer.ruMen
      ..lineageRole = LineageRole.senior
      ..isFounder = false
      ..birthInGameYear = 5
      ..attributes = Attributes();
    await tester.pumpWidget(
      _detailHost(LineageCharacterDetailScreen(character: d)),
    );
    await tester.pumpAndSettle();
    expect(find.text('叶清'), findsOneWidget);
    expect(
      find.text(UiStrings.lineageCharacterDetailFounderBuff),
      findsNothing,
    );
  });

  testWidgets('弟子纪事至少显示拜入年份', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final d = Character()
      ..id = 3
      ..name = '苏遥'
      ..realmTier = RealmTier.sanLiu
      ..realmLayer = RealmLayer.ruMen
      ..lineageRole = LineageRole.junior
      ..isFounder = false
      ..birthInGameYear = 7
      ..attributes = Attributes();
    await tester.pumpWidget(
      _detailHost(LineageCharacterDetailScreen(character: d)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('江湖 7 年'), findsOneWidget);
  });

  // ── 伤势 chip 测试（Task 9）────────────────────────────────────────────────

  testWidgets('重伤角色显示重伤标签与疗养提示', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = Character()
      ..id = 10
      ..name = '沈风'
      ..realmTier = RealmTier.erLiu
      ..realmLayer = RealmLayer.ruMen
      ..lineageRole = LineageRole.senior
      ..isFounder = false
      ..birthInGameYear = 3
      ..attributes = Attributes()
      ..injuryHoursRemaining = 12.0;
    await tester.pumpWidget(
      _detailHost(LineageCharacterDetailScreen(character: c)),
    );
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.injuryHeavyLabel), findsOneWidget);
    expect(find.text(UiStrings.injuryRecoveryHint(12.0)), findsOneWidget);
  });

  testWidgets('带伤（轻伤）角色显示带伤标签', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = Character()
      ..id = 11
      ..name = '白鸾'
      ..realmTier = RealmTier.sanLiu
      ..realmLayer = RealmLayer.ruMen
      ..lineageRole = LineageRole.junior
      ..isFounder = false
      ..birthInGameYear = 5
      ..attributes = Attributes()
      ..lightInjuryStacks = 3;
    await tester.pumpWidget(
      _detailHost(LineageCharacterDetailScreen(character: c)),
    );
    await tester.pumpAndSettle();
    // 轻伤显带伤标签（含层数）
    expect(find.textContaining(UiStrings.injuryLightLabel), findsOneWidget);
  });

  testWidgets('心魔余毒角色显示来源、影响与闭关清解路径', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = Character()
      ..id = 13
      ..name = '顾澄'
      ..realmTier = RealmTier.wuSheng
      ..realmLayer = RealmLayer.ruMen
      ..lineageRole = LineageRole.founder
      ..isFounder = true
      ..birthInGameYear = 1
      ..attributes = Attributes()
      ..innerDemonResidueHoursRemaining = 5.2;
    final debuff = GameRepository.instance.numbers.innerDemon.residueDebuff;
    await tester.pumpWidget(
      _detailHost(LineageCharacterDetailScreen(character: c)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(UiStrings.lineageCharacterDetailConditionTitle),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.conditionInnerDemonResidueLabel),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.conditionInnerDemonResidueSource),
      findsOneWidget,
    );
    expect(
      find.text(
        UiStrings.conditionInnerDemonResidueEffect(
          battleOutputPenaltyPct: ((1 - debuff.battleOutputMultiplier) * 100)
              .round(),
          internalForceRecoveryPenaltyPct:
              ((1 - debuff.internalForceRecoveryMultiplier) * 100).round(),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.conditionInnerDemonResidueRecovery(5.2)),
      findsOneWidget,
    );
  });

  testWidgets('无伤角色不显示伤势 chip', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = Character()
      ..id = 12
      ..name = '莫云'
      ..realmTier = RealmTier.sanLiu
      ..realmLayer = RealmLayer.ruMen
      ..lineageRole = LineageRole.junior
      ..isFounder = false
      ..birthInGameYear = 4
      ..attributes = Attributes()
      ..lightInjuryStacks = 0
      ..injuryHoursRemaining = 0;
    await tester.pumpWidget(
      _detailHost(LineageCharacterDetailScreen(character: c)),
    );
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.injuryHeavyLabel), findsNothing);
    expect(find.text(UiStrings.injuryLightLabel), findsNothing);
    expect(find.text(UiStrings.conditionInnerDemonResidueLabel), findsNothing);
  });
}

Widget _detailHost(Widget child) {
  return ProviderScope(
    overrides: [allEquipmentsProvider.overrideWith((ref) async => [])],
    child: MaterialApp(home: child),
  );
}
