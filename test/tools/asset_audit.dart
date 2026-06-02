// 资产缺图审计——纯扫描逻辑（读 GameRepository.instance）。
// 跑法见 asset_audit_test.dart。
import 'dart:io';

import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/domain/chapter_assets.dart';

enum AssetCategory { equipment, enemy, portrait, scene, chapterCover, narrative }

class AssetRef {
  final String path;
  final AssetCategory category;
  final String sourceId; // 谁引用了它（报告标注用）
  const AssetRef(this.path, this.category, this.sourceId);
}

bool assetExists(String path) => File(path).existsSync();

/// 从生产 def 收集所有被引用的资产路径。
List<AssetRef> collectAssetRefs() {
  final repo = GameRepository.instance;
  final refs = <AssetRef>[];

  // 装备 icon（必填）+ detail（可空）
  for (final e in repo.equipmentDefs.values) {
    refs.add(AssetRef(e.iconPath, AssetCategory.equipment, e.id));
    final d = e.detailPath;
    if (d != null) {
      refs.add(AssetRef(d, AssetCategory.equipment, '${e.id} (detail)'));
    }
  }

  // 主线 stage：敌人 iconPath + 场景背景 + 章节封面 + 剧情背景
  final chapters = <int>{};
  for (final s in repo.stageDefs.values) {
    for (final en in s.enemyTeam) {
      if (en.iconPath.isNotEmpty) {
        refs.add(AssetRef(en.iconPath, AssetCategory.enemy, s.id));
      }
    }
    final sb = s.sceneBackgroundPath;
    if (sb != null) refs.add(AssetRef(sb, AssetCategory.scene, s.id));
    final ci = s.chapterIndex;
    if (s.stageType == StageType.mainline && ci != null) {
      chapters.add(ci);
      refs.add(AssetRef(stageNarrativePath(s.id), AssetCategory.narrative, s.id));
    }
  }
  for (final c in (chapters.toList()..sort())) {
    refs.add(AssetRef(chapterCoverPath(c), AssetCategory.chapterCover, 'chapter_$c'));
  }

  // 爬塔 floor：敌人 + 场景背景
  for (final f in repo.towerFloors) {
    for (final en in f.enemyTeam) {
      if (en.iconPath.isNotEmpty) {
        refs.add(AssetRef(en.iconPath, AssetCategory.enemy, 'tower_floor_${f.floorIndex}'));
      }
    }
    final sb = f.sceneBackgroundPath;
    if (sb != null) {
      refs.add(AssetRef(sb, AssetCategory.scene, 'tower_floor_${f.floorIndex}'));
    }
  }

  // 立绘 portraitPath（祖师/弟子 + 收徒 + 门派招收）
  repo.masters.asMap().forEach((i, m) {
    final p = m.portraitPath;
    if (p != null) refs.add(AssetRef(p, AssetCategory.portrait, 'master[$i]'));
  });
  repo.recruitCandidates.forEach((k, v) {
    final p = v.portraitPath;
    if (p != null) refs.add(AssetRef(p, AssetCategory.portrait, 'recruit:$k'));
  });
  repo.sectCandidates.forEach((k, v) {
    final p = v.portraitPath;
    if (p != null) refs.add(AssetRef(p, AssetCategory.portrait, 'sect:$k'));
  });

  return refs;
}

/// 缺图路径（去重排序）。
List<String> missingPaths(List<AssetRef> refs) {
  final s = refs.map((r) => r.path).where((p) => !assetExists(p)).toSet().toList()
    ..sort();
  return s;
}

/// 人看的分类别 md 报告（附引用源）。
String buildReport(List<AssetRef> refs) {
  final buf = StringBuffer();
  buf.writeln('# 资产缺图审计报告');
  buf.writeln();
  buf.writeln('> 工具生成，勿手改。跑法:`flutter test test/tools/asset_audit_test.dart`');
  buf.writeln();
  buf.writeln('## 汇总');
  buf.writeln();
  buf.writeln('| 类别 | 引用(去重) | 存在 | 缺失 |');
  buf.writeln('|---|---|---|---|');
  for (final cat in AssetCategory.values) {
    final paths =
        refs.where((r) => r.category == cat).map((r) => r.path).toSet();
    final miss = paths.where((p) => !assetExists(p)).length;
    buf.writeln('| ${cat.name} | ${paths.length} | ${paths.length - miss} | $miss |');
  }
  final all = refs.map((r) => r.path).toSet();
  final allMiss = all.where((p) => !assetExists(p)).length;
  buf.writeln('| **合计** | ${all.length} | ${all.length - allMiss} | $allMiss |');
  buf.writeln();
  buf.writeln('## 缺图清单');
  for (final cat in AssetCategory.values) {
    final byPath = <String, List<String>>{};
    for (final r in refs.where((r) => r.category == cat && !assetExists(r.path))) {
      byPath.putIfAbsent(r.path, () => []).add(r.sourceId);
    }
    if (byPath.isEmpty) continue;
    buf.writeln();
    buf.writeln('### ${cat.name} (${byPath.length})');
    buf.writeln();
    for (final p in byPath.keys.toList()..sort()) {
      buf.writeln('- `$p` ← ${byPath[p]!.join(', ')}');
    }
  }
  return buf.toString();
}

const String allowlistPath = 'test/fixtures/known_missing_assets.txt';

/// 读 allowlist(跳空行 + # 注释)。
Set<String> loadAllowlist([String path = allowlistPath]) {
  final f = File(path);
  if (!f.existsSync()) return <String>{};
  return f
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toSet();
}
