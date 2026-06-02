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
