import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/codex/domain/codex_category.dart';
import 'package:wuxia_idle/features/codex/domain/codex_entry.dart';

void main() {
  group('CodexEntry.fromMd', () {
    test('单段 md → title 首行 # + 1 paragraph', () {
      const raw = '# 境界\n\n武学一道，自古以来便有「九品」之分。';
      final entry = CodexEntry.fromMd(id: 'realm', raw: raw);
      expect(entry.id, 'realm');
      expect(entry.title, '境界');
      expect(entry.step, 1);
      expect(entry.category, CodexCategory.combat);
      expect(entry.paragraphs.length, 1);
      expect(entry.paragraphs.first, contains('九品'));
    });

    test('多段 md → 空行切段 + 段内单换行保留', () {
      const raw = '# 师徒传承\n\n第一段第一行\n第一段第二行\n\n第二段第一行';
      final entry = CodexEntry.fromMd(id: 'master_disciple', raw: raw);
      expect(entry.title, '师徒传承');
      expect(entry.step, 6);
      expect(entry.category, CodexCategory.lineage);
      expect(entry.paragraphs.length, 2);
      expect(entry.paragraphs[0], '第一段第一行\n第一段第二行');
      expect(entry.paragraphs[1], '第二段第一行');
    });

    test('未在 CodexIndex 登记的 id → StateError', () {
      const raw = '# 不存在\n\n正文';
      expect(
        () => CodexEntry.fromMd(id: 'not_registered', raw: raw),
        throwsA(isA<StateError>()),
      );
    });

    test('缺 # 标题首行 → FormatException', () {
      const raw = '正文段落,无 # 标题';
      expect(
        () => CodexEntry.fromMd(id: 'realm', raw: raw),
        throwsA(isA<FormatException>()),
      );
    });

    test('# 后无 title 文本 → FormatException', () {
      const raw = '# \n\n正文';
      expect(
        () => CodexEntry.fromMd(id: 'realm', raw: raw),
        throwsA(isA<FormatException>()),
      );
    });

    test('# 标题后 body 全空 → FormatException', () {
      const raw = '# 境界\n\n\n   ';
      expect(
        () => CodexEntry.fromMd(id: 'realm', raw: raw),
        throwsA(isA<FormatException>()),
      );
    });

    test('totalChars 字段返回所有 paragraph 字数和', () {
      const raw = '# 境界\n\nabcde\n\nfgh';
      final entry = CodexEntry.fromMd(id: 'realm', raw: raw);
      expect(entry.totalChars, 8);
    });

    test('CodexCategory.step 8 档全映射对齐', () {
      expect(CodexCategory.combat.step, 1);
      expect(CodexCategory.enhancement.step, 2);
      expect(CodexCategory.techniques.step, 3);
      expect(CodexCategory.schoolCounter.step, 4);
      expect(CodexCategory.seclusion.step, 5);
      expect(CodexCategory.lineage.step, 6);
      expect(CodexCategory.encounter.step, 7);
      expect(CodexCategory.advanced.step, 8);
    });
  });
}
