import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/slot_summary.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/features/save_slot/application/save_slot_startup_service.dart';

import '../support/isar_test_support.dart';
import '../support/test_data.dart';

void main() {
  late Directory directory;
  final probes = <({Isar instance, String directory})>[];
  void captureProbe(Isar isar) {
    if (isar.name.startsWith('wuxia_slot_probe_')) {
      probes.add((instance: isar, directory: isar.directory!));
    }
  }

  File slotFile(int slot) =>
      File('${directory.path}/wuxia_save_slot$slot.isar');

  Future<void> seed(int slot, {String? version}) async {
    await IsarSetup.init(slotId: slot, directory: directory, inspector: false);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.currentSaveData())!
        ..slotName = 'preserved-$slot'
        ..totalPassiveExperience = 9876;
      if (version != null) save.saveVersion = version;
      await IsarSetup.instance.saveDatas.put(save);
    });
    await IsarSetup.close();
  }

  void expectReleased() {
    expect(IsarSetup.instanceOrNull, isNull);
    expect(Isar.instanceNames, isEmpty);
    for (var slot = 1; slot <= 3; slot++) {
      expect(Isar.getInstance('wuxia_save_slot$slot'), isNull);
    }
  }

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('wuxia_slot_fault_');
    probes.clear();
    Isar.addOpenListener(captureProbe);
  });
  tearDown(() async {
    Isar.removeOpenListener(captureProbe);
    for (final probe in probes) {
      expect(
        probe.instance.isOpen,
        isFalse,
        reason: 'Probe handle must be released',
      );
      expect(
        await Directory(probe.directory).exists(),
        isFalse,
        reason: 'Probe copy and lock directory must be removed',
      );
    }
    for (var slot = 1; slot <= 3; slot++) {
      await Isar.getInstance('wuxia_save_slot$slot')?.close();
    }
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  test('damaged file does not block healthy and absent slots', () async {
    await seed(1);
    await seed(2);
    final damaged = List<int>.filled(16384, 0x78);
    await slotFile(1).writeAsBytes(damaged);
    for (var attempt = 0; attempt < 2; attempt++) {
      final slots = await IsarSetup.listSlots(directory: directory);
      expect(slots, hasLength(3));
      expect(slots[0].isEmpty, isFalse, reason: 'Unreadable is not empty');
      expect(slots[0].isAvailable, isFalse);
      expect(slots[0].readError, isA<UnreadableSaveException>());
      expect(slots[0].readStackTrace, isNotNull);
      expect(slots[1].isAvailable, isTrue);
      expect(slots[1].isMostRecent, isTrue);
      expect(slots[1].slotName, 'preserved-2');
      expect(slots[2].isEmpty, isTrue);
      expect(await slotFile(1).readAsBytes(), damaged);
      expectReleased();
    }
  });

  test(
    'future version read failure does not block healthy and damaged slots',
    () async {
      await seed(1, version: '0.99.0');
      await seed(3);
      await slotFile(2).writeAsBytes(List<int>.filled(16384, 0x78));
      final futureBefore = await slotFile(1).readAsBytes();
      for (var attempt = 0; attempt < 2; attempt++) {
        final slots = await IsarSetup.listSlots(directory: directory);
        expect(slots, hasLength(3));
        expect(slots[0].isEmpty, isFalse);
        expect(slots[1].isEmpty, isFalse);
        expect(slots[0].readError, isA<UnsupportedSaveVersionException>());
        expect(slots[1].readError, isA<UnreadableSaveException>());
        expect(slots[2].isAvailable, isTrue);
        expect(slots[2].slotName, 'preserved-3');
        expect(await slotFile(1).readAsBytes(), futureBefore);
        expectReleased();
      }
      await SaveSlotStartupService.openSlot(3, directory: directory);
      expect((await IsarSetup.currentSaveData())!.slotName, 'preserved-3');
    },
  );

  test(
    'zero-byte existing file must not become a new empty database',
    () async {
      await slotFile(1).writeAsBytes([]);
      final slots = await IsarSetup.listSlots(directory: directory);
      expect(
        slots[0].isEmpty,
        isFalse,
        reason: 'Truncated file is not an absent slot',
      );
      expect(await slotFile(1).length(), 0);
      await expectLater(
        SaveSlotStartupService.openSlot(1, directory: directory),
        throwsA(isA<Exception>()),
      );
      expect(await slotFile(1).length(), 0);
      expectReleased();
    },
  );

  test(
    'startup rejects future save, releases its handle and healthy slot reopens',
    () async {
      await seed(1, version: '0.99.0');
      await seed(2);
      final futureBefore = await slotFile(1).readAsBytes();
      for (var attempt = 0; attempt < 2; attempt++) {
        await expectLater(
          SaveSlotStartupService.openSlot(1, directory: directory),
          throwsA(isA<UnsupportedSaveVersionException>()),
        );
        expectReleased();
        expect(await slotFile(1).readAsBytes(), futureBefore);
      }
      await SaveSlotStartupService.openSlot(2, directory: directory);
      expect((await IsarSetup.currentSaveData())!.slotName, 'preserved-2');
      expect((await IsarSetup.currentSaveData())!.totalPassiveExperience, 9876);
    },
  );
  test(
    'direct startup, existence and rename reject damage without changing bytes',
    () async {
      await seed(1);
      final damaged = List<int>.filled(16384, 0x78);
      await slotFile(1).writeAsBytes(damaged);
      for (final operation in [
        () => SaveSlotStartupService.openSlot(1, directory: directory),
        () => IsarSetup.slotHasSave(1, directory: directory),
        () => IsarSetup.renameSlot(1, 'must-not-write', directory: directory),
      ]) {
        await expectLater(operation(), throwsA(isA<UnreadableSaveException>()));
        expect(await slotFile(1).readAsBytes(), damaged);
        expectReleased();
      }
    },
  );

  test('future existence and rename cannot bypass version rejection', () async {
    await seed(1, version: '0.99.0');
    final before = await slotFile(1).readAsBytes();
    await expectLater(
      IsarSetup.slotHasSave(1, directory: directory),
      throwsA(isA<UnsupportedSaveVersionException>()),
    );
    await expectLater(
      IsarSetup.renameSlot(1, 'must-not-write', directory: directory),
      throwsA(isA<UnsupportedSaveVersionException>()),
    );
    expect(await slotFile(1).readAsBytes(), before);
    expectReleased();
  });

  test(
    'active healthy handle survives repeated mixed-slot reads and failure recovery',
    () async {
      await seed(1);
      await seed(2, version: '0.99.0');
      final recoverable = await slotFile(2).readAsBytes();
      await SaveSlotStartupService.openSlot(1, directory: directory);
      final active = IsarSetup.instance;
      for (var attempt = 0; attempt < 2; attempt++) {
        final slots = await IsarSetup.listSlots(directory: directory);
        expect(slots[0].isAvailable, isTrue);
        expect(slots[1].isAvailable, isFalse);
        expect(slots[2].isEmpty, isTrue);
        expect(identical(active, IsarSetup.instance), isTrue);
        expect(active.isOpen, isTrue);
        expect(Isar.instanceNames, {'wuxia_save_slot1'});
      }
      await slotFile(2).writeAsBytes(List<int>.filled(16384, 0x78));
      var slots = await IsarSetup.listSlots(directory: directory);
      expect(slots[1].readError, isA<UnreadableSaveException>());
      // Simulates external restoration only in this test-owned directory.
      await slotFile(2).writeAsBytes(recoverable);
      slots = await IsarSetup.listSlots(directory: directory);
      expect(slots[1].readError, isA<UnsupportedSaveVersionException>());
      expect(await slotFile(2).readAsBytes(), recoverable);
      expect(identical(active, IsarSetup.instance), isTrue);
    },
  );

  test(
    'uncreated slot and valid unfinished database remain empty and can start',
    () async {
      await IsarSetup.init(slotId: 2, directory: directory, inspector: false);
      await IsarSetup.close();
      final before = await slotFile(2).readAsBytes();
      final slots = await IsarSetup.listSlots(directory: directory);
      expect(slots.every((slot) => slot.isAvailable && slot.isEmpty), isTrue);
      expect(await slotFile(2).readAsBytes(), before);
      expect(await slotFile(1).exists(), isFalse);
      expect(await slotFile(3).exists(), isFalse);
      await SaveSlotStartupService.openSlot(2, directory: directory);
      expect(
        (await IsarSetup.currentSaveData())!.saveVersion,
        IsarSetup.currentSaveVersion,
      );
    },
  );
}
