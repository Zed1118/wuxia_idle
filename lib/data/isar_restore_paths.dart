import 'dart:io';

class IsarRestorePaths {
  IsarRestorePaths(Directory directory, int slotId)
    : current = File(_join(directory, 'wuxia_save_slot$slotId.isar')),
      partial = File(
        _join(directory, 'wuxia_save_slot${slotId}_restore.partial'),
      ),
      candidate = File(
        _join(directory, 'wuxia_save_slot${slotId}_restore_candidate.isar'),
      ),
      rollback = File(
        _join(directory, 'wuxia_save_slot${slotId}_restore_rollback.isar'),
      );

  final File current;
  final File partial;
  final File candidate;
  final File rollback;

  static String _join(Directory directory, String fileName) =>
      '${directory.path}${Platform.pathSeparator}$fileName';
}
