import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// 战斗立绘「大气融合」档位:按所在场景背景的**合成后**明度自适应。
///
/// ## 为什么按明度、且只动立绘侧
///
/// battle-ui-v2 遗留 B3「立绘浮贴」的原诊断指错了层也指错了轴
/// (`docs/spec/2026-07-30-battle-ui-b3-evaluation.md`):
/// 实测暖度差中位仅 5.4、B3 点名的 `stage_01_05` 只有 -0.3,而**明度差**中位
/// -48.5、最深 -121.5 —— 主导轴是明度;且跨场景方差极大,故该按场景自适应,
/// 不是全局常量。杠杆全在立绘侧,**零触 90 关背景美术**。
///
/// ## 主杠杆为什么是 opacity(而非只调矩阵)
///
/// 合成式 `out = opacity×立绘 + (1-opacity)×背景`:背景亮时降 opacity 直接把
/// 立绘抬向背景;背景暗时同一 opacity 几乎不抬(没有亮色可掺)。即 opacity 融合
/// **物理自限** —— 它不可能在暗底上把人物洗淡。这也是本实装**不需要按 style
/// 另钉系数**的原因:实测暗系 style 的背景明度本就落在 [battleStandeeFusionLuminanceFloor]
/// 之下(massBattle 105.0 / lightFoot 97.5 / tower·innerDemon 125.0),
/// 明度下沿一条线就把它们全钳在基线档。
///
/// ## 边缘柔化不参与自适应
///
/// [battleStandeeEdgeSofteningSigma] 保持常量:模糊半径逐场景变会让同一角色在
/// 不同关卡的轮廓锐度漂移(比明度更容易被察觉),且 blur 是三档里最贵的一项。
const battleStandeeFusionMatrix = <double>[
  0.74,
  0.10,
  0.06,
  0,
  12,
  0.08,
  0.75,
  0.07,
  0,
  10,
  0.06,
  0.14,
  0.67,
  0,
  8,
  0,
  0,
  0,
  0.96,
  0,
];

const battleStandeeFusionOpacity = 0.96;
const battleStandeeEdgeSofteningSigma = 0.38;

/// 各战斗背景资产**合成后**的背景带明度(0-255,越大越亮)。
///
/// 取样带:真机 1280×720 战斗屏(物理 2560×1440)`x∈[0.74,0.86]`·`y∈[0.28,0.48]`
/// —— 紧邻敌立绘右侧的躯干高度带。单敌关该区恒为纯背景(玩家三席锚点 x≤0.475、
/// 单敌立绘锚心 x=0.64 实拍右缘约 0.71),已逐图目检确认无立绘像素混入。
///
/// **取样带经跨数据集自校验**:与 2026-07-30 夜批独立实测(同为「紧邻立绘同高度
/// 背景带」)在 4 个共有资产上平均绝对误差 5.9 / 最大 8.9 / 秩相关 0.80;
/// 候选「右远端带」为 18.3/34.2/0.40、「紧邻左带」为 45.5/74.2/**-0.80**。
/// 故精度按 **±9** 记 —— 这也是下沿/上沿都留了余量、不卡在实测极值上的原因。
///
/// 每个资产取其**最常用 style 下的非 boss 代表关**实测(cliffwaterfall 全仓只有
/// boss 用法,取 stage_13_04)。逐值本会话 PIL 实测,复现见评估文档。
/// 新增背景资产必须在此登记,否则 `battle_standee_fusion_test` 的覆盖棘轮会红。
const battleSceneCompositeLuminance = <String, double>{
  'assets/scenes/battle_desert.png': 192.5,
  'assets/scenes/battle_frontier.png': 180.1,
  'assets/scenes/battle_bambooforest.png': 177.4,
  'assets/scenes/battle_smithy.png': 164.1,
  'assets/scenes/battle_mountainpath.png': 147.0,
  'assets/scenes/battle_escortroad.png': 146.9,
  'assets/scenes/battle_mountainforest.png': 140.6,
  'assets/scenes/battle_citywall.png': 130.0,
  'assets/scenes/battle_dock.png': 129.8,
  'assets/scenes/battle_teahouse.png': 127.2,
  'assets/scenes/battle_innerrealm.png': 125.0,
  'assets/scenes/battle_temple.png': 122.0,
  'assets/scenes/battle_inn.png': 111.5,
  'assets/scenes/battle_cliffwaterfall.png': 103.8,
  'assets/scenes/battle_drillground.png': 103.1,
  'assets/scenes/battle_alley.png': 70.6,
};

/// 自适应下沿:背景明度不高于此值 → 完全走基线档(逐值等于自适应前的常量)。
///
/// 取 125:立绘自身合成后可见明度约 91(基线档·实测立绘带中位 85 过矩阵与
/// opacity 后),背景到 125 时明度差约 -34,尚在「人物压在背景上」而非「浮贴」的
/// 区间;再暗则融合只会把人物往背景里埋。实测 16 个资产中 6 个落在此线下。
const double battleStandeeFusionLuminanceFloor = 125.0;

/// 自适应上沿:背景明度到此值 → 用满档。取 195(实测最亮 desert 192.5 之上留 2.5
/// 余量,避免把满档钉死在单个实测点上,并吸收 ±9 的量测精度)。
const double battleStandeeFusionLuminanceCeil = 195.0;

/// 满档时的三项:opacity 下限、矩阵对角缩放、矩阵偏移缩放。
///
/// 满档在最亮场景(desert·背景 192.5)上的手算效果:立绘可见明度 90.8 → 106.2
/// (+15.4,填掉背景-立绘明度差的约 15%),同时对比范围 170.4 → 152.2(-11%)。
/// 即**软化而非抹平** —— 刻意不去填满明度差,厚涂质感与人物可读性优先
/// (评估文档 §七 记的「融合太强 → 人物发灰、失去厚涂质感」)。
const double battleStandeeFusionOpacityAtFull = 0.85;
const double _fusionDiagonalScaleAtFull = 0.87;
const double _fusionOffsetScaleAtFull = 2.2;

/// 矩阵里对角项与偏移项的下标(ColorFilter.matrix 为 4×5 行主序)。
const List<int> _matrixDiagonalIndices = <int>[0, 6, 12];
const List<int> _matrixOffsetIndices = <int>[4, 9, 14];

/// 一档立绘融合参数。[strength] 0 = 基线档(既有观感),1 = 满档。
@immutable
class BattleStandeeFusion {
  const BattleStandeeFusion({
    required this.matrix,
    required this.opacity,
    required this.strength,
  });

  final List<double> matrix;
  final double opacity;
  final double strength;

  /// 基线档:与自适应前的常量逐值相同。未接线的调用点(debug route / widget 测 /
  /// 缺登记的新资产)一律回落此档,保证零回归。
  static const BattleStandeeFusion baseline = BattleStandeeFusion(
    matrix: battleStandeeFusionMatrix,
    opacity: battleStandeeFusionOpacity,
    strength: 0,
  );

  @override
  bool operator ==(Object other) =>
      other is BattleStandeeFusion &&
      other.opacity == opacity &&
      other.strength == strength &&
      listEquals(other.matrix, matrix);

  @override
  int get hashCode => Object.hash(opacity, strength, Object.hashAll(matrix));
}

/// 把背景明度换算成融合强度(0..1)。低于下沿 → 0;高于上沿 → 1。
double battleStandeeFusionStrengthForLuminance(double luminance) {
  final span =
      battleStandeeFusionLuminanceCeil - battleStandeeFusionLuminanceFloor;
  return ((luminance - battleStandeeFusionLuminanceFloor) / span).clamp(
    0.0,
    1.0,
  );
}

/// 取本场战斗该用的融合档。
///
/// [scenePath] 为空、或不在 [battleSceneCompositeLuminance] 登记表内 →
/// [BattleStandeeFusion.baseline](保守:宁可不融合,也不对没量过的新背景瞎调)。
BattleStandeeFusion battleStandeeFusionFor({String? scenePath}) {
  if (scenePath == null || scenePath.isEmpty) {
    return BattleStandeeFusion.baseline;
  }
  final luminance = battleSceneCompositeLuminance[scenePath];
  if (luminance == null) return BattleStandeeFusion.baseline;
  return battleStandeeFusionAtStrength(
    battleStandeeFusionStrengthForLuminance(luminance),
  );
}

/// 按强度插值出融合档。[strength] 0 → 逐值等于基线;1 → 满档。
BattleStandeeFusion battleStandeeFusionAtStrength(double strength) {
  final t = strength.clamp(0.0, 1.0);
  if (t == 0) return BattleStandeeFusion.baseline;
  final diagonalScale = lerpDouble(1, _fusionDiagonalScaleAtFull, t)!;
  final offsetScale = lerpDouble(1, _fusionOffsetScaleAtFull, t)!;
  final matrix = List<double>.of(battleStandeeFusionMatrix);
  for (final i in _matrixDiagonalIndices) {
    matrix[i] = battleStandeeFusionMatrix[i] * diagonalScale;
  }
  for (final i in _matrixOffsetIndices) {
    matrix[i] = battleStandeeFusionMatrix[i] * offsetScale;
  }
  return BattleStandeeFusion(
    matrix: matrix,
    opacity: lerpDouble(
      battleStandeeFusionOpacity,
      battleStandeeFusionOpacityAtFull,
      t,
    )!,
    strength: t,
  );
}
