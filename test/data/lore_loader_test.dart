import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/lore_loader.dart';

/// Phase 4 W15 · LoreLoader 单测 + 35 件 lore yaml 红线。
///
/// 验证:
///   - 注入式 loader 体例(同 NarrativeLoader)
///   - 文件缺失 / yaml 损坏 → placeholder 兜底,不抛
///   - data/lore/ 35 个真实 yaml 全可解析 + id 与文件名一致 + default_lore 非空
void main() {
  group('LoreLoader.load', () {
    test('正常 yaml 解析:id + name + default_lore 全字段', () async {
      Future<String> mockLoader(String path) async {
        expect(path, 'data/lore/weapon_test.yaml');
        return '''
id: weapon_test
name: 测试剑
default_lore:
  - text: |
      第一段典故。
  - text: |
      第二段典故。
''';
      }
      final c = await LoreLoader.load('weapon_test', loader: mockLoader);
      expect(c.id, 'weapon_test');
      expect(c.name, '测试剑');
      expect(c.defaultLore.length, 2);
      expect(c.defaultLore[0].text, '第一段典故。');
      expect(c.defaultLore[1].text, '第二段典故。');
      expect(c.isPlaceholder, isFalse);
    });

    test('default_lore 缺省 → 空列表(仍非占位)', () async {
      Future<String> mockLoader(String path) async => '''
id: x
name: 空段装备
''';
      final c = await LoreLoader.load('x', loader: mockLoader);
      expect(c.defaultLore, isEmpty);
      expect(c.isPlaceholder, isFalse);
    });

    test('文件不存在 → placeholder(不抛异常)', () async {
      Future<String> mockLoader(String path) async {
        throw Exception('file not found: $path');
      }
      final c = await LoreLoader.load('missing', loader: mockLoader);
      expect(c.isPlaceholder, isTrue);
      expect(c.id, 'missing');
      expect(c.name, '');
      expect(c.defaultLore, isEmpty);
    });

    test('yaml 损坏 → placeholder(不抛异常)', () async {
      Future<String> mockLoader(String path) async => '{ invalid yaml :::';
      final c = await LoreLoader.load('broken', loader: mockLoader);
      expect(c.isPlaceholder, isTrue);
    });

    test('yaml 顶层非 map → placeholder(不抛异常)', () async {
      Future<String> mockLoader(String path) async => '- 列表顶层';
      final c = await LoreLoader.load('top_list', loader: mockLoader);
      expect(c.isPlaceholder, isTrue);
    });
  });

  group('LoreContent.placeholder', () {
    test('placeholder 字段约定:isPlaceholder=true / id 透传 / name 空 / 段空', () {
      final c = LoreContent.placeholder('test_id');
      expect(c.isPlaceholder, isTrue);
      expect(c.id, 'test_id');
      expect(c.name, '');
      expect(c.defaultLore, isEmpty);
    });
  });

  group('data/lore/ 35 个真实 yaml 红线', () {
    test('全部解析成功 + 文件名 == yaml.id + default_lore 非空', () async {
      final dir = Directory('data/lore');
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      expect(files.length, 35, reason: 'W15 #35 交付 35 件装备 lore');

      for (final f in files) {
        final basename = f.uri.pathSegments.last.replaceAll('.yaml', '');
        final c = await LoreLoader.load(
          basename,
          loader: (p) => File(p).readAsString(),
        );
        expect(c.isPlaceholder, isFalse, reason: '$basename 加载失败');
        expect(c.id, basename, reason: '$basename yaml.id 与文件名不一致');
        expect(c.name.isNotEmpty, isTrue, reason: '$basename name 字段为空');
        expect(c.defaultLore.isNotEmpty, isTrue,
            reason: '$basename default_lore 段为空');
        for (final seg in c.defaultLore) {
          expect(seg.text.isNotEmpty, isTrue,
              reason: '$basename 有空 text 段');
        }
      }
    });
  });
}
