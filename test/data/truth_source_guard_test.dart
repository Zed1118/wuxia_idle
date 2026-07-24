import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 真相源守卫(2026-07-24 外审 triage 落地)。
///
/// A. GDD 头部「当前状态块」必须与生产真值一致——cap 读 numbers.yaml、
///    章数/关数统计 stages.yaml。加章 reconcile 漏更状态块时此测红,
///    防 GDD 头部快照再漂移(07-21/07-24 两轮外审同病根)。
/// B. 已退役配置字段不得复活(v1.34 战败不扣内力,
///    `boss_internal_force_penalty` 2026-07-24 删除)。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  group('A · GDD 当前状态块 ↔ 生产真值一致', () {
    test('发布上限/章数/关数与 numbers.yaml + stages.yaml 一致', () async {
      final repo = await GameRepository.loadAllDefs(loader: fileLoader);
      final gdd = File('GDD.md').readAsStringSync();

      final cap = repo.numbers.progressionReleaseCap.maxAbsoluteRealmLevel;
      final mainlines = repo.stageDefs.values
          .where((s) => s.stageType == StageType.mainline)
          .toList();
      final chapterCount = mainlines.map((s) => s.chapterIndex).toSet().length;

      expect(
        gdd,
        contains('绝对境界层 **$cap**'),
        reason:
            'GDD 头部当前状态块发布上限与 numbers.yaml '
            'progression.release_cap.max_absolute_realm_level=$cap 漂移,'
            '加章 reconcile 须同步状态块',
      );
      expect(
        gdd,
        contains('**$chapterCount 章 ${mainlines.length} 关**'),
        reason:
            'GDD 头部当前状态块主线规模与 stages.yaml 实况'
            '($chapterCount 章 ${mainlines.length} 关)漂移,'
            '加章 reconcile 须同步状态块',
      );
    });
  });

  group('B · 退役配置防复活', () {
    test('boss_internal_force_penalty 不得重回 numbers.yaml', () {
      final yaml = File('data/numbers.yaml').readAsStringSync();
      expect(
        yaml.contains('boss_internal_force_penalty:'),
        isFalse,
        reason:
            'v1.34 起战败不扣永久内力(只施加内息紊乱),该配置键 '
            '2026-07-24 已退役删除;如需恢复须先回 GDD §4.3 讨论',
      );
    });
  });
}
