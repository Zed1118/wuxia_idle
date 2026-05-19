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

    test('P1 #44 · continued_lore_obtained / continued_lore_boss_defeated 池解析',
        () async {
      Future<String> mockLoader(String path) async => '''
id: weapon_test
name: 测试剑
default_lore:
  - text: |
      preset 段 1。
continued_lore_obtained:
  - text: |
      于「{source}」初见此剑,寒光乍现。
  - text: |
      初遇于{source},剑身犹温。
continued_lore_boss_defeated:
  - text: |
      斩 {boss_name} 于 {stage_name},此剑沾血未崩。
''';
      final c = await LoreLoader.load('weapon_test', loader: mockLoader);
      expect(c.defaultLore.length, 1);
      expect(c.continuedLoreObtainedPool.length, 2);
      expect(c.continuedLoreObtainedPool[0].text,
          '于「{source}」初见此剑,寒光乍现。');
      expect(c.continuedLoreObtainedPool[1].text, '初遇于{source},剑身犹温。');
      expect(c.continuedLoreBossDefeatedPool.length, 1);
      expect(c.continuedLoreBossDefeatedPool[0].text,
          '斩 {boss_name} 于 {stage_name},此剑沾血未崩。');
    });

    test('P1 #44 · continued_lore_* 字段缺省 → 空池(仍非占位)', () async {
      Future<String> mockLoader(String path) async => '''
id: weapon_test
name: 测试剑
default_lore:
  - text: |
      preset 段 1。
''';
      final c = await LoreLoader.load('weapon_test', loader: mockLoader);
      expect(c.continuedLoreObtainedPool, isEmpty);
      expect(c.continuedLoreBossDefeatedPool, isEmpty);
      expect(c.isPlaceholder, isFalse);
    });
  });

  group('LoreContent.placeholder', () {
    test('placeholder 字段约定:isPlaceholder=true / id 透传 / name 空 / 段空', () {
      final c = LoreContent.placeholder('test_id');
      expect(c.isPlaceholder, isTrue);
      expect(c.id, 'test_id');
      expect(c.name, '');
      expect(c.defaultLore, isEmpty);
      expect(c.continuedLoreObtainedPool, isEmpty);
      expect(c.continuedLoreBossDefeatedPool, isEmpty);
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

  group('P1 #44 · 35 件 continued_lore 池红线', () {
    test(
      '5 strict red line:漏件 / 占位符白名单 / 占位符分池 / 长度 / 网游词',
      () async {
        final dir = Directory('data/lore');
        final files = dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.yaml'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
        expect(files.length, 35);

        final placeholderPattern = RegExp(r'\{(\w+)\}');
        const allPlaceholders = {'source', 'boss_name', 'stage_name'};
        const obtainedAllowed = {'source'};
        const bossDefeatedAllowed = {'boss_name', 'stage_name'};
        const gameWords = [
          '传说之', '史诗', '神级', '无敌', '最强', '究极', '霸气', '逆天',
          'legendary', 'epic',
        ];

        for (final f in files) {
          final basename = f.uri.pathSegments.last.replaceAll('.yaml', '');
          final c = await LoreLoader.load(
            basename,
            loader: (p) => File(p).readAsString(),
          );

          expect(c.continuedLoreObtainedPool.length, inInclusiveRange(3, 5),
              reason:
                  '$basename: continued_lore_obtained 池数 ${c.continuedLoreObtainedPool.length} 不在 [3, 5]');
          expect(c.continuedLoreBossDefeatedPool.length, inInclusiveRange(3, 5),
              reason:
                  '$basename: continued_lore_boss_defeated 池数 ${c.continuedLoreBossDefeatedPool.length} 不在 [3, 5]');

          void validatePool(
              List<LoreSegment> pool, String poolName, Set<String> poolAllowed) {
            for (var i = 0; i < pool.length; i++) {
              final text = pool[i].text;
              expect(text.trim().isNotEmpty, isTrue,
                  reason: '$basename / $poolName / 条 $i: text 空白');
              expect(text.length, lessThanOrEqualTo(300),
                  reason: '$basename / $poolName / 条 $i: text 超长 ${text.length} 字');

              for (final m in placeholderPattern.allMatches(text)) {
                final variable = m.group(1)!;
                expect(allPlaceholders.contains(variable), isTrue,
                    reason:
                        '$basename / $poolName / 条 $i: 未约定占位符 {$variable}');
                expect(poolAllowed.contains(variable), isTrue,
                    reason:
                        '$basename / $poolName / 条 $i: 占位符 {$variable} 不属于此池');
              }

              for (final word in gameWords) {
                expect(text.contains(word), isFalse,
                    reason: '$basename / $poolName / 条 $i: 含网游词「$word」');
              }
            }
          }

          validatePool(c.continuedLoreObtainedPool, 'continued_lore_obtained',
              obtainedAllowed);
          validatePool(c.continuedLoreBossDefeatedPool,
              'continued_lore_boss_defeated', bossDefeatedAllowed);
        }
      },
    );

    test(
      'soft · 文风审计(emoji / < 10 字 / 同池重复)— print warning 不 fail',
      () async {
        final dir = Directory('data/lore');
        final files = dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.yaml'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

        final emojiPattern = RegExp(
          r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
          unicode: true,
        );
        final warnings = <String>[];

        for (final f in files) {
          final basename = f.uri.pathSegments.last.replaceAll('.yaml', '');
          final c = await LoreLoader.load(
            basename,
            loader: (p) => File(p).readAsString(),
          );

          void auditPool(List<LoreSegment> pool, String poolName) {
            final seen = <String>{};
            for (var i = 0; i < pool.length; i++) {
              final text = pool[i].text;
              if (emojiPattern.hasMatch(text)) {
                warnings.add('$basename / $poolName / 条 $i: 含 emoji');
              }
              if (text.length < 10) {
                warnings.add(
                    '$basename / $poolName / 条 $i: text 仅 ${text.length} 字 < 10 疑似敷衍');
              }
              if (!seen.add(text)) {
                warnings.add('$basename / $poolName / 条 $i: 同池重复 text');
              }
            }
          }

          auditPool(c.continuedLoreObtainedPool, 'continued_lore_obtained');
          auditPool(
              c.continuedLoreBossDefeatedPool, 'continued_lore_boss_defeated');
        }

        if (warnings.isNotEmpty) {
          // ignore: avoid_print
          print('\n[P1 #44 文风审计 warning] ${warnings.length} 条:');
          for (final w in warnings) {
            // ignore: avoid_print
            print('  - $w');
          }
        }
      },
    );
  });
}
