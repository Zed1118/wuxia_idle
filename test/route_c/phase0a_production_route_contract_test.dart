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

  test('引擎中立服务不得反向依赖旧 3v3 状态', () {
    const files = [
      'lib/shared/audio/audio_assets.dart',
      'lib/features/injury/application/injury_service.dart',
      'lib/features/jianghu/application/enmity_battle_modifier.dart',
      'lib/features/inner_demon/application/inner_demon_service.dart',
    ];
    final violations = <String>[];

    for (final path in files) {
      final source = File(path).readAsStringSync();
      if (source.contains('battle/domain/battle_state.dart')) {
        violations.add('$path: imports retired 3v3 state');
      }
      if (source.contains('BattleState') ||
          source.contains('BattleAction') ||
          source.contains('BattleCharacter')) {
        violations.add('$path: mentions retired 3v3 domain types');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: '中立服务必须可独立于旧 3v3 删除:\n${violations.join('\n')}',
    );
  });

  test('全局生产模块只能从 battle 目录导入 Phase 0A', () {
    final forbiddenImport = RegExp(
      r'''^import\s+['"][^'"]*/battle/(?:application|domain|presentation)/(?!phase0a/)''',
      multiLine: true,
    );
    final violations = <String>[];

    for (final root in ['lib/features', 'lib/shared']) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.startsWith('lib/features/battle/') ||
            entity.path.startsWith('lib/features/debug/')) {
          continue;
        }
        final source = entity.readAsStringSync();
        for (final match in forbiddenImport.allMatches(source)) {
          violations.add('${entity.path}: ${match.group(0)}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: '生产模块不得依赖待删旧核:\n${violations.join('\n')}',
    );
  });

  test('Phase 0A 核心测试 fixture 不得借用待删旧核', () {
    const roots = [
      'test/features/battle/application/phase0a',
      'test/features/battle/domain/phase0a',
      'test/features/battle/presentation/phase0a',
    ];
    final forbiddenImport = RegExp(
      r'''^import\s+['"][^'"]*/battle/(?:application|domain|presentation)/(?!phase0a/)''',
      multiLine: true,
    );
    final violations = <String>[];

    for (final root in roots) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        for (final match in forbiddenImport.allMatches(source)) {
          violations.add('${entity.path}: ${match.group(0)}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Phase 0A 测试不得随旧核删除丢失:\n${violations.join('\n')}',
    );
  });

  test('active tools must not launch retired 3v3 visual routes', () {
    final violations = <String>[];
    final retiredRoute = RegExp(
      r'\b(?:battle_tap_live|battle_scene|battle_v2_[a-z0-9_]+)\b',
    );
    for (final entity in Directory('tools').listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!const <String>{
        '.dart',
        '.json',
        '.md',
        '.py',
        '.sh',
        '.ps1',
      }.contains(
        entity.uri.pathSegments.last.contains('.')
            ? '.${entity.uri.pathSegments.last.split('.').last}'
            : '',
      )) {
        continue;
      }
      final source = entity.readAsStringSync();
      if (retiredRoute.hasMatch(source)) {
        violations.add(entity.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: '可执行工具不得再启动已删除的 3v3 route:\n${violations.join('\n')}',
    );
  });
}
