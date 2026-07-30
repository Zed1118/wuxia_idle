import 'package:flutter/material.dart';

import 'battle_layout_tokens.dart';

enum BattleStageLayoutMode { standard, innerDemon, lightFoot, massBattle }

/// 人物舞台比例锚点（0..1）。
///
/// 1v1/2v2 保持左右镜像。标准 3v3 复刻指挥案台样板的非对称舞台：
/// 我方主位在左前景、两名弟子向中场展开；敌方主位在右中场、两名随从向右展开。
/// 轻功与心魔仍保留各自的镜像构图。
Offset battleStageAnchor(
  int teamSide,
  int slotIndex,
  int teamSize, {
  BattleStageLayoutMode mode = BattleStageLayoutMode.standard,
}) {
  final normalizedSize = teamSize.clamp(1, 3);
  final normalizedSlot = slotIndex.clamp(0, normalizedSize - 1);

  if (normalizedSize == 3 &&
      mode != BattleStageLayoutMode.lightFoot &&
      mode != BattleStageLayoutMode.innerDemon) {
    final anchors = teamSide == 0
        ? const [Offset(0.15, 0.56), Offset(0.27, 0.59), Offset(0.38, 0.35)]
        : const [Offset(0.66, 0.51), Offset(0.80, 0.58), Offset(0.90, 0.62)];
    return anchors[normalizedSlot];
  }

  final left = mode == BattleStageLayoutMode.lightFoot
      ? switch (normalizedSize) {
          1 => const [Offset(0.25, 0.50)],
          2 => const [Offset(0.27, 0.25), Offset(0.17, 0.75)],
          _ => const [
            Offset(0.28, 0.48),
            Offset(0.13, 0.14),
            Offset(0.18, 0.82),
          ],
        }
      : switch (normalizedSize) {
          1 => const [Offset(0.36, 0.55)],
          2 => const [Offset(0.36, 0.58), Offset(0.14, 0.34)],
          _ => const [
            Offset(0.38, 0.51),
            Offset(0.20, 0.64),
            Offset(0.07, 0.33),
          ],
        };
  final anchor = left[normalizedSlot];
  return teamSide == 0 ? anchor : Offset(1 - anchor.dx, anchor.dy);
}

/// 后位略缩小，形成前后景深度；1v1/2v2 时两人都保持主体尺寸。
double battleStageScale(int slotIndex, int teamSize, {bool isBoss = false}) {
  final depthScale = switch (teamSize.clamp(1, 3)) {
    1 => 1.28,
    2 => slotIndex == 0 ? 1.18 : 1.04,
    _ => switch (slotIndex) {
      0 => 1.16,
      1 => 0.96,
      _ => 0.84,
    },
  };
  return depthScale * (isBoss ? BattleLayoutTokens.bossStageScale : 1);
}
