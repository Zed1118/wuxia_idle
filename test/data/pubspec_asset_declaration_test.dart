import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// pubspec asset 声明守卫(2026-07-02 全面审查 P0-1 收口)。
///
/// 背景:Flutter asset 目录声明**不递归**,`data/lore/sect_event/`(10 篇门派
/// 事件文案)与 `data/narratives/` 根扁平层(爬塔 Boss 开场/胜利 ×12 + 收徒
/// 叙事 ×2)曾漏声明,运行期 rootBundle 加载失败被 catch 吞掉 → 玩家只见
/// 兜底/「[剧情待补]」占位,静默丢文案(构建产物复核证实,详
/// `docs/audit/full_project_review_2026-07-02.md` P0-1)。
///
/// 两层守卫:
/// 1. 结构:data/ 下任何**直接**含 .yaml 的目录(路径含 `_archive` 的除外,
///    归档目录有意不打包)都必须在 pubspec `assets:` 逐个声明;
/// 2. 冒烟:曾漏网的两目录全部文件经 rootBundle 真实可加载(端到端证明
///    进了 test asset bundle,而非只看声明文本)。
void main() {
  group('pubspec asset 声明守卫', () {
    test('data/ 下含 yaml 的非 _archive 目录均已声明进 pubspec assets', () {
      final pubspec =
          loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
      final declared = ((pubspec['flutter'] as YamlMap)['assets'] as YamlList)
          .cast<String>()
          .toSet();

      // 收集 data/ 下所有「直接包含 ≥1 个 .yaml」的目录(含 data/ 自身)。
      final dirsWithYaml = <String>{};
      for (final entity in Directory('data').listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.yaml')) {
          dirsWithYaml.add('${entity.parent.path}/');
        }
      }

      final missing = dirsWithYaml
          .where((dir) => !dir.split('/').any((seg) => seg == '_archive'))
          .where((dir) => !declared.contains(dir))
          .toList()
        ..sort();

      expect(
        missing,
        isEmpty,
        reason:
            'Flutter asset 目录声明不递归:以下目录直接含 yaml 但未在 pubspec '
            'assets 声明,运行期 rootBundle 将加载失败并静默走兜底文案。'
            '请在 pubspec.yaml assets 段逐个补上:$missing',
      );
    });
  });

  group('曾漏网目录 rootBundle 冒烟(端到端可加载)', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    /// 逐文件经 rootBundle 加载并解析,证明真进了 asset bundle。
    Future<void> expectAllLoadable(String dir) async {
      final files = Directory(dir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList();
      expect(files, isNotEmpty, reason: '$dir 下应存在 yaml 文件');
      for (final f in files) {
        final content = await rootBundle.loadString(f.path);
        final yaml = loadYaml(content);
        expect(
          yaml,
          isA<Map>(),
          reason: '${f.path} 应可经 rootBundle 加载并解析为 Map',
        );
      }
    }

    testWidgets('data/lore/sect_event/ 全部文案可加载', (tester) async {
      await expectAllLoadable('data/lore/sect_event');
    });

    testWidgets('data/narratives/ 根扁平叙事(tower/lineage)可加载', (
      tester,
    ) async {
      final flatFiles = Directory('data/narratives')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList();
      expect(
        flatFiles,
        isNotEmpty,
        reason: 'data/narratives/ 根应存在扁平 yaml(tower_*/lineage_*)',
      );
      for (final f in flatFiles) {
        final content = await rootBundle.loadString(f.path);
        expect(
          loadYaml(content),
          isA<Map>(),
          reason: '${f.path} 应可经 rootBundle 加载(NarrativeLoader 扁平层)',
        );
      }
    });
  });
}
