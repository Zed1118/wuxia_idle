import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/data/codex_loader.dart';
import 'package:wuxia_idle/features/codex/domain/codex_index.dart';

void main() {
  // P2 扩段后 CodexIndex.entries = 8 机制 + 4 A 组补充阅读 + 7 lore = 19 条。
  // 语义化引用 entries.length 避免具体数字硬编码(P3+ 扩段后稳定)。
  group('CodexLoader.loadAll', () {
    test('全条 md 提供 → 加载到全条 entry', () async {
      final fakeFs = <String, String>{
        for (final e in CodexIndex.entries)
          'data/narratives/codex/${e.id}.md': '# ${e.id}_title\n\n'
              '占位段落一,字数控制在 50 字以上。占位占位占位占位占位占位。'
              '占位占位占位占位占位占位占位占位占位占位占位占位占位占位。\n\n'
              '占位段落二,字数充足验证 paragraphs 切段语义。',
      };
      final entries = await CodexLoader.loadAll(
        loader: (path) async => fakeFs[path] ?? (throw 'missing $path'),
      );
      expect(entries.length, CodexIndex.entries.length);
      expect(entries.map((e) => e.id).toSet(),
          CodexIndex.entries.map((e) => e.id).toSet());
    });

    test('某机制档 md 缺失 → graceful 跳过,其余加载', () async {
      // 任挑一条机制条目 combat_advanced(档 8)模拟缺失
      const missingId = 'combat_advanced';
      final fakeFs = <String, String>{
        for (final e in CodexIndex.entries.where((e) => e.id != missingId))
          'data/narratives/codex/${e.id}.md': '# title\n\n段落一。\n\n段落二。',
      };
      final entries = await CodexLoader.loadAll(
        loader: (path) async => fakeFs[path] ?? (throw 'missing $path'),
      );
      expect(entries.length, CodexIndex.entries.length - 1);
      expect(entries.any((e) => e.id == missingId), false);
    });

    test('P2:某 lore md 缺失 → graceful 跳过,其余加载', () async {
      // lore 条目缺失也走 graceful(loader 不区分 mechanic / lore)
      const missingId = 'famous_battles';
      final fakeFs = <String, String>{
        for (final e in CodexIndex.entries.where((e) => e.id != missingId))
          'data/narratives/codex/${e.id}.md': '# title\n\n段落一。\n\n段落二。',
      };
      final entries = await CodexLoader.loadAll(
        loader: (path) async => fakeFs[path] ?? (throw 'missing $path'),
      );
      expect(entries.length, CodexIndex.entries.length - 1);
      expect(entries.any((e) => e.id == missingId), false);
    });

    test('全缺失 → 返回空 list 不抛', () async {
      final entries = await CodexLoader.loadAll(
        loader: (path) async => throw 'missing $path',
      );
      expect(entries, isEmpty);
    });

    test('某条 md 解析失败(缺 # 标题)→ 跳过该条不抛', () async {
      final fakeFs = <String, String>{
        'data/narratives/codex/realm.md': '没有标题的正文',
        'data/narratives/codex/retreat.md': '# 闭关\n\n段落一。',
      };
      final entries = await CodexLoader.loadAll(
        loader: (path) async => fakeFs[path] ?? (throw 'missing $path'),
      );
      expect(entries.length, 1);
      expect(entries.first.id, 'retreat');
    });
  });
}
