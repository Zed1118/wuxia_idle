import 'dart:io';

import '../../../data/isar_setup.dart';

abstract interface class SaveRestoreDatabaseOps {
  Future<void> recoverInterruptedFiles(Directory directory, int slotId);

  Future<void> validateCandidate({
    required String candidatePath,
    required int expectedSlotId,
  });

  Future<void> touchOnlineNow(DateTime now);

  Future<void> closeDatabase();
}

class IsarSaveRestoreDatabaseOps implements SaveRestoreDatabaseOps {
  const IsarSaveRestoreDatabaseOps();

  @override
  Future<void> recoverInterruptedFiles(Directory directory, int slotId) =>
      IsarSetup.recoverInterruptedRestoreFiles(directory, slotId);

  @override
  Future<void> validateCandidate({
    required String candidatePath,
    required int expectedSlotId,
  }) => IsarSetup.validateRestoreCandidate(
    candidatePath: candidatePath,
    expectedSlotId: expectedSlotId,
  );

  @override
  Future<void> touchOnlineNow(DateTime now) =>
      IsarSetup.touchOnlineNow(now: now);

  @override
  Future<void> closeDatabase() => IsarSetup.close();
}
