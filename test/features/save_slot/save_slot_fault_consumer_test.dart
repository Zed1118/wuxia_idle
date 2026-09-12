import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/features/onboarding/presentation/founder_creation_screen.dart';
import 'package:wuxia_idle/features/save_slot/application/slot_list_provider.dart';
import 'package:wuxia_idle/features/save_slot/presentation/save_select_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/error_fallback.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_button.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  late Directory directory;
  late List<int> unfinishedBytes;
  late ProviderContainer container;

  File slotFile(int slot) =>
      File('${directory.path}/wuxia_save_slot$slot.isar');

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('wuxia_slot_consumer_');
    for (var slot = 1; slot <= 3; slot++) {
      await IsarSetup.init(
        slotId: slot,
        directory: directory,
        inspector: false,
      );
      if (slot != 3) {
        await OnboardingService(
          isar: IsarSetup.instance,
        ).ensureFoundingMasters();
      }
      await IsarSetup.instance.writeTxn(() async {
        final save = (await IsarSetup.currentSaveData())!
          ..slotName = 'healthy-$slot';
        if (slot == 2) save.saveVersion = '0.99.0';
        await IsarSetup.instance.saveDatas.put(save);
      });
      await IsarSetup.close();
    }
    unfinishedBytes = await slotFile(3).readAsBytes();
    await slotFile(3).writeAsBytes(List<int>.filled(16384, 0x78));
    container = ProviderContainer();
    container.listen(slotListProvider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    for (final name in Isar.instanceNames) {
      await Isar.getInstance(name)?.close();
    }
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  Future<void> mount(
    WidgetTester tester,
    Size size, {
    NavigatorObserver? observer,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => container.read(slotListProvider.future));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: const SaveSelectScreen(),
          navigatorObservers: [?observer],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> waitForSlotRefresh(WidgetTester tester) async {
    // Invalidation can start the provider during a fake-time frame. Its Isar
    // reads still need real IO, so keep both clocks moving until it settles.
    for (var attempt = 0; attempt < 500; attempt++) {
      await tester.pump(const Duration(milliseconds: 10));
      final slots = container.read(slotListProvider);
      if (!slots.isLoading) {
        expect(slots.hasError, isFalse);
        expect(slots.hasValue, isTrue);
        return;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    fail('Slot list refresh did not complete while driving frames and IO');
  }

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('real provider isolates mixed failures and retries at $size', (
      tester,
    ) async {
      await mount(tester, size);
      final semantics = tester.ensureSemantics();

      expect(find.text('healthy-1'), findsOneWidget);
      expect(
        find.text(UiStrings.slotUnsupportedVersion('0.99.0')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.slotUnreadable), findsOneWidget);
      expect(find.byType(ErrorFallback), findsNWidgets(2));
      expect(find.text(UiStrings.slotSaveEmpty), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      for (final slot in [2, 3]) {
        final card = find.ancestor(
          of: find.text(UiStrings.slotCardTitle(slot)),
          matching: find.byType(InkWell),
        );
        expect(tester.widget<InkWell>(card).onTap, isNull);
      }
      final healthyCard = find.ancestor(
        of: find.text('healthy-1'),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(healthyCard).onTap, isNotNull);
      final slots = container.read(slotListProvider).requireValue;
      expect(slots[0].isMostRecent, isTrue);
      expect(
        slots.skip(1).every((slot) => !slot.isAvailable && !slot.isEmpty),
        isTrue,
      );
      await tester.runAsync(() async {
        await slotFile(3).writeAsBytes(unfinishedBytes);
      });
      final retry = find
          .widgetWithText(PlaqueButton, UiStrings.errorRetry)
          .last;
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await waitForSlotRefresh(tester);
      await tester.pumpAndSettle();
      expect(find.text(UiStrings.slotUnreadable), findsNothing);
      expect(find.text(UiStrings.slotSaveEmpty), findsOneWidget);
      expect(find.byType(ErrorFallback), findsOneWidget);
      expect(
        container.read(slotListProvider).requireValue[2].isAvailable,
        isTrue,
      );
      expect(Isar.instanceNames, isEmpty);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('startup failure after leaving the screen is safely ignored', (
    tester,
  ) async {
    await mount(tester, const Size(1280, 720));
    await tester.runAsync(() async {
      await slotFile(1).writeAsBytes(List<int>.filled(16384, 0x78));
    });
    final card = find.ancestor(
      of: find.text('healthy-1'),
      matching: find.byType(InkWell),
    );
    final onTap = tester.widget<InkWell>(card).onTap!;
    late Future<void> opening;
    Object? callbackError;
    await tester.runAsync(() async {
      // Keep the real card callback's Future so the assertion observes async
      // failures even when its ConsumerElement has already been disposed.
      opening = ((onTap as dynamic)() as Future<void>).catchError((
        Object error,
      ) {
        callbackError = error;
      });
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => opening);
    expect(callbackError, isNull);
    expect(Isar.instanceNames, isEmpty);
    await tester.runAsync(() async {
      expect(await slotFile(1).readAsBytes(), List<int>.filled(16384, 0x78));
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stale healthy card reports startup failure without onboarding or navigation',
    (tester) async {
      final failureShown = Completer<void>();
      await mount(
        tester,
        const Size(1280, 720),
        observer: _PopupObserver(() {
          if (!failureShown.isCompleted) failureShown.complete();
        }),
      );
      late List<int> futureBytes;
      await tester.runAsync(() async {
        final raw = await Isar.open(
          IsarSetup.schemasForTesting,
          directory: directory.path,
          name: 'wuxia_save_slot1',
          inspector: false,
        );
        await raw.writeTxn(() async {
          final save = (await raw.saveDatas.get(0))!..saveVersion = '0.99.0';
          await raw.saveDatas.put(save);
        });
        await raw.close();
        futureBytes = await slotFile(1).readAsBytes();
      });
      await tester.runAsync(() => tester.tap(find.text('healthy-1')));
      // Navigator observer notifications need frames while the database probe
      // needs the real event loop; drive both instead of awaiting in fake time.
      for (
        var attempt = 0;
        !failureShown.isCompleted && attempt < 500;
        attempt++
      ) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      expect(failureShown.isCompleted, isTrue);
      await tester.pump();
      await waitForSlotRefresh(tester);
      await tester.pumpAndSettle();
      expect(find.text(UiStrings.slotOpenFailed), findsOneWidget);
      expect(find.byType(SaveSelectScreen), findsOneWidget);
      expect(find.byType(FounderCreationScreen), findsNothing);
      expect(Isar.instanceNames, isEmpty);
      await tester.runAsync(() async {
        expect(await slotFile(1).readAsBytes(), futureBytes);
      });
      expect(tester.takeException(), isNull);
    },
  );
}

class _PopupObserver extends NavigatorObserver {
  _PopupObserver(this.onPopup);
  final VoidCallback onPopup;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) onPopup();
  }
}
