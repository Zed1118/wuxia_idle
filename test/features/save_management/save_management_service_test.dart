import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/save_management/application/save_management_service.dart';
import 'package:wuxia_idle/features/save_management/domain/save_management_status.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
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
  });
}
