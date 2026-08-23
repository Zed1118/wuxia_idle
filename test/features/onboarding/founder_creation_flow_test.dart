import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/onboarding/domain/founder_creation_selection.dart';
import 'package:wuxia_idle/features/onboarding/presentation/founder_creation_screen.dart';
import 'package:wuxia_idle/shared/battle_shared/enum_localizations.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/rarity_tier_badge.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/shared/utils/rng_provider.dart';
import '../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  testWidgets('fate 切换同步更新创建页资质档位与出生点数', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rngProvider.overrideWithValue(_LastIndexRng())],
        child: const MaterialApp(home: FounderCreationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final visibleFates = GameRepository.instance.founderCreation.fatePool
        .where((fate) => find.text(fate.label).evaluate().isNotEmpty)
        .toList();
    expect(visibleFates.length, greaterThanOrEqualTo(2));
    expect(find.byType(RarityTierBadge), findsOneWidget);
    final initialLabel = tester.getSemantics(find.byType(RarityTierBadge)).label;
    expect(initialLabel, contains('资质'));
    expect(initialLabel, contains('出生点数'));
    final initialTotal = int.parse(
      RegExp(r'（(\d+)）').firstMatch(initialLabel)!.group(1)!,
    );
    final changedFate = visibleFates.firstWhere(
      (fate) => fate.attributeProfile.total != initialTotal,
      orElse: () => throw TestFailure(
        '可见命盘候选没有与初始出生点数不同的 fate，无法验证同步接线',
      ),
    );
    final expectedTotal = changedFate.attributeProfile.total;
    final expectedTier = GameRepository.instance.numbers.rarityForTotalPoints(
      expectedTotal,
    );
    await tester.tap(find.text(changedFate.label));
    await tester.pumpAndSettle();
    final changedLabel = tester.getSemantics(find.byType(RarityTierBadge)).label;
    expect(
      changedLabel,
      contains('资质 ${EnumL10n.rarityTier(expectedTier)}（$expectedTotal）'),
    );
    expect(changedLabel, contains('出生点数 $expectedTotal'));
  });

  testWidgets('submit → 开局行装弹窗 → 确认后进入主菜单', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final calls = <String>[];
    late FounderCreationSelection capturedSelection;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: FounderCreationScreen(
            createFoundingMaster: (selection) async {
              calls.add('seed');
              capturedSelection = selection;
              return true;
            },
            showStarterGear: (context, school) async {
              calls.add('dialog:${school.id}');
              await showFounderStarterGearDialog(context, school);
            },
            mainMenuBuilder: (_) {
              calls.add('mainMenu');
              return const MainMenu();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(UiStrings.founderCreateConfirm));
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.founderStarterGearDialogTitle), findsOneWidget);
    expect(find.text(UiStrings.founderStarterGearConfirm), findsOneWidget);
    expect(
      capturedSelection.school,
      GameRepository.instance.founderCreation.schools.first,
    );
    expect(capturedSelection.startMode, FounderStartMode.guided);
    expect(calls, ['seed', 'dialog:${capturedSelection.school.id}']);

    await tester.tap(find.text(UiStrings.founderStarterGearConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MainMenu), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTitle), findsOneWidget);
    expect(calls, [
      'seed',
      'dialog:${capturedSelection.school.id}',
      'mainMenu',
    ]);
  });

  testWidgets('有资格时可选择老江湖开局并随创建选择提交', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late FounderCreationSelection capturedSelection;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: FounderCreationScreen(
            allowQuickStart: true,
            createFoundingMaster: (selection) async {
              capturedSelection = selection;
              return false;
            },
            mainMenuBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.founderCreateGuidedMode), findsOneWidget);
    expect(find.text(UiStrings.founderCreateQuickMode), findsOneWidget);
    await tester.tap(find.text(UiStrings.founderCreateQuickMode));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(UiStrings.founderCreateConfirm));
    await tester.tap(find.text(UiStrings.founderCreateConfirm));
    await tester.pumpAndSettle();

    expect(capturedSelection.startMode, FounderStartMode.quick);
  });

  testWidgets('无资格时不显示开局方式选择', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FounderCreationScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.founderCreateStartModeSection), findsNothing);
    expect(find.text(UiStrings.founderCreateQuickMode), findsNothing);
  });
}

class _LastIndexRng implements Rng {
  @override
  int nextInt(int max) => max - 1;

  @override
  double nextDouble() => 0;

  @override
  T pick<T>(List<T> list) => list.last;
}
