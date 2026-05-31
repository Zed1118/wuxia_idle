import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/onboarding/application/master_builder.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (p) => File(p).readAsString(),
      );
    }
  });

  test('buildMasterCharacter 透传 MasterDef.portraitPath', () {
    // GameRepository.masters 是 List<MasterDef>,按 slotIndex 0-2 连续唯一(红线保证)
    final founderDef = GameRepository.instance.masters[0]; // slot 0 = 祖师
    final ch = buildMasterCharacter(founderDef, now: DateTime(2026, 5, 31));
    expect(ch.portraitPath, founderDef.portraitPath);
    expect(ch.portraitPath, isNotNull); // masters.yaml founder.png 已配
  });
}
