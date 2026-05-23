import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';

/// P2.3 §7.1 飞升 narrative 加载验证(spec p2_3_ascension_spec_2026-05-24 §7)
/// + P5+ 多代续灯 narrative(8h overnight F.1 + H.1)。
///
/// 5 yaml(`data/narratives/ascension/`)通过 [NarrativeLoader] 加载:
///   - ascension_intro:仪式横幅(AscensionScreen 真消费)
///   - ascension_complete:gen1 一代飞升完成 narrative(AscensionScreen
///     isLineageContinuation=false 路径)
///   - ascension_pick_hint:择物 hint(UI 暂未接 · 预留)
///   - ascension_disciple_thank:弟子接物(UI 暂未接 · 预留)
///   - ascension_lineage_chant:P5+ gen2+ 多代续灯(AscensionScreen
///     isLineageContinuation=true 路径 · 太祖→师父→我→新弟子叙事弧)
///
/// 语义校验(memory `feedback_red_line_test_semantics`):字数不写死,只测
/// 「能加载」「非空」「非 placeholder」「id/title 字段对齐」。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  group('P2.3 + P5+ 飞升 narrative 加载', () {
    final ids = [
      'ascension_intro',
      'ascension_complete',
      'ascension_pick_hint',
      'ascension_disciple_thank',
      'ascension_lineage_chant',
    ];

    test('4 yaml 全加载 + 非 placeholder + paragraphs 非空 + id 对齐', () async {
      for (final id in ids) {
        final c = await NarrativeLoader.load(id, loader: fileLoader);
        expect(c.isPlaceholder, isFalse,
            reason: '$id 应有真实 narrative,不走 placeholder');
        expect(c.paragraphs, isNotEmpty,
            reason: '$id paragraphs 不应为空');
        expect(c.id, id, reason: 'yaml id 字段必须等于文件名(不含 .yaml)');
        expect(c.title, isNotNull, reason: '$id 应有 title');
      }
    });

    test('ascension_intro 至少 2 段(AscensionScreen 仪式横幅 take(2) 消费)',
        () async {
      final c = await NarrativeLoader.load(
        'ascension_intro',
        loader: fileLoader,
      );
      expect(c.paragraphs.length, greaterThanOrEqualTo(2),
          reason: 'AscensionScreen banner 取 paragraphs.take(2) 显示,'
              '< 2 段时第二行空白');
    });

    test('ascension_complete 至少 3 段(NarrativeReaderScreen 翻页体验)',
        () async {
      final c = await NarrativeLoader.load(
        'ascension_complete',
        loader: fileLoader,
      );
      expect(c.paragraphs.length, greaterThanOrEqualTo(3),
          reason: 'complete narrative 走 NarrativeReaderScreen 翻页 ≥3 段才有'
              '「继续」按钮的仪式感');
    });

    test('ascension_lineage_chant 至少 3 段 + Tier wuSheng 风格梯度词均匀',
        () async {
      final c = await NarrativeLoader.load(
        'ascension_lineage_chant',
        loader: fileLoader,
      );
      expect(c.paragraphs.length, greaterThanOrEqualTo(3),
          reason: 'P5+ 多代续灯 narrative · 太祖→师父→我→新弟子三代弧 ≥3 段');
      // Tier wuSheng 4 风格梯度词应各至少 1 处命中(memory feedback_user_offline_autonomous)
      final fullText = c.paragraphs.join('\n');
      for (final word in const ['湛然', '寂照', '圆融', '化机']) {
        expect(fullText.contains(word), isTrue,
            reason: 'Tier wuSheng 风格词「$word」应在 narrative 中至少出现 1 次(均匀分布)');
      }
    });
  });
}
