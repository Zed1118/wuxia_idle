import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/save_management/application/save_management_providers.dart';
import 'package:wuxia_idle/features/save_management/application/save_management_service.dart';
import 'package:wuxia_idle/features/save_management/application/save_restore_file_ops.dart';
import 'package:wuxia_idle/features/save_management/domain/save_management_status.dart';
import 'package:wuxia_idle/features/save_management/domain/save_restore.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  group('SaveManagementService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_save_mgmt_');
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> seedFounder() async {
      await OnboardingService(isar: IsarSetup.instance).ensureFoundingMasters();
    }

    Future<void> writeSlotName(String value) async {
      final save = (await IsarSetup.currentSaveData())!..slotName = value;
      await IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.saveDatas.put(save),
      );
    }

    test(
      'loadStatus exposes current save metadata and empty backup state',
      () async {
        final service = SaveManagementService(isar: IsarSetup.instance);

        final status = await service.loadStatus();

        expect(status.slotId, 1);
        expect(status.saveVersion, IsarSetup.currentSaveVersion);
        expect(status.createdAt, status.lastSavedAt);
        expect(status.lastOnlineAt, status.createdAt);
        expect(status.databasePath, endsWith('wuxia_save_slot1.isar'));
        expect(status.backupDirectoryPath, contains('wuxia_save_backups'));
        expect(status.backupCount, 0);
        expect(status.latestBackup, isNull);
      },
    );

    test(
      'createBackup writes compact Isar snapshot and updates backup list',
      () async {
        final service = SaveManagementService(
          isar: IsarSetup.instance,
          now: () => DateTime(2026, 6, 27, 1, 2, 3),
        );

        final backup = await service.createBackup();
        final file = File(backup.path);

        expect(backup.fileName, 'wuxia_save_slot1_20260627_010203.isar');
        expect(await file.exists(), isTrue);
        expect(backup.sizeBytes, greaterThan(0));

        final status = await service.loadStatus();
        expect(status.backupCount, 1);
        expect(status.latestBackup!.fileName, backup.fileName);
      },
    );

    test('createBackup does not overwrite backup from same second', () async {
      final service = SaveManagementService(
        isar: IsarSetup.instance,
        now: () => DateTime(2026, 6, 27, 1, 2, 3),
      );

      final first = await service.createBackup();
      final second = await service.createBackup();

      expect(first.fileName, 'wuxia_save_slot1_20260627_010203.isar');
      expect(second.fileName, 'wuxia_save_slot1_20260627_010203_1.isar');
      expect(await File(first.path).exists(), isTrue);
      expect(await File(second.path).exists(), isTrue);
      expect((await service.listBackups()).length, 2);
    });

    test('deleteBackup only deletes files inside backup directory', () async {
      final service = SaveManagementService(isar: IsarSetup.instance);
      final backup = await service.createBackup();
      final currentDb = File(IsarSetup.instance.path!);
      expect(await currentDb.exists(), isTrue);

      await service.deleteBackup(backup);

      expect(await File(backup.path).exists(), isFalse);
      expect(await currentDb.exists(), isTrue);

      final outside = File(
        '${tempDir.path}${Platform.pathSeparator}outside.isar',
      );
      await outside.writeAsString('not a backup');
      addTearDown(() async {
        if (await outside.exists()) await outside.delete();
      });

      expect(
        () => service.deleteBackup(
          SaveBackupInfo(
            path: outside.path,
            fileName: 'outside.isar',
            createdAt: DateTime(2026),
            sizeBytes: 12,
          ),
        ),
        throwsArgumentError,
      );
      expect(await outside.exists(), isTrue);
    });

    test('providers expose status and refresh after backup creation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(saveManagementServiceProvider);
      expect(service, isNotNull);

      final initial = await container.read(saveManagementStatusProvider.future);
      expect(initial.backupCount, 0);

      final backup = await service!.createBackup();
      container.invalidate(saveManagementStatusProvider);

      final refreshed = await container.read(
        saveManagementStatusProvider.future,
      );
      expect(refreshed.backupCount, 1);
      expect(refreshed.latestBackup?.fileName, backup.fileName);
      expect(await File(backup.path).exists(), isTrue);
    });

    test('restoreBackup restores A and safety backup restores B', () async {
      await seedFounder();
      final service = SaveManagementService(
        isar: IsarSetup.instance,
        now: () => DateTime(2026, 7, 10, 12),
      );
      await writeSlotName('state-A');
      final selected = await service.createBackup();
      final selectedSize = await File(selected.path).length();
      await writeSlotName('state-B');

      final result = await service.restoreBackup(selected);

      expect(IsarSetup.instanceOrNull, isNull);
      expect(await File(selected.path).exists(), isTrue);
      expect(await File(selected.path).length(), selectedSize);
      expect(await File(result.safetyBackup.path).exists(), isTrue);

      await IsarSetup.init(directory: tempDir, inspector: false);
      expect((await IsarSetup.currentSaveData())!.slotName, 'state-A');

      final safetyService = SaveManagementService(
        isar: IsarSetup.instance,
        now: () => DateTime(2026, 7, 10, 12),
      );
      await safetyService.restoreBackup(result.safetyBackup);
      await IsarSetup.init(directory: tempDir, inspector: false);
      expect((await IsarSetup.currentSaveData())!.slotName, 'state-B');
    });

    test('restoreBackup rejects unsafe files before closing Isar', () async {
      await seedFounder();
      final service = SaveManagementService(isar: IsarSetup.instance);
      await service.backupDirectory.create(recursive: true);

      final outside = File('${tempDir.path}/outside.isar')
        ..writeAsStringSync('outside');
      final wrongSlot = File(
        '${service.backupDirectory.path}/wuxia_save_slot2_20260710_120000.isar',
      )..writeAsStringSync('wrong-slot');
      final empty = File(
        '${service.backupDirectory.path}/wuxia_save_slot1_20260710_120001.isar',
      )..createSync();
      final corrupt = File(
        '${service.backupDirectory.path}/wuxia_save_slot1_20260710_120002.isar',
      )..writeAsStringSync('not-an-isar-database');
      final missing = File(
        '${service.backupDirectory.path}/wuxia_save_slot1_20260710_120003.isar',
      );

      for (final file in [outside, wrongSlot, empty, corrupt, missing]) {
        final stat = await file.exists() ? await file.stat() : null;
        final backup = SaveBackupInfo(
          path: file.path,
          fileName: file.uri.pathSegments.last,
          createdAt: stat?.modified ?? DateTime(2026, 7, 10, 12),
          sizeBytes: stat?.size ?? 0,
        );

        await expectLater(
          service.restoreBackup(backup),
          throwsA(
            isA<SaveRestoreException>()
                .having((e) => e.phase, 'phase', SaveRestorePhase.preflight)
                .having((e) => e.requiresRestart, 'requiresRestart', isFalse),
          ),
          reason: file.path,
        );
        expect(IsarSetup.instanceOrNull, same(service.isar));
      }
    });

    test('swap failure restores rollback and requires restart', () async {
      await seedFounder();
      final initial = SaveManagementService(
        isar: IsarSetup.instance,
        now: () => DateTime(2026, 7, 10, 13),
      );
      await writeSlotName('state-A');
      final selected = await initial.createBackup();
      await writeSlotName('state-B');
      final service = SaveManagementService(
        isar: IsarSetup.instance,
        now: () => DateTime(2026, 7, 10, 13),
        fileOps: _FailingRenameFileOps({3}),
      );

      await expectLater(
        service.restoreBackup(selected),
        throwsA(
          isA<SaveRestoreException>()
              .having((e) => e.phase, 'phase', SaveRestorePhase.swapFiles)
              .having((e) => e.requiresRestart, 'requiresRestart', isTrue),
        ),
      );

      expect(IsarSetup.instanceOrNull, isNull);
      expect(
        await File('${tempDir.path}/wuxia_save_slot1.isar').exists(),
        isTrue,
      );
      await IsarSetup.init(directory: tempDir, inspector: false);
      expect((await IsarSetup.currentSaveData())!.slotName, 'state-B');
    });

    test(
      'rollback rename failure leaves startup-recoverable rollback',
      () async {
        await seedFounder();
        final initial = SaveManagementService(
          isar: IsarSetup.instance,
          now: () => DateTime(2026, 7, 10, 14),
        );
        await writeSlotName('state-A');
        final selected = await initial.createBackup();
        await writeSlotName('state-B');
        final service = SaveManagementService(
          isar: IsarSetup.instance,
          now: () => DateTime(2026, 7, 10, 14),
          fileOps: _FailingRenameFileOps({3, 4}),
        );
        final backupDirectory = service.backupDirectory;

        await expectLater(
          service.restoreBackup(selected),
          throwsA(
            isA<SaveRestoreException>()
                .having((e) => e.phase, 'phase', SaveRestorePhase.rollbackFiles)
                .having((e) => e.requiresRestart, 'requiresRestart', isTrue),
          ),
        );

        expect(
          await File('${tempDir.path}/wuxia_save_slot1.isar').exists(),
          isFalse,
        );
        expect(
          await File(
            '${tempDir.path}/wuxia_save_slot1_restore_rollback.isar',
          ).exists(),
          isTrue,
        );
        final backupFiles = await backupDirectory
            .list()
            .where((entity) => entity is File && entity.path.endsWith('.isar'))
            .toList();
        expect(backupFiles.length, 2);

        await IsarSetup.recoverInterruptedRestoreFiles(tempDir, 1);
        await IsarSetup.init(directory: tempDir, inspector: false);
        expect((await IsarSetup.currentSaveData())!.slotName, 'state-B');
      },
    );
  });
}

class _FailingRenameFileOps implements SaveRestoreFileOps {
  _FailingRenameFileOps(this.failOnRenameCalls);

  final Set<int> failOnRenameCalls;
  final SaveRestoreFileOps _delegate = const DartIoSaveRestoreFileOps();
  int _renameCalls = 0;

  @override
  Future<void> copy(String sourcePath, String targetPath) =>
      _delegate.copy(sourcePath, targetPath);

  @override
  Future<void> delete(String path) => _delegate.delete(path);

  @override
  Future<bool> exists(String path) => _delegate.exists(path);

  @override
  Future<int> length(String path) => _delegate.length(path);

  @override
  Future<void> rename(String sourcePath, String targetPath) {
    _renameCalls++;
    if (failOnRenameCalls.contains(_renameCalls)) {
      throw FileSystemException('injected rename failure', sourcePath);
    }
    return _delegate.rename(sourcePath, targetPath);
  }
}
