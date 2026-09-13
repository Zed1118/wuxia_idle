import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock_receipt.dart';
import 'package:wuxia_idle/features/seclusion/presentation/offline_recap_card.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

// Run only from tester.runAsync: native Isar needs the real event loop.
Future<void> _pumpUntil(
  WidgetTester tester,
  Future<bool> Function() finished,
  String description,
) async {
  final elapsed = Stopwatch()..start();
  while (!await finished()) {
    if (elapsed.elapsed >= const Duration(seconds: 5)) {
      fail('Main menu startup did not finish: $description');
    }
    await tester.pump(const Duration(milliseconds: 16));
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late Directory directory;
  late DateTime start;

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('main_menu_startup_');
    await IsarSetup.init(directory: directory, inspector: false);
    start = DateTime.now().subtract(const Duration(hours: 5, minutes: 30));
    await OnboardingService(
      isar: IsarSetup.instance,
    ).ensureFoundingMasters(now: start.subtract(const Duration(days: 1)));
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.currentSaveData())!
        ..lastOnlineAt = start
        ..passiveLastSettledAt = start
        ..sweepReadinessLastRecoveredAt = start;
      await IsarSetup.instance.saveDatas.put(save);
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    await directory.delete(recursive: true);
  });

  testWidgets('real main menu completes startup and preserves it on reopen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      Future<void> openMenu() => tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: MainMenu())),
      );
      try {
        await openMenu();
        await _pumpUntil(
          tester,
          () async => find.byType(OfflineRecapCard).evaluate().isNotEmpty,
          'passive recap',
        );
        final recap = tester.widget<OfflineRecapCard>(
          find.byType(OfflineRecapCard),
        );
        expect(recap.passiveExperience, 16);
        expect(recap.passiveMojianshi, 1);
        await tester.tap(find.text(UiStrings.passiveRecapDismiss));
        await _pumpUntil(
          tester,
          () async =>
              await IsarSetup.instance.progressiveUnlockReceipts.count() ==
              ProgressiveUnlockId.values.length,
          'all progressive unlock baseline receipts',
        );
        expect(tester.takeException(), isNull);
        final receipts = await IsarSetup.instance.progressiveUnlockReceipts
            .where()
            .findAll();
        final firstTimes = {
          for (final row in receipts) row.receiptKey: row.firstObservedAt,
        };
        await tester.pumpWidget(const SizedBox.shrink());
        await IsarSetup.close();
        await IsarSetup.init(directory: directory, inspector: false);
        final saved = (await IsarSetup.currentSaveData())!;
        expect(saved.totalPassiveExperience, 16);
        expect(saved.totalPassiveMojianshi, 1);
        expect(saved.passiveLastSettledAt!.isAfter(start), isTrue);
        expect(saved.lastOnlineAt, saved.passiveLastSettledAt);
        final experience = (await IsarSetup.instance.characters.get(
          1,
        ))!.experience;
        final stones = (await IsarSetup.instance.inventoryItems.getByDefId(
          'item_mojianshi',
        ))!.quantity;
        final restartRows = await IsarSetup.instance.progressiveUnlockReceipts
            .where()
            .findAll();
        final restartTimes = {
          for (final row in restartRows) row.receiptKey: row.updatedAt,
        };

        await openMenu();
        await _pumpUntil(
          tester,
          () async => (await IsarSetup.currentSaveData())!.passiveLastSettledAt!
              .isAfter(saved.passiveLastSettledAt!),
          'reopened presence settlement',
        );
        await _pumpUntil(tester, () async {
          final rows = await IsarSetup.instance.progressiveUnlockReceipts
              .where()
              .findAll();
          return rows.length == firstTimes.length &&
              rows.every(
                (row) => row.updatedAt.isAfter(restartTimes[row.receiptKey]!),
              );
        }, 'reopened progressive unlock observation');
        expect(find.byType(OfflineRecapCard), findsNothing);
        expect((await IsarSetup.currentSaveData())!.totalPassiveExperience, 16);
        expect(
          (await IsarSetup.instance.characters.get(1))!.experience,
          experience,
        );
        expect(
          (await IsarSetup.instance.inventoryItems.getByDefId(
            'item_mojianshi',
          ))!.quantity,
          stones,
        );
        final reopened = await IsarSetup.instance.progressiveUnlockReceipts
            .where()
            .findAll();
        expect({
          for (final row in reopened) row.receiptKey: row.firstObservedAt,
        }, firstTimes);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });
  });
}
