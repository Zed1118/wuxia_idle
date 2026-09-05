import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_entry_flow.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory directory;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('tower_defeat_refresh_');
    await IsarSetup.init(directory: directory, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  testWidgets(
    'defeat persists once and refreshes the already-visible progress',
    (tester) async {
      WidgetRef? pageRef;
      BuildContext? pageContext;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Start the native database query outside the widget fake-async zone.
      await tester.runAsync(() async {
        container.listen(towerProgressProvider, (_, _) {});
        await container.read(towerProgressProvider.future);
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                pageRef = ref;
                pageContext = context;
                final progress = ref.watch(towerProgressProvider).asData?.value;
                return Text(
                  progress == null
                      ? 'loading'
                      : '${progress.totalAttempts}/${progress.totalDefeats}',
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0/0'), findsOneWidget);

      await tester.runAsync(() async {
        await runTowerFlow(
          context: pageContext!,
          ref: pageRef!,
          floor: GameRepository.instance.getTowerFloor(1),
          participantId: 1,
          // Only the combat result is supplied; use the production Isar recorder
          // and the real cached provider, with no defeat-recorder override.
          phase0aBattleOutcomeForTest: () async =>
              (won: false, surrendered: false, settlement: null),
        );
        final service = TowerProgressService(isar: IsarSetup.instance);
        for (var attempt = 0; attempt < 50; attempt++) {
          final persisted = await service.getOrCreate(
            saveDataId: IsarSetup.currentSlotId,
          );
          if (persisted.totalDefeats == 1) break;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        final persisted = await service.getOrCreate(
          saveDataId: IsarSetup.currentSlotId,
        );
        expect(persisted.totalAttempts, 1);
        expect(persisted.totalDefeats, 1);
        expect(persisted.highestClearedFloor, 0);
        await pageRef!.read(towerProgressProvider.future);
      });
      await tester.pumpAndSettle();
      expect(find.text('1/1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
