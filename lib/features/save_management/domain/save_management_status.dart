import 'dart:io';

import '../../../core/domain/save_data.dart';

class SaveBackupInfo {
  const SaveBackupInfo({
    required this.path,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String path;
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;
}

class SaveManagementStatus {
  const SaveManagementStatus({
    required this.slotId,
    required this.saveVersion,
    required this.createdAt,
    required this.lastSavedAt,
    required this.lastOnlineAt,
    required this.databasePath,
    required this.backupDirectoryPath,
    required this.backups,
  });

  factory SaveManagementStatus.fromSaveData({
    required SaveData save,
    required String? databasePath,
    required Directory backupDirectory,
    required List<SaveBackupInfo> backups,
  }) {
    return SaveManagementStatus(
      slotId: save.slotId,
      saveVersion: save.saveVersion,
      createdAt: save.createdAt,
      lastSavedAt: save.lastSavedAt,
      lastOnlineAt: save.lastOnlineAt,
      databasePath: databasePath,
      backupDirectoryPath: backupDirectory.path,
      backups: backups,
    );
  }

  final int slotId;
  final String saveVersion;
  final DateTime createdAt;
  final DateTime lastSavedAt;
  final DateTime lastOnlineAt;
  final String? databasePath;
  final String backupDirectoryPath;
  final List<SaveBackupInfo> backups;

  int get backupCount => backups.length;
  SaveBackupInfo? get latestBackup => backups.isEmpty ? null : backups.first;
}
