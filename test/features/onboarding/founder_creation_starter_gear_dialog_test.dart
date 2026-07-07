import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/onboarding/presentation/founder_creation_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  testWidgets('起手装备弹窗逐件展示三件装备', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final school = GameRepository.instance.founderCreation.schools.first;
    final equipmentNames = school.startingEquipmentIds
        .map((id) => GameRepository.instance.equipmentDefs[id]!.name)
        .toList();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showFounderStarterGearDialog(context, school),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      if (find
          .text(UiStrings.founderStarterGearDialogTitle)
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text(UiStrings.founderStarterGearDialogTitle), findsOneWidget);
    expect(find.text(UiStrings.founderStarterGearDialogIntro), findsOneWidget);
    expect(find.text(UiStrings.founderStarterGearEquippedHint), findsOneWidget);
    for (final name in equipmentNames) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text(UiStrings.founderStarterGearConfirm), findsOneWidget);

    await tester.tap(find.text(UiStrings.founderStarterGearConfirm));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
