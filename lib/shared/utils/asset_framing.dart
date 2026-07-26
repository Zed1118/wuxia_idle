import 'package:flutter/material.dart';

/// 位图在 `BoxFit.cover` 下的用途级裁切元数据。
///
/// [focus] 与 [safeArea] 都采用 0–1 原图坐标。组件只消费焦点来改变裁切落点，
/// 安全区供资产门禁和后续多比例导出校验使用，不改变任何页面几何。
@immutable
class AssetFraming {
  const AssetFraming({required this.focus, required this.safeArea});

  static const centered = AssetFraming(
    focus: Offset(0.5, 0.5),
    safeArea: Rect.fromLTWH(0, 0, 1, 1),
  );

  final Offset focus;
  final Rect safeArea;

  Alignment get alignment => Alignment(focus.dx * 2 - 1, focus.dy * 2 - 1);
}

const _sceneFraming = <String, AssetFraming>{
  // 方形断崖图转桌面宽屏时优先保住瀑布源头、峡口与近景落脚带。
  'assets/scenes/battle_cliffwaterfall.png': AssetFraming(
    focus: Offset(0.62, 0.43),
    safeArea: Rect.fromLTWH(0.20, 0.08, 0.72, 0.76),
  ),
  // 山道两版共享中轴与地平线，轻微上移可避免矮窗把远山压出画面。
  'assets/scenes/battle_mountain_pass_stage_v2.png': AssetFraming(
    focus: Offset(0.5, 0.46),
    safeArea: Rect.fromLTWH(0.16, 0.10, 0.68, 0.76),
  ),
  'assets/scenes/battle_mountain_pass_stage_cool_v3.png': AssetFraming(
    focus: Offset(0.5, 0.46),
    safeArea: Rect.fromLTWH(0.16, 0.10, 0.68, 0.76),
  ),
  // 厅堂以牌匾—长案中轴为主体，裁切时略保上缘以维持空间纵深。
  'assets/scenes/sect_hall_main_v1.png': AssetFraming(
    focus: Offset(0.5, 0.43),
    safeArea: Rect.fromLTWH(0.22, 0.08, 0.56, 0.76),
  ),
};

/// 只对明确登记的离群场景改变焦点；其他既有背景继续居中。
AssetFraming assetFramingForScene(String assetPath) =>
    _sceneFraming[assetPath] ?? AssetFraming.centered;

const _portraitFraming = <String, AssetFraming>{
  'assets/characters/founder.png': _upperBodyPortrait,
  'assets/characters/first_disciple.png': _upperBodyPortrait,
  'assets/characters/second_disciple.png': _upperBodyPortrait,
  'assets/characters/recruit_candidate_a.png': _upperBodyPortrait,
  'assets/characters/recruit_candidate_b.png': _upperBodyPortrait,
  'assets/characters/recruit_candidate_c.png': _upperBodyPortrait,
  'assets/characters/sect_candidate_bamboo.png': _upperBodyPortrait,
  'assets/characters/sect_candidate_blacksmith.png': _upperBodyPortrait,
  'assets/characters/sect_candidate_desert.png': _upperBodyPortrait,
  'assets/characters/sect_candidate_mountain.png': _upperBodyPortrait,
  'assets/characters/sect_candidate_river.png': _upperBodyPortrait,
  'assets/characters/sect_candidate_valley.png': _upperBodyPortrait,
};

const _upperBodyPortrait = AssetFraming(
  focus: Offset(0.5, 0.25),
  safeArea: Rect.fromLTWH(0.16, 0.04, 0.68, 0.62),
);

/// 生产纵向肖像以脸部和上半身为方形头像焦点；透明战斗站姿不在此表内。
AssetFraming assetFramingForPortrait(String assetPath) =>
    _portraitFraming[assetPath] ?? AssetFraming.centered;
