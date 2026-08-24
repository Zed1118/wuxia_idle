import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import '../../support/test_data.dart';

/// 主线章节剧情完整性守护。
///
/// `NarrativeLoader` 对缺文件会 graceful fallback 成「剧情待补」；这对运行期安全，
/// 但主线属于玩家必经内容，不能把占位兜底交给实玩发现。
void main() {
  late GameRepository repo;
  Future<String> fileLoader(String path) => File(path).readAsString();

  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  test('主线 stage 绑定的 narrative id 全部能加载到真内容', () async {
    final checked = <String>[];
    final manifestScopedIds = <String>[];
    final mainlineStages =
        repo.stageDefs.values
            .where((s) => s.stageType == StageType.mainline)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    for (final stage in mainlineStages) {
      final ids = <String?>[
        stage.narrativeOpeningId,
        stage.narrativeVictoryId,
        stage.narrativeDefeatId,
        if (stage.bossRecruit != null) '${stage.id}_boss_recruit',
        if (stage.bossRecruit != null) '${stage.id}_boss_fail_recover',
      ];
      manifestScopedIds.addAll(
        [
          stage.narrativeOpeningId,
          stage.narrativeVictoryId,
          stage.narrativeDefeatId,
        ].whereType<String>(),
      );

      for (final id in ids.whereType<String>()) {
        final content = await NarrativeLoader.load(id, loader: fileLoader);
        expect(
          content.isPlaceholder,
          isFalse,
          reason: '${stage.id} 引用的 $id 不应走剧情占位兜底',
        );
        expect(content.id, id, reason: '$id 文件内 id 必须自洽');
        expect(content.paragraphs, isNotEmpty, reason: '$id 段落不能为空');
        for (final paragraph in content.paragraphs) {
          expect(
            paragraph,
            isNot(anyOf(contains('剧情待补'), contains('TODO'), contains('占位'))),
            reason: '$id 仍含占位/TODO 文本',
          );
        }
        checked.add(id);
      }
    }

    expect(mainlineStages.length, 105, reason: '当前主线应覆盖 Ch1-21 共 105 关');
    expect(
      manifestScopedIds,
      hasLength(252),
      reason: '冻结合同为 105 opening + 105 victory + 42 defeat',
    );
    expect(
      manifestScopedIds.toSet(),
      hasLength(252),
      reason: '主线三类旧叙事 ID 不得跨关或跨类型复用',
    );
    expect(
      checked.length,
      greaterThanOrEqualTo(190),
      reason: '至少覆盖 95 关开场/胜利(95×2) + Boss 战败/招降扩展文本',
    );
  });

  test('252 个主线 source 在 NarrativeLoader 三目录物理唯一且无孤儿', () {
    final sourceIds = repo.stageDefs.values
        .where((stage) => stage.stageType == StageType.mainline)
        .expand(
          (stage) => [
            stage.narrativeOpeningId,
            stage.narrativeVictoryId,
            stage.narrativeDefeatId,
          ].whereType<String>(),
        )
        .toSet();
    final stageNarrativePattern = RegExp(
      r'^stage_\d{2}_\d{2}_(opening|victory|defeat)$',
    );
    final pathsById = <String, List<String>>{};

    for (final root in const [
      'data/narratives',
      'data/narratives/stages',
      'data/narratives/ascension',
    ]) {
      final files = Directory(root)
          .listSync(followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.yaml'));
      for (final file in files) {
        final fileName = file.uri.pathSegments.last;
        final stem = fileName.substring(0, fileName.length - '.yaml'.length);
        if (!stageNarrativePattern.hasMatch(stem)) continue;
        final yaml = parseYamlMap(file.readAsStringSync());
        expect(
          yaml['id'],
          stem,
          reason: '${file.path} file stem and YAML id must agree',
        );
        pathsById.putIfAbsent(stem, () => []).add(file.path);
      }
    }

    expect(sourceIds, hasLength(252));
    expect(
      pathsById.keys.toSet(),
      sourceIds,
      reason: 'stage-pattern assets must equal the 252 source IDs (0 orphan)',
    );
    for (final id in sourceIds) {
      expect(
        pathsById[id],
        hasLength(1),
        reason: '$id must exist in exactly one loader directory (0 shadow)',
      );
    }
  });

  test('主线 chapter_01..21 卷首卷尾全为真内容', () async {
    for (var i = 1; i <= 21; i++) {
      final id = 'chapter_${i.toString().padLeft(2, '0')}';
      final chapter = await NarrativeLoader.loadChapter(id, loader: fileLoader);

      expect(chapter.isPlaceholder, isFalse, reason: '$id 不能缺章节文件');
      expect(chapter.id, id, reason: '$id 文件内 id 必须自洽');
      expect(chapter.title, isNotNull, reason: '$id 应有章节标题');
      expect(chapter.prologue, isNotNull, reason: '$id 应有卷首');
      expect(chapter.epilogue, isNotNull, reason: '$id 应有卷尾');
      expect(
        chapter.prologue,
        isNot(contains('TODO')),
        reason: '$id 卷首不能含 TODO',
      );
      expect(
        chapter.epilogue,
        isNot(contains('TODO')),
        reason: '$id 卷尾不能含 TODO',
      );
    }
  });

  test('Ch4 阳关胜利后铜镜仍留黑石，承接 Ch4 卷尾与 Ch5 回取', () async {
    final victory = await NarrativeLoader.load(
      'stage_04_05_victory',
      loader: fileLoader,
    );
    final joined = victory.paragraphs.join('\n');

    expect(joined, contains('黑石上'));
    expect(
      joined,
      isNot(contains('收进怀里')),
      reason: 'Ch4 卷尾写明小铜镜还在黑石上，Ch5 卷首第三日才回取',
    );
  });

  test('Ch5 章末战败有标题，避免阅读器标题断层', () async {
    final defeat = await NarrativeLoader.load(
      'stage_05_05_defeat',
      loader: fileLoader,
    );

    expect(defeat.title, '中州论剑 · 败');
  });
}
