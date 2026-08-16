import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phase 0A 纯 Dart 战斗模拟基础的源码契约测。
///
/// 防线来源:`docs/audit/phase0a-production-wiring-audit-2026-08-16.md` §6——
/// 引擎锁纯 Flutter(Flame 不进根应用)、probe 固定数字不直迁、根 lib 与 probe
/// 双向零代码依赖。本契约把三条边界钉成回归:
/// 1. `lib/features/battle/domain/phase0a/` 不得 import dart:ui / Flutter /
///    Flame / probe 包;
/// 2. 符号命名不得回流 `Gameplay*` / `probe*` 前缀;
/// 3. 不得出现数值参数默认值(probe 数值默认值回流的唯一入口形态)。
///
/// 第二批(reducer/输入/事件闭环)扩展:`application/phase0a/` 会话/适配层
/// 同守 1/3 两条,并额外禁止依赖旧 3v3 的 `BattleState` / `BattleAI`
/// (派单禁区:不得复用旧状态机)。
void main() {
  final sourceDir = Directory('lib/features/battle/domain/phase0a');
  final appDir = Directory('lib/features/battle/application/phase0a');

  String stripComments(String source) {
    final noBlock = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    return noBlock
        .split('\n')
        .map((line) {
          final i = line.indexOf('//');
          return i >= 0 ? line.substring(0, i) : line;
        })
        .join('\n');
  }

  List<File> sourceFiles(Directory dir) =>
      dir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  const forbiddenImports = [
    "import 'dart:ui",
    "import 'package:flutter",
    "import 'package:flame",
    'phase0minus_probe',
  ];

  test('phase0a domain 目录存在且非空', () {
    expect(sourceDir.existsSync(), isTrue);
    expect(sourceFiles(sourceDir), isNotEmpty);
  });

  test('不得引入 dart:ui / Flutter / Flame / probe 依赖', () {
    for (final file in sourceFiles(sourceDir)) {
      final code = stripComments(file.readAsStringSync());
      for (final needle in forbiddenImports) {
        expect(
          code.contains(needle),
          isFalse,
          reason: '${file.path} 出现禁用依赖 "$needle"',
        );
      }
    }
  });

  test('符号命名不得回流 Gameplay / probe 前缀', () {
    final probeNaming = RegExp(r'\b(Gameplay|Probe|probe)\w*');
    for (final file in sourceFiles(sourceDir)) {
      final code = stripComments(file.readAsStringSync());
      final hit = probeNaming.firstMatch(code);
      expect(
        hit,
        isNull,
        reason: '${file.path} 出现 Gameplay*/probe* 命名 "${hit?.group(0)}"',
      );
    }
  });

  test('不得出现数值参数默认值', () {
    // 只匹配「名字 = 数字」后紧跟 , ) 或 { 的默认值形态;
    // lookbehind 排除 == / <= / >= / != 与算术赋值。
    final numericDefault = RegExp(
      r'(?<![=<>!+\-*/])=\s*-?\d+(?:\.\d+)?\s*[,){]',
    );
    for (final file in sourceFiles(sourceDir)) {
      final code = stripComments(file.readAsStringSync());
      final hit = numericDefault.firstMatch(code);
      expect(
        hit,
        isNull,
        reason:
            '${file.path} 出现数值默认值 "${hit?.group(0)}"'
            '(数值必须由调用方显式传入)',
      );
    }
  });

  group('application/phase0a 会话与适配层契约', () {
    test('目录存在且非空', () {
      expect(appDir.existsSync(), isTrue);
      expect(sourceFiles(appDir), isNotEmpty);
    });

    test('不得引入 dart:ui / Flutter / Flame / probe 依赖', () {
      for (final file in sourceFiles(appDir)) {
        final code = stripComments(file.readAsStringSync());
        for (final needle in forbiddenImports) {
          expect(
            code.contains(needle),
            isFalse,
            reason: '${file.path} 出现禁用依赖 "$needle"',
          );
        }
      }
    });

    test('不得依赖旧 3v3 的 BattleState / BattleAI', () {
      final legacyBattle = RegExp(r'\b(BattleState|BattleAI)\b');
      for (final file in sourceFiles(appDir)) {
        final code = stripComments(file.readAsStringSync());
        expect(
          code.contains('battle_state.dart'),
          isFalse,
          reason: '${file.path} import 旧 battle_state.dart',
        );
        expect(
          code.contains('battle_ai.dart'),
          isFalse,
          reason: '${file.path} import 旧 battle_ai.dart',
        );
        final hit = legacyBattle.firstMatch(code);
        expect(
          hit,
          isNull,
          reason: '${file.path} 引用旧 3v3 符号 "${hit?.group(0)}"',
        );
      }
    });

    test('不得出现数值参数默认值', () {
      final numericDefault = RegExp(
        r'(?<![=<>!+\-*/])=\s*-?\d+(?:\.\d+)?\s*[,){]',
      );
      for (final file in sourceFiles(appDir)) {
        final code = stripComments(file.readAsStringSync());
        final hit = numericDefault.firstMatch(code);
        expect(
          hit,
          isNull,
          reason:
              '${file.path} 出现数值默认值 "${hit?.group(0)}"'
              '(数值必须由调用方显式传入)',
        );
      }
    });
  });
}
