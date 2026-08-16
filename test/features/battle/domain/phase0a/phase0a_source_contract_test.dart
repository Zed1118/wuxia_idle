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
void main() {
  final sourceDir = Directory('lib/features/battle/domain/phase0a');

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

  List<File> sourceFiles() => sourceDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('phase0a domain 目录存在且非空', () {
    expect(sourceDir.existsSync(), isTrue);
    expect(sourceFiles(), isNotEmpty);
  });

  test('不得引入 dart:ui / Flutter / Flame / probe 依赖', () {
    final forbidden = [
      "import 'dart:ui",
      "import 'package:flutter",
      "import 'package:flame",
      'phase0minus_probe',
    ];
    for (final file in sourceFiles()) {
      final code = stripComments(file.readAsStringSync());
      for (final needle in forbidden) {
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
    for (final file in sourceFiles()) {
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
    for (final file in sourceFiles()) {
      final code = stripComments(file.readAsStringSync());
      final hit = numericDefault.firstMatch(code);
      expect(
        hit,
        isNull,
        reason: '${file.path} 出现数值默认值 "${hit?.group(0)}"'
            '(数值必须由调用方显式传入)',
      );
    }
  });
}
