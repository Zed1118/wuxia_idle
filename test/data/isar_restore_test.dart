import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';

import '../support/isar_test_support.dart';
import '../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_isar_restore_');
  });

  tearDown(() async {
    for (final name in Isar.instanceNames.toList()) {
      await Isar.getInstance(name)?.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  String path(String fileName) =>
      '${tempDir.path}${Platform.pathSeparator}$fileName';

  test(
    'validateRestoreCandidate accepts a valid backup for current slot',
    () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
      final candidate = path('wuxia_save_slot1_restore_candidate.isar');
      await IsarSetup.instance.copyToFile(candidate);

      await expectLater(
        IsarSetup.validateRestoreCandidate(
          candidatePath: candidate,
          expectedSlotId: 1,
        ),
        completes,
      );
    },
  );

  test('validateRestoreCandidate rejects a backup from another slot', () async {
    await IsarSetup.init(slotId: 2, directory: tempDir, inspector: false);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    final candidate = path('wuxia_save_slot1_restore_candidate.isar');
    await IsarSetup.instance.copyToFile(candidate);

    await expectLater(
      IsarSetup.validateRestoreCandidate(
        candidatePath: candidate,
        expectedSlotId: 1,
      ),
      throwsStateError,
    );
  });

  test('validateRestoreCandidate rejects future save versions', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    final save = (await IsarSetup.currentSaveData())!..saveVersion = '9.0.0';
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.saveDatas.put(save),
    );
    final candidate = path('wuxia_save_slot1_restore_candidate.isar');
    await IsarSetup.instance.copyToFile(candidate);

    await expectLater(
      IsarSetup.validateRestoreCandidate(
        candidatePath: candidate,
        expectedSlotId: 1,
      ),
      throwsStateError,
    );
  });

  test('validateRestoreCandidate rejects saves without a founder', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    final candidate = path('wuxia_save_slot1_restore_candidate.isar');
    await IsarSetup.instance.copyToFile(candidate);

    await expectLater(
      IsarSetup.validateRestoreCandidate(
        candidatePath: candidate,
        expectedSlotId: 1,
      ),
      throwsStateError,
    );
  });

  test(
    'interrupted restore prefers rollback when current file is missing',
    () async {
      final candidate = File(path('wuxia_save_slot1_restore_candidate.isar'));
      final rollback = File(path('wuxia_save_slot1_restore_rollback.isar'));
      await candidate.writeAsString('selected-backup');
      await rollback.writeAsString('pre-restore-save');

      await IsarSetup.recoverInterruptedRestoreFiles(tempDir, 1);

      expect(
        await File(path('wuxia_save_slot1.isar')).readAsString(),
        'pre-restore-save',
      );
      expect(await candidate.exists(), isFalse);
      expect(await rollback.exists(), isFalse);
    },
  );

  test(
    'interrupted restore promotes complete candidate without rollback',
    () async {
      final candidate = File(path('wuxia_save_slot1_restore_candidate.isar'));
      await candidate.writeAsString('selected-backup');

      await IsarSetup.recoverInterruptedRestoreFiles(tempDir, 1);

      expect(
        await File(path('wuxia_save_slot1.isar')).readAsString(),
        'selected-backup',
      );
      expect(await candidate.exists(), isFalse);
    },
  );

  test(
    'existing current save wins and stale restore files are removed',
    () async {
      final current = File(path('wuxia_save_slot1.isar'));
      final partial = File(path('wuxia_save_slot1_restore.partial'));
      final candidate = File(path('wuxia_save_slot1_restore_candidate.isar'));
      final rollback = File(path('wuxia_save_slot1_restore_rollback.isar'));
      await current.writeAsString('current-save');
      await partial.writeAsString('partial-copy');
      await candidate.writeAsString('selected-backup');
      await rollback.writeAsString('pre-restore-save');

      await IsarSetup.recoverInterruptedRestoreFiles(tempDir, 1);

      expect(await current.readAsString(), 'current-save');
      expect(await partial.exists(), isFalse);
      expect(await candidate.exists(), isFalse);
      expect(await rollback.exists(), isFalse);
    },
  );
}
