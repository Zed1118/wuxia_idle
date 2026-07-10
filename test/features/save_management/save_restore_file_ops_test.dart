import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/save_management/application/save_restore_file_ops.dart';

void main() {
  test('DartIoSaveRestoreFileOps copies renames and deletes files', () async {
    final dir = await Directory.systemTemp.createTemp('wuxia_restore_ops_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final source = File('${dir.path}/source.isar');
    final copied = File('${dir.path}/copied.isar');
    final renamed = File('${dir.path}/renamed.isar');
    await source.writeAsString('save-data');
    const ops = DartIoSaveRestoreFileOps();

    expect(await ops.exists(source.path), isTrue);
    expect(await ops.length(source.path), 9);

    await ops.copy(source.path, copied.path);
    expect(await copied.readAsString(), 'save-data');

    await ops.rename(copied.path, renamed.path);
    expect(await copied.exists(), isFalse);
    expect(await renamed.readAsString(), 'save-data');

    await ops.delete(renamed.path);
    expect(await ops.exists(renamed.path), isFalse);
    await ops.delete(renamed.path);
  });
}
