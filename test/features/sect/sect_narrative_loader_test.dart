import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// P3.4 sect_event narrative loader 红线(R4)。
///
/// 校验 `data/lore/sect_event/` 下全部 yaml:
/// - 文件数 ≥ 10(tournament ≥ 5 + mission ≥ 3 + crisis ≥ 2)
/// - schema 合法(id 与文件名一致 / type ∈ {tournament,mission,crisis} /
///             title / opening / choices 非空)
/// - opening 行数 ≤ 6
/// - 黑名单词 0
void main() {
  final sectDir = Directory('data/lore/sect_event');
  final allYamls = sectDir.listSync().whereType<File>().where((f) => f.path.endsWith('.yaml')).toList();
  const validTypes = <String>{'tournament', 'mission', 'crisis'};

  group('R4 sect_event narrative loader', () {
    test('R4.1 sect_event narrative 文件数 ≥ 10(tournament 5 + mission 3 + crisis 2)', () {
      expect(allYamls.length, greaterThanOrEqualTo(10),
          reason: 'sect_event/ 下应至少 10 个 narrative,当前 ${allYamls.length}');
    });

    for (final f in allYamls) {
      final basename = f.uri.pathSegments.last.replaceAll('.yaml', '');
      test('R4.2 [$basename] schema 合法 + opening ≤ 4 行 + choices 非空', () {
        final doc = loadYaml(f.readAsStringSync()) as Map;
        expect(doc['id'], equals(basename), reason: 'id 应与文件名一致');
        final type = doc['type'] as String;
        expect(validTypes.contains(type), isTrue,
            reason: 'type「$type」应 ∈ {tournament,mission,crisis}');
        expect(doc['title'], isA<String>());
        expect((doc['title'] as String).trim().isNotEmpty, isTrue, reason: 'title 非空');
        final opening = doc['opening'] as String;
        expect(opening.trim().isNotEmpty, isTrue, reason: 'opening 非空');
        final lineCount = opening.split('\n').where((l) => l.trim().isNotEmpty).length;
        expect(lineCount, lessThanOrEqualTo(4),
            reason: '$basename opening 行数 $lineCount > 4(简洁古风约束)');
        final choices = doc['choices'];
        expect(choices, isA<List>(), reason: 'choices 应为 list');
        expect((choices as List).isNotEmpty, isTrue, reason: 'choices 非空');
        for (final c in choices) {
          expect((c as Map)['text'], isNotNull, reason: 'choice.text 必填');
          expect(c['outcome'], isNotNull, reason: 'choice.outcome 必填');
        }
      });
    }

    test('R4.3 type 分布(tournament ≥ 5 / mission ≥ 3 / crisis ≥ 2)', () {
      final byType = <String, int>{for (final t in validTypes) t: 0};
      for (final f in allYamls) {
        final doc = loadYaml(f.readAsStringSync()) as Map;
        final type = doc['type'] as String;
        byType[type] = (byType[type] ?? 0) + 1;
      }
      expect(byType['tournament']!, greaterThanOrEqualTo(5),
          reason: 'tournament 应 ≥ 5,当前 ${byType['tournament']}');
      expect(byType['mission']!, greaterThanOrEqualTo(3),
          reason: 'mission 应 ≥ 3,当前 ${byType['mission']}');
      expect(byType['crisis']!, greaterThanOrEqualTo(2),
          reason: 'crisis 应 ≥ 2,当前 ${byType['crisis']}');
    });

    test('R4.4 黑名单词 0', () {
      const blacklist = <String>[
        '霸气', '逆天', '史诗', '神级', '无敌', '最强', '究极',
        '刀光剑影', '血溅', '血雨腥风', 'legendary', 'epic',
      ];
      for (final f in allYamls) {
        final content = f.readAsStringSync();
        for (final w in blacklist) {
          expect(content.contains(w), isFalse, reason: '${f.path} 含黑名单词「$w」');
        }
      }
    });
  });
}
