import 'dart:io';

abstract interface class SaveRestoreFileOps {
  Future<void> copy(String sourcePath, String targetPath);

  Future<void> rename(String sourcePath, String targetPath);

  Future<void> delete(String path);

  Future<bool> exists(String path);

  Future<int> length(String path);
}

class DartIoSaveRestoreFileOps implements SaveRestoreFileOps {
  const DartIoSaveRestoreFileOps();

  @override
  Future<void> copy(String sourcePath, String targetPath) async {
    await File(sourcePath).copy(targetPath);
  }

  @override
  Future<void> rename(String sourcePath, String targetPath) async {
    await File(sourcePath).rename(targetPath);
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<int> length(String path) => File(path).length();
}
