import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production consumers never read the legacy threshold mirror', () async {
    const allowed = <String>{
      'lib/core/domain/character.dart',
      'lib/features/cultivation/application/character_advancement_service.dart',
      'lib/features/debug/application/phase2_seed_service.dart',
      'lib/features/onboarding/application/master_builder.dart',
      'lib/features/recruitment/application/recruitment_service.dart',
      'lib/features/sect/presentation/sect_recruit_handler.dart',
      // U04 transaction-owned 角色创建 sink；与上述 handler 同样
      // 先取 RealmDef，只把权威 experienceToNext 写入兼容镜像。
      'lib/features/sect/application/sect_recruit_transaction_service.dart',
    };

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'),
        );

    for (final file in files) {
      final path = file.path;
      if (allowed.contains(path)) continue;
      final source = await file.readAsString();
      expect(
        source,
        isNot(contains('experienceToNextLayer')),
        reason: '$path must derive the threshold from RealmDef',
      );
    }
  });
}
