import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';

/// 问鼎九霄 Boss 层剧情完整性守护(2026-06-26)。
///
/// 6 个 Boss 层(5/10/15/20/25/30)的 narrativeOpeningId / narrativeVictoryId
/// 都配在 towers.yaml,但文案文件曾全缺 → 加载层兜底返回占位「[剧情待补]」,
/// Boss 战只见占位符(用户实玩 floor 25 抓到)。本测锁:凡配了 id 的塔层,
/// id 都能加载到真内容(非 placeholder + 段落非空),防文件再缺/改名漏。
void main() {
  late GameRepository repo;
  Future<String> fileLoader(String path) => File(path).readAsString();

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(loader: fileLoader);
  });

  test('每个配了 narrative id 的塔层都加载到真内容(非占位)', () async {
    final checked = <String>[];
    for (final floor in repo.towerFloors) {
      for (final id in [floor.narrativeOpeningId, floor.narrativeVictoryId]) {
        if (id == null) continue;
        final content = await NarrativeLoader.load(id, loader: fileLoader);
        expect(
          content.isPlaceholder,
          isFalse,
          reason: 'floor ${floor.floorIndex} 的 $id 文案缺失(占位符) —— '
              '应在 data/narratives/$id.yaml 补真内容',
        );
        expect(
          content.paragraphs,
          isNotEmpty,
          reason: '$id 段落为空',
        );
        checked.add(id);
      }
    }
    // 6 Boss 层 × (opening + victory) = 12,防「一个都没配」误判全绿。
    expect(checked.length, 12, reason: '应覆盖 6 Boss 层 × opening/victory');
  });
}
