import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phase 0A 表现层源码契约红测。
///
/// 扫描 `lib/features/battle/presentation/phase0a`:
/// - 禁止 legacy 3v3 耦合:旧 `battle_state.dart` import 与
///   `BattleState`/`BattleAI`/`DefaultGroundStrategy`/`BattleScreen`/
///   `CharacterAvatar`/`BattleField`/`BattleBottomBar` 符号;
/// - 禁止 Flame、probe、`yaml_loader`、`GameRepository`;
/// - 禁止非注释中的中文字符串(文案统一走 UiStrings);
/// - 布局/时长/池上限 token 集中在专用 presentation_tokens 文件,
///   其余文件不得写 `const Duration(...)` 字面量。
void main() {
  const phase0aDir = 'lib/features/battle/presentation/phase0a';

  final forbiddenImports = <String>[
    'battle_state.dart',
    'battle_screen.dart',
    'character_avatar.dart',
    'battle_field.dart',
    'battle_bottom_bar.dart',
    'package:flame',
    'visual_fidelity_region_probe',
    'yaml_loader',
    'game_repository',
  ];

  final forbiddenSymbols = <RegExp>[
    RegExp(r'\bBattleState\b'),
    RegExp(r'\bBattleAI\b'),
    RegExp(r'\bDefaultGroundStrategy\b'),
    RegExp(r'\bBattleScreen\b'),
    RegExp(r'\bCharacterAvatar\b'),
    RegExp(r'\bBattleField\b'),
    RegExp(r'\bBattleBottomBar\b'),
  ];

  String stripComments(String source) {
    final withoutBlocks = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    return withoutBlocks
        .split('\n')
        .map((line) {
          final index = line.indexOf('//');
          return index >= 0 ? line.substring(0, index) : line;
        })
        .join('\n');
  }

  group('phase0a 表现层源码契约', () {
    test('目录存在且至少含一个 dart 文件', () {
      final dir = Directory(phase0aDir);
      expect(
        dir.existsSync(),
        isTrue,
        reason: '$phase0aDir 尚未创建(红测:先实现表现层首切片)',
      );
      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty);
    });

    test('存在专用 presentation_tokens 文件集中 token', () {
      final dir = Directory(phase0aDir);
      if (!dir.existsSync()) {
        fail('$phase0aDir 尚未创建(红测:先实现表现层首切片)');
      }
      final tokenFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.dart') &&
                file.uri.pathSegments.last.contains('presentation_tokens'),
          )
          .toList();
      expect(
        tokenFiles,
        hasLength(1),
        reason: '布局/时长/池上限必须集中在唯一 presentation_tokens 文件',
      );
    });

    test('不 import / 不引用禁用依赖与 legacy 3v3 符号', () {
      final dir = Directory(phase0aDir);
      if (!dir.existsSync()) {
        fail('$phase0aDir 尚未创建(红测:先实现表现层首切片)');
      }
      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        for (final forbidden in forbiddenImports) {
          expect(
            source.contains(forbidden),
            isFalse,
            reason: '${file.path} 不得引用 $forbidden',
          );
        }
        for (final symbol in forbiddenSymbols) {
          expect(
            symbol.hasMatch(stripComments(source)),
            isFalse,
            reason: '${file.path} 不得使用 legacy 符号 $symbol',
          );
        }
      }
    });

    test('非注释代码中不得出现中文字符串', () {
      final dir = Directory(phase0aDir);
      if (!dir.existsSync()) {
        fail('$phase0aDir 尚未创建(红测:先实现表现层首切片)');
      }
      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      final chinese = RegExp(r'[一-鿿]');
      for (final file in dartFiles) {
        final code = stripComments(file.readAsStringSync());
        expect(
          chinese.hasMatch(code),
          isFalse,
          reason: '${file.path} 中文文案必须走 UiStrings,不得硬编码',
        );
      }
    });

    test('presentation_tokens 之外不得写 const Duration 字面量', () {
      final dir = Directory(phase0aDir);
      if (!dir.existsSync()) {
        fail('$phase0aDir 尚未创建(红测:先实现表现层首切片)');
      }
      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in dartFiles) {
        if (file.uri.pathSegments.last.contains('presentation_tokens')) {
          continue;
        }
        expect(
          stripComments(file.readAsStringSync()).contains('const Duration('),
          isFalse,
          reason: '${file.path} 时长 token 必须集中在 presentation_tokens',
        );
      }
    });

    test('active VFX 只由父帧 notifier 驱动,反馈层不自建 ticker', () {
      final source = File(
        'lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart',
      ).readAsStringSync();
      expect(source, contains('ValueListenableBuilder<int>'));
      expect(
        RegExp(
          r'class _FeedbackLayerState[\s\S]*?createTicker',
        ).hasMatch(source),
        isFalse,
        reason: 'active VFX 不得拥有第二个 ticker 重复驱动中间帧重绘',
      );
      expect(source, contains('feedbackFrame: _feedbackFrame'));
      expect(
        source,
        contains('if (_heldFeedback.isNotEmpty) _feedbackFrame.value++'),
      );
    });
  });
}
