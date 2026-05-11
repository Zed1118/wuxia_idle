import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';

/// T36 NarrativeLoader 单测（纯函数 + 注入式 loader）。
void main() {
  group('NarrativeLoader.load', () {
    test('正常 yaml 解析：id + title + paragraphs 全字段', () async {
      Future<String> mockLoader(String path) async {
        expect(path, 'data/narratives/mainline_test_01_opening.yaml');
        return '''
id: mainline_test_01_opening
title: 山道试剑
paragraphs:
  - 山雾未散，你立于青石之上。
  - 三道身影自林中涌出。
''';
      }
      final c = await NarrativeLoader.load(
        'mainline_test_01_opening',
        loader: mockLoader,
      );
      expect(c.id, 'mainline_test_01_opening');
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
  });
}
