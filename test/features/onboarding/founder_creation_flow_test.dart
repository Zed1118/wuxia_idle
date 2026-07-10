
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/onboarding/domain/founder_creation_selection.dart';
import 'package:wuxia_idle/features/onboarding/presentation/founder_creation_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import '../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
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
}
