import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// P3.3 PVP narrative loader 红线(R4)。
///
/// 校验 `data/lore/pvp/` 下全部 yaml:
/// - 文件数 ≥ 11(初战 + 连胜 2 + 升级 6 阶 + 降段 + 月榜)
/// - schema 合法(id 与文件名一致 / trigger.kind 非空 / title 非空 / opening 非空)
/// - opening 行数 ≤ 6(简洁古风,spec 建议 ≤ 4 行,留 buffer)
/// - 黑名单词 0(霸气 / 逆天 / 史诗 / legendary 等)
void main() {
  final pvpDir = Directory('data/lore/pvp');
  final allYamls = pvpDir.listSync().whereType<File>().where((f) => f.path.endsWith('.yaml')).toList();

  group('R4 PVP narrative loader', () {
    test('R4.1 PVP narrative 文件数 ≥ 11(初战 + 连胜 2 + 升级 6 阶 + 降段 + 月榜)', () {
      expect(allYamls.length, greaterThanOrEqualTo(11),
          reason: 'pvp/ 下应至少 11 个 narrative,当前 ${allYamls.length}');
    });

    for (final f in allYamls) {
      final basename = f.uri.pathSegments.last.replaceAll('.yaml', '');
      test('R4.2 [$basename] schema 合法 + opening ≤ 6 行', () {
        final doc = loadYaml(f.readAsStringSync()) as Map;
        expect(doc['id'], equals(basename), reason: 'id 应与文件名一致');
        expect(doc['trigger'], isNotNull, reason: 'trigger 段必填');
        expect((doc['trigger'] as Map)['kind'], isNotNull, reason: 'trigger.kind 必填');
        expect(doc['title'], isA<String>());
        expect((doc['title'] as String).trim().isNotEmpty, isTrue, reason: 'title 非空');
        final opening = doc['opening'] as String;
        expect(opening.trim().isNotEmpty, isTrue, reason: 'opening 非空');
        final lineCount = opening.split('\n').where((l) => l.trim().isNotEmpty).length;
        expect(lineCount, lessThanOrEqualTo(6),
            reason: '$basename opening 行数 $lineCount > 6(简洁古风约束)');
      });
    }

    test('R4.3 黑名单词 0(霸气 / 逆天 / 史诗 / legendary 等)', () {
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
