import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('路线 C 五个生产消费面不得重新依赖旧 3v3 入口或状态', () {
    const roots = [
      'lib/features/mainline',
      'lib/features/tower',
      'lib/features/sweep',
      'lib/features/expedition',
      'lib/features/boss_gauntlet',
    ];
    const forbiddenImports = [
      'features/battle/application/battle_providers.dart',
      'features/battle/application/legacy_3v3_combatant_adapter.dart',
      'features/battle/application/stage_battle_setup.dart',
      'features/battle/domain/battle_state.dart',
      'features/battle/presentation/battle_screen.dart',
    ];
    final forbiddenGates = RegExp(
      r'\bPhase0a(?:Mainline|Tower|Sweep|Expedition|Gauntlet)Gate\b',
    );

    final violations = <String>[];
    for (final root in roots) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        for (final needle in forbiddenImports) {
          if (source.contains(needle)) {
            violations.add('${entity.path}: forbidden import $needle');
          }
        }
        if (forbiddenGates.hasMatch(source)) {
          violations.add('${entity.path}: obsolete Phase0a gate');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: '生产消费面必须永久单路由 Phase 0A:\n${violations.join('\n')}',
    );
  });
}
