/// 章节封面资产路径(出版美术 Phase A · 章节页封面接线)。
///
/// 约定路径 `assets/scenes/chapter_<NN>_cover.png`(NN 两位补零),无图走调用方
/// errorBuilder 兜底(沿 `technique_panel_screen` enum-keyed inline asset 体例)。
/// card + 过场屏共用此单一真相源,不在两处写裸路径(DRY)。
String chapterCoverPath(int chapterIndex) {
  final nn = chapterIndex.toString().padLeft(2, '0');
  return 'assets/scenes/chapter_${nn}_cover.png';
}

/// 主线 stage 剧情背景图路径(出版美术 · 剧情阅读屏)。
/// 约定 `assets/scenes/narrative_<stageId>.png`,无图走 NarrativeSceneBackground
/// errorBuilder 兜底。与 [chapterCoverPath] 同列(单一真相源,不写裸路径)。
String stageNarrativePath(String stageId) => 'assets/scenes/narrative_$stageId.png';
