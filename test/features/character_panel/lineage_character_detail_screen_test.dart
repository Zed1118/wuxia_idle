import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/character_panel/presentation/lineage_character_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
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
      ProviderScope(
        child: MaterialApp(home: LineageCharacterDetailScreen(character: f)),
      ),
    );
    await tester.pumpAndSettle();
    // GameRepository 未加载 → 祖师恩泽段 config-gated 不渲染，断言祖师身份本身。
    expect(find.text('林青崖'), findsOneWidget);
    expect(
      find.text(EnumL10n.lineageRole(LineageRole.founder)),
      findsOneWidget,
    );
  });

  testWidgets('多代祖师纪事按 generationIndex 显「第 N 代掌门」非「开派太祖」', (
    tester,
  ) async {
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
      ProviderScope(
        child: MaterialApp(
          home: LineageCharacterDetailScreen(
            character: f,
            generationIndex: 2,
          ),
        ),
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
      ProviderScope(
        child: MaterialApp(home: LineageCharacterDetailScreen(character: d)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('叶清'), findsOneWidget);
    expect(
      find.text(UiStrings.lineageCharacterDetailFounderBuff),
      findsNothing,
    );
  });

  testWidgets('弟子纪事 GameRepository 未加载时走 year-only 文案', (tester) async {
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
      ProviderScope(
        child: MaterialApp(home: LineageCharacterDetailScreen(character: d)),
      ),
    );
    await tester.pumpAndSettle();
    // GameRepository 未加载 → _resolveJoinStageName 返回 null → year-only 分支。
    expect(
      find.text(UiStrings.lineageCharacterDetailJoinedYearOnly(7)),
      findsOneWidget,
    );
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
      ProviderScope(
        child: MaterialApp(home: LineageCharacterDetailScreen(character: c)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.injuryHeavyLabel), findsOneWidget);
    expect(
      find.text(UiStrings.injuryRecoveryHint(12.0)),
      findsOneWidget,
    );
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
      ProviderScope(
        child: MaterialApp(home: LineageCharacterDetailScreen(character: c)),
      ),
    );
    await tester.pumpAndSettle();
    // 轻伤显带伤标签（含层数）
    expect(find.textContaining(UiStrings.injuryLightLabel), findsOneWidget);
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
      ProviderScope(
        child: MaterialApp(home: LineageCharacterDetailScreen(character: c)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.injuryHeavyLabel), findsNothing);
    expect(find.text(UiStrings.injuryLightLabel), findsNothing);
  });
}
