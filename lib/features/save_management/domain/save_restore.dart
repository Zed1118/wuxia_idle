import 'save_management_status.dart';

enum SaveRestorePhase {
  preflight,
  safetyBackup,
  closeDatabase,
  swapFiles,
  rollbackFiles,
}

class SaveRestoreResult {
  const SaveRestoreResult({
    required this.selectedBackup,
    required this.safetyBackup,
    required this.slotId,
  });

  final SaveBackupInfo selectedBackup;
  final SaveBackupInfo safetyBackup;
  final int slotId;
}

class SaveRestoreException implements Exception {
  const SaveRestoreException({
    required this.phase,
    required this.requiresRestart,
    required this.cause,
  });

  final SaveRestorePhase phase;
  final bool requiresRestart;
  final Object cause;

  @override
  String toString() => 'SaveRestoreException($phase): $cause';
}
