import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';

/// Batch 2.3 R4:心魔 22 narrative 加载验证。
///
/// 21 stage narrative(7 opening + 7 victory + 7 defeat)通过 NarrativeLoader
/// 加载 → 不命中 placeholder fallback「[剧情待补]」+ paragraphs 非空。
/// chapter_inner_demon.yaml(prologue + epilogue 体例,运行时不 load,纯叙事
/// 设计 doc)仅验文件存在 + 内容非空。
///
/// 语义校验(memory `feedback_red_line_test_semantics`):字数不写死,只测
/// 「能加载」「非空」「非 placeholder」。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  group('Batch 2.3 R4 · 心魔 narrative 加载', () {
    final stageIds = [
      for (var i = 1; i <= 7; i++) 'stage_inner_demon_0$i',
    ];

    test('7 opening 全加载 + 非 placeholder + paragraphs 非空', () async {
      for (final id in stageIds) {
        final c = await NarrativeLoader.load(
          '${id}_opening',
          loader: fileLoader,
        );
        expect(c.isPlaceholder, isFalse,
            reason: '${id}_opening 应有真实 narrative,不走 placeholder');
        expect(c.paragraphs, isNotEmpty,
            reason: '${id}_opening paragraphs 不应为空');
        expect(c.id, '${id}_opening');
        expect(c.title, isNotNull,
            reason: '${id}_opening 应有 title(「心魔·X · 启」体例)');
      }
    });

    test('7 victory 全加载 + 非 placeholder + paragraphs 非空', () async {
      for (final id in stageIds) {
        final c = await NarrativeLoader.load(
          '${id}_victory',
          loader: fileLoader,
        );
        expect(c.isPlaceholder, isFalse,
            reason: '${id}_victory 应有真实 narrative');
        expect(c.paragraphs, isNotEmpty);
        expect(c.title, isNotNull);
      }
    });

    test('7 defeat 全加载 + 非 placeholder + paragraphs 非空', () async {
      for (final id in stageIds) {
        final c = await NarrativeLoader.load(
          '${id}_defeat',
          loader: fileLoader,
        );
        expect(c.isPlaceholder, isFalse,
            reason: '${id}_defeat 应有真实 narrative');
        expect(c.paragraphs, isNotEmpty);
        expect(c.title, isNotNull);
      }
    });

    test('chapter_inner_demon.yaml 文件存在 + 含 prologue 与 epilogue', () async {
      const path = 'data/narratives/chapters/chapter_inner_demon.yaml';
      final f = File(path);
      expect(await f.exists(), isTrue, reason: '$path 应存在');
      final content = await f.readAsString();
      expect(content, contains('id: chapter_inner_demon'));
      expect(content, contains('title:'));
      expect(content, contains('prologue:'),
          reason: 'chapter narrative 体例(参考 chapter_06.yaml)');
      expect(content, contains('epilogue:'));
      expect(content.length, greaterThan(500),
          reason: 'chapter 内容非空,实际 ~720+ 字');
    });
  });
}
