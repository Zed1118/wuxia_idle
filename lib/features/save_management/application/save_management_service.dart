import 'dart:io';

import 'package:isar_community/isar.dart';

import '../../../core/domain/save_data.dart';
import '../domain/save_management_status.dart';

class SaveManagementService {
  SaveManagementService({required this.isar, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Isar isar;
  final DateTime Function() _now;

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
