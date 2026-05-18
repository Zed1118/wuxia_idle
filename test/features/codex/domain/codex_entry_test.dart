import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/codex/domain/codex_category.dart';
import 'package:wuxia_idle/features/codex/domain/codex_entry.dart';
import 'package:wuxia_idle/features/codex/domain/codex_index.dart';

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

  // ── P2 扩段:lore + isMechanic / isLore 派生 ────────────────────────────────
  group('P2 扩段', () {
    test('CodexCategory.lore.step == null(永久可查不 gate)', () {
      expect(CodexCategory.lore.step, isNull);
      expect(CodexCategory.lore.isMechanic, isFalse);
      expect(CodexCategory.lore.isLore, isTrue);
    });

    test('8 档机制 isMechanic == true && isLore == false', () {
      for (final c in CodexCategory.values.where((c) => c != CodexCategory.lore)) {
        expect(c.isMechanic, isTrue, reason: '$c 应 isMechanic');
        expect(c.isLore, isFalse, reason: '$c 不应 isLore');
        expect(c.step, isNotNull, reason: '$c step 不应 null');
      }
    });

    test('CodexIndex.entries 分组数:8 档首批 + 4 A 组 + 7 lore = 19', () {
      final mechanic = CodexIndex.entries.where((e) => e.category.isMechanic);
      final lore = CodexIndex.entries.where((e) => e.category.isLore);
      // 机制总数 = 8 P1.z 首批 + 4 A 组补充阅读 = 12
      expect(mechanic.length, 12);
      // lore 总数 = B 组 7
      expect(lore.length, 7);
      expect(CodexIndex.entries.length, 19);
    });

    test('CodexIndex.entries 每条 id 唯一', () {
      final ids = CodexIndex.entries.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'id 重复登记');
    });

    test('lore 条目 fromMd → step null', () {
      const raw = '# 江湖九流\n\n比境界更民间的叫法是「流」。\n\n学徒不算流。';
      final entry = CodexEntry.fromMd(id: 'jianghu_ranks', raw: raw);
      expect(entry.id, 'jianghu_ranks');
      expect(entry.category, CodexCategory.lore);
      expect(entry.step, isNull);
      expect(entry.category.isLore, isTrue);
    });

    test('A 组补充阅读条目挂相应机制 category(step 派生 1-8)', () {
      // 语义化:不写死 id → step 映射,只校验 isMechanic + step != null
      const aGroupIds = {
        'equipment_tiers',
        'strengthening',
        'weapon_forging',
        'lost_techniques',
      };
      for (final id in aGroupIds) {
        final entry = CodexIndex.byId(id);
        expect(entry, isNotNull, reason: '$id 未登记');
        expect(entry!.category.isMechanic, isTrue, reason: '$id 应挂机制');
        expect(entry.step, isNotNull, reason: '$id step 应非 null');
        expect(entry.step, inInclusiveRange(1, 8));
      }
    });
  });
}
