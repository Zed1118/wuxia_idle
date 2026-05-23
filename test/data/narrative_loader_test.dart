import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';

/// T36 NarrativeLoader 单测（纯函数 + 注入式 loader）。
void main() {
  group('NarrativeLoader.load', () {
    test('正常 yaml 解析：id + title + paragraphs 全字段', () async {
      Future<String> mockLoader(String path) async {
        expect(path, 'data/narratives/stage_01_01_opening.yaml');
        return '''
id: stage_01_01_opening
title: 山道试剑
paragraphs:
  - 山雾未散，你立于青石之上。
  - 三道身影自林中涌出。
''';
      }
      final c = await NarrativeLoader.load(
        'stage_01_01_opening',
        loader: mockLoader,
      );
      expect(c.id, 'stage_01_01_opening');
      expect(c.title, '山道试剑');
      expect(c.paragraphs.length, 2);
      expect(c.paragraphs[0], '山雾未散，你立于青石之上。');
      expect(c.isPlaceholder, isFalse);
    });

    test('title 缺省 → null', () async {
      Future<String> mockLoader(String path) async => '''
id: x
paragraphs:
  - 单段
''';
      final c = await NarrativeLoader.load('x', loader: mockLoader);
      expect(c.title, isNull);
      expect(c.paragraphs, ['单段']);
      expect(c.isPlaceholder, isFalse);
    });

    test('paragraphs 缺省 → 空列表（仍非占位）', () async {
      Future<String> mockLoader(String path) async => '''
id: empty
title: 空
''';
      final c = await NarrativeLoader.load('empty', loader: mockLoader);
      expect(c.paragraphs, isEmpty);
      expect(c.isPlaceholder, isFalse);
    });

    test('文件不存在 → placeholder（不抛异常）', () async {
      Future<String> mockLoader(String path) async {
        throw Exception('file not found: $path');
      }
      final c = await NarrativeLoader.load('missing', loader: mockLoader);
      expect(c.isPlaceholder, isTrue);
      expect(c.id, 'missing');
      expect(c.paragraphs.length, 1);
      expect(c.paragraphs.first, contains('missing'));
      expect(c.paragraphs.first, contains('剧情待补'));
    });

    test('yaml 损坏 → placeholder（不抛异常）', () async {
      Future<String> mockLoader(String path) async => '{ invalid yaml :::';
      final c = await NarrativeLoader.load('broken', loader: mockLoader);
      expect(c.isPlaceholder, isTrue);
      expect(c.paragraphs.first, contains('broken'));
    });

    test('yaml 顶层非 map → placeholder（不抛异常）', () async {
      Future<String> mockLoader(String path) async => '- 列表顶层';
      final c = await NarrativeLoader.load('top_list', loader: mockLoader);
      expect(c.isPlaceholder, isTrue);
    });

    test('P1 #1 扁平缺失 → stages/ 子目录命中（DeepSeek 拆分体系）', () async {
      final calls = <String>[];
      Future<String> mockLoader(String path) async {
        calls.add(path);
        if (path == 'data/narratives/stage_01_01_opening.yaml') {
          throw Exception('not at flat root');
        }
        if (path == 'data/narratives/stages/stage_01_01_opening.yaml') {
          return '''
id: stage_01_01_opening
title: 山门之外 · 启
paragraphs:
  - 山门已经看不见了。
''';
        }
        throw Exception('unexpected path: $path');
      }

      final c = await NarrativeLoader.load(
        'stage_01_01_opening',
        loader: mockLoader,
      );
      expect(c.id, 'stage_01_01_opening');
      expect(c.title, '山门之外 · 启');
      expect(c.paragraphs.length, 1);
      expect(c.isPlaceholder, isFalse);
      expect(calls, [
        'data/narratives/stage_01_01_opening.yaml',
        'data/narratives/stages/stage_01_01_opening.yaml',
      ], reason: '扫描顺序契约：先扁平后 stages/');
    });

    test('P1 #1 扁平 + stages/ + ascension/ 都不存在 → 各试一次后 placeholder 兜底',
        () async {
      final calls = <String>[];
      Future<String> mockLoader(String path) async {
        calls.add(path);
        throw Exception('not found: $path');
      }

      final c = await NarrativeLoader.load(
        'stage_99_99_opening',
        loader: mockLoader,
      );
      expect(c.isPlaceholder, isTrue);
      // P2.3 加 `data/narratives/ascension/` 后 _scanPaths 长度 3
      // (memory `feedback_red_line_test_semantics`:断言扫描顺序契约非具体数字)。
      expect(calls, [
        'data/narratives/stage_99_99_opening.yaml',
        'data/narratives/stages/stage_99_99_opening.yaml',
        'data/narratives/ascension/stage_99_99_opening.yaml',
      ], reason: '扁平 → stages/ → ascension/ 顺序各试一次');
    });
  });

  group('NarrativeContent.placeholder', () {
    test('placeholder 字段约定：isPlaceholder=true / 单段 / id 出现在文案中', () {
      final c = NarrativeContent.placeholder('test_id');
      expect(c.isPlaceholder, isTrue);
      expect(c.id, 'test_id');
      expect(c.title, isNull);
      expect(c.paragraphs.length, 1);
      expect(c.paragraphs.first, contains('test_id'));
    });

    test('placeholder mandatory 默认 false(占位剧情不强制)', () {
      final c = NarrativeContent.placeholder('test_id');
      expect(c.mandatory, isFalse);
    });
  });

  group('P1 #42 Phase 2 §10 P1.x · mandatory 字段', () {
    test('yaml 无 mandatory 字段 → 默认 false(向后兼容)', () async {
      Future<String> mockLoader(String path) async => '''
id: stage_old
title: 老剧情
paragraphs:
  - 段落
''';
      final c = await NarrativeLoader.load('stage_old', loader: mockLoader);
      expect(c.mandatory, isFalse);
      expect(c.isPlaceholder, isFalse);
    });

    test('yaml mandatory: true → mandatory=true(强制引导)', () async {
      Future<String> mockLoader(String path) async => '''
id: stage_01_01_opening
title: 山道试剑
mandatory: true
paragraphs:
  - 师父说:握剑要紧。
''';
      final c = await NarrativeLoader.load(
        'stage_01_01_opening',
        loader: mockLoader,
      );
      expect(c.mandatory, isTrue);
      expect(c.id, 'stage_01_01_opening');
      expect(c.title, '山道试剑');
    });

    test('yaml mandatory: false 显式 → mandatory=false', () async {
      Future<String> mockLoader(String path) async => '''
id: x
mandatory: false
paragraphs:
  - 一段
''';
      final c = await NarrativeLoader.load('x', loader: mockLoader);
      expect(c.mandatory, isFalse);
    });
  });
}
