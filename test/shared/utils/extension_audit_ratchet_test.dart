import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// lib/ extension 声明审计棘轮(K2 · 2026-08-07,仿 math_random_wiring_contract_test 体例)。
///
/// 背景:K1(2026-08-06)附录 A 对 lib/ 全量 15 处 extension 做过人工审计
/// (结论:14 处零硬编码不动 + codex_category.dart:34 step 序数为领域定义维持现状,
/// 详 docs/dispatch/reports/2026-08-06_K1_techdebt.md 附录 A)。但审计是一次性的——
/// 新 extension 悄悄进来不会被任何人再看一眼。本棘轮把「extension 全集 =
/// 已审计 N 处」钉成契约:新增 extension(任何文件,含已白名单文件)即红,
/// 强制经过一次人工审计再更新本表白名单。
///
/// 增量:2026-08-11 P11 资质三连 +1(character.dart 出生总点数),15 → 16。
/// 审计结论一律登记进 K1 附录 A 的「增量登记」段,再回来改本表。
///
/// 口径:`extension` 关键字在 Dart 中只出现在声明处(含无名形式
/// `extension on Path` 与 extension type),行首正则覆盖全部形式;
/// 剥注释后扫描,防文档注释里的字样误伤。
void main() {
  /// extension 声明检测:行首(可缩进)extension 关键字。
  /// 覆盖:命名 `extension Foo on Bar` / 无名 `extension on Path`
  /// (projectile_trail.dart:413 实证存在)/ `extension type`。
  final extensionDecl = RegExp(r'^\s*extension\s+', multiLine: true);

  /// 剥掉注释(块注释 + 行注释),只留可执行代码参与扫描。
  String stripComments(String source) {
    final noBlock = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    return noBlock
        .split('\n')
        .map((line) {
          final i = line.indexOf('//');
          return i >= 0 ? line.substring(0, i) : line;
        })
        .join('\n');
  }

  group('K2 · extension 审计棘轮', () {
    test('lib/ extension 声明全集 = K1 附录 A 已审计 16 处(新增即红待审计)', () {
      // K1 附录 A 建表实测 15/15(2026-08-07 派单方重扫零漂移;K2 本会话复扫逐值吻合),
      // 2026-08-11 P11 追加 1 处(character.dart 出生总点数)后为 16。
      // 值 = 该文件内 extension 声明数;新文件出现 extension 或既有文件增减
      // 声明数都会红——红 = 「请先过一遍硬编码/归宿审计再更新本表」。
      const audited = {
        // 2026-08-11 P11 资质三连追加:出生总点数算法 sink。审计结论见 K1 附录 A
        // 增量登记段——刻意不写成类内 getter(isar_community 会把它生成成持久化
        // 属性,实证 Attributes.total → attributes.g.dart PropertySchema id=4)。
        'lib/core/domain/character.dart': 1,
        'lib/core/domain/technique.dart': 1, // Technique 散功(数值走 NumbersConfig)
        'lib/core/domain/equipment.dart':
            1, // Equipment 共鸣/传承(阈值全读 NumbersConfig)
        'lib/core/domain/enums.dart': 1, // LineageRole.isDiscipleRole 纯枚举判定
        'lib/core/domain/skill_unlock_entry.dart': 1, // Map 语义
        'lib/core/domain/skill_usage_entry.dart': 1, // Map 语义
        'lib/core/domain/reward_entry.dart': 1, // quantityOf Map 语义
        'lib/features/encounter/domain/encounter_progress.dart': 3, // Map 语义 ×3
        'lib/features/encounter/application/encounter_service.dart':
            1, // CurrentSlot 别名
        'lib/data/defs/codex_category.dart':
            1, // step 1-8 = GDD §10.1 领域定义(维持现状)
        'lib/features/settings/presentation/settings_panel.dart':
            1, // withFollowing 布局 helper
        'lib/features/battle/presentation/projectile_trail.dart':
            1, // 无名 extension on Path
        'lib/features/shop/presentation/shop_screen.dart':
            2, // 私有枚举 label(文案走 UiStrings)
      };
      const totalAudited = 16; // 15(K1 建表)+ 1(2026-08-11 P11 追加)

      final found = <String, int>{};
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path;
        if (path.endsWith('.g.dart')) continue; // 生成代码
        final count = extensionDecl
            .allMatches(stripComments(entity.readAsStringSync()))
            .length;
        if (count > 0) found[path] = count;
      }

      final foundTotal = found.values.fold<int>(0, (a, b) => a + b);
      expect(
        foundTotal,
        totalAudited,
        reason:
            'lib/ extension 声明总数 $foundTotal ≠ 已审计 $totalAudited;'
            '新增 extension 请先审计(硬编码?有更优归宿?)再更新本棘轮白名单',
      );
      expect(
        found,
        audited,
        reason:
            'extension 分布漂移:对照 K1 附录 A 找出新增/删除/移位项\n'
            '实有: $found',
      );
    });

    test('扫描口径自控:命名/无名/extension type 必命中,注释字样必不命中', () {
      const hits = {
        'extension Foo on Bar {': '命名形式',
        'extension on Path {': '无名形式(projectile_trail 实证)',
        '  extension Indented on int {': '缩进变体',
        'extension type Meters(int) {}': 'extension type',
      };
      for (final e in hits.entries) {
        expect(
          extensionDecl.hasMatch(e.key),
          isTrue,
          reason: '${e.value}: ${e.key}',
        );
      }
      final commented = stripComments('''
// extension on Fake 注释字样不应命中
/* extension on AlsoFake */
final x = 1;
''');
      expect(
        extensionDecl.hasMatch(commented),
        isFalse,
        reason: '注释里的 extension 字样剥注释后不得命中',
      );
    });
  });
}
