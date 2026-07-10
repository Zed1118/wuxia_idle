import 'dart:io';

import 'package:isar_community/isar.dart';

import '../../../core/domain/save_data.dart';
import '../../../data/isar_restore_paths.dart';
import '../../../data/isar_setup.dart';
import '../domain/save_management_status.dart';
import '../domain/save_restore.dart';
import 'save_restore_file_ops.dart';

class SaveManagementService {
  SaveManagementService({
    required this.isar,
    DateTime Function()? now,
    SaveRestoreFileOps fileOps = const DartIoSaveRestoreFileOps(),
  }) : _now = now ?? DateTime.now,
       _fileOps = fileOps;

  final Isar isar;
  final DateTime Function() _now;
  final SaveRestoreFileOps _fileOps;

  Directory get backupDirectory {
    final dir = isar.directory;
    return Directory('$dir${Platform.pathSeparator}wuxia_save_backups');
  }

  Future<SaveManagementStatus> loadStatus() async {
    final save = await _currentSave();
    return SaveManagementStatus.fromSaveData(
      save: save,
      databasePath: isar.path,
      backupDirectory: backupDirectory,
      backups: await listBackups(),
    );
  }

  Future<List<SaveBackupInfo>> listBackups() async {
    final dir = backupDirectory;
    if (!await dir.exists()) return const [];

    final backups = <SaveBackupInfo>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.isar')) continue;
      final stat = await entity.stat();
      backups.add(
        SaveBackupInfo(
          path: entity.path,
          fileName: _basename(entity.path),
          createdAt: stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }
    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  Future<SaveBackupInfo> createBackup() async {
    final save = await _currentSave();
    final dir = backupDirectory;
    await dir.create(recursive: true);

    final stamp = _timestampForFileName(_now());
    final fileNamePrefix = 'wuxia_save_slot${save.slotId}_$stamp';
    final target = await _firstAvailableBackupFile(dir, fileNamePrefix);
    await isar.copyToFile(target.path);

    final stat = await target.stat();
    return SaveBackupInfo(
      path: target.path,
      fileName: _basename(target.path),
      createdAt: stat.modified,
      sizeBytes: stat.size,
    );
  }

  Future<void> deleteBackup(SaveBackupInfo backup) async {
    final file = File(backup.path);
    final backupDirPath = backupDirectory.absolute.path;
    final parentPath = file.absolute.parent.path;
    if (parentPath != backupDirPath || !file.path.endsWith('.isar')) {
      throw ArgumentError('Refuse to delete file outside backup directory');
    }
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<SaveRestoreResult> restoreBackup(SaveBackupInfo backup) async {
    late final SaveData save;
    late final IsarRestorePaths paths;
    try {
      save = await _currentSave();
      final databasePath = isar.path;
      if (databasePath == null) {
        throw StateError('Current database path missing');
      }
      paths = IsarRestorePaths(File(databasePath).parent, save.slotId);
      await IsarSetup.recoverInterruptedRestoreFiles(
        File(databasePath).parent,
        save.slotId,
      );
      await _validateBackupFile(backup, save.slotId);
      await _fileOps.copy(backup.path, paths.partial.path);
      await _fileOps.rename(paths.partial.path, paths.candidate.path);
      await IsarSetup.validateRestoreCandidate(
        candidatePath: paths.candidate.path,
        expectedSlotId: save.slotId,
      );
    } catch (error) {
      await _cleanupRestoreCopies(
        partialPath: _pathOrNull(() => paths.partial.path),
        candidatePath: _pathOrNull(() => paths.candidate.path),
      );
      throw SaveRestoreException(
        phase: SaveRestorePhase.preflight,
        requiresRestart: false,
        cause: error,
      );
    }

    late final SaveBackupInfo safetyBackup;
    try {
      await IsarSetup.touchOnlineNow(now: _now());
      safetyBackup = await createBackup();
    } catch (error) {
      await _cleanupRestoreCopies(
        partialPath: paths.partial.path,
        candidatePath: paths.candidate.path,
      );
      throw SaveRestoreException(
        phase: SaveRestorePhase.safetyBackup,
        requiresRestart: false,
        cause: error,
      );
    }

    try {
      await IsarSetup.close();
    } catch (error) {
      throw SaveRestoreException(
        phase: SaveRestorePhase.closeDatabase,
        requiresRestart: true,
        cause: error,
      );
    }

    var currentMoved = false;
    try {
      await _fileOps.delete('${paths.current.path}.lock');
      await _fileOps.rename(paths.current.path, paths.rollback.path);
      currentMoved = true;
      await _fileOps.rename(paths.candidate.path, paths.current.path);
    } catch (error) {
      if (currentMoved &&
          !await _fileOps.exists(paths.current.path) &&
          await _fileOps.exists(paths.rollback.path)) {
        try {
          await _fileOps.rename(paths.rollback.path, paths.current.path);
        } catch (rollbackError) {
          throw SaveRestoreException(
            phase: SaveRestorePhase.rollbackFiles,
            requiresRestart: true,
            cause: rollbackError,
          );
        }
      }
      throw SaveRestoreException(
        phase: SaveRestorePhase.swapFiles,
        requiresRestart: true,
        cause: error,
      );
    }

    await _deleteBestEffort(paths.rollback.path);
    await _deleteBestEffort('${paths.rollback.path}.lock');
    return SaveRestoreResult(
      selectedBackup: backup,
      safetyBackup: safetyBackup,
      slotId: save.slotId,
    );
  }

  Future<void> _validateBackupFile(SaveBackupInfo backup, int slotId) async {
    final file = File(backup.path);
    if (file.absolute.parent.path != backupDirectory.absolute.path) {
      throw ArgumentError('Backup is outside the backup directory');
    }
    final expectedName = RegExp(
      '^wuxia_save_slot${slotId}_[0-9]{8}_[0-9]{6}(?:_[0-9]+)?[.]isar\$',
    );
    if (backup.fileName != _basename(file.path) ||
        !expectedName.hasMatch(backup.fileName)) {
      throw ArgumentError('Backup does not belong to current slot');
    }
    if (!await _fileOps.exists(file.path) ||
        await _fileOps.length(file.path) == 0) {
      throw StateError('Backup file is missing or empty');
    }
  }

  Future<void> _cleanupRestoreCopies({
    required String? partialPath,
    required String? candidatePath,
  }) async {
    if (partialPath != null) await _deleteBestEffort(partialPath);
    if (candidatePath != null) await _deleteBestEffort(candidatePath);
  }

  Future<void> _deleteBestEffort(String path) async {
    try {
      await _fileOps.delete(path);
    } catch (_) {
      // Startup recovery clears any restore artifacts left behind.
    }
  }

  static String? _pathOrNull(String Function() read) {
    try {
      return read();
    } catch (_) {
      return null;
    }
  }

  Future<SaveData> _currentSave() async {
    final save = await isar.saveDatas.get(0);
    if (save == null) {
      throw StateError('SaveData missing');
    }
    return save;
  }

  static String _timestampForFileName(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }

  static Future<File> _firstAvailableBackupFile(
    Directory directory,
    String fileNamePrefix,
  ) async {
    for (var i = 0; i < 1000; i++) {
      final suffix = i == 0 ? '' : '_$i';
      final file = File(
        '${directory.path}${Platform.pathSeparator}$fileNamePrefix$suffix.isar',
      );
      if (!await file.exists()) return file;
    }
    throw StateError('Too many backups with same timestamp');
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index < 0 ? normalized : normalized.substring(index + 1);
  }
}
