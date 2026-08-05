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
        ? const [
            Offset(0.11, 0.772),
            Offset(0.241, 0.592),
            Offset(0.372, 0.436),
          ]
        : const [
            Offset(0.669, 0.521),
            Offset(0.79, 0.601),
            Offset(0.908, 0.615),
          ];
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

/// 样板的状态签刻意压在人物下裳，而不是跟随每张透明原图的脚底留白。
///
/// 仅标准 3v3 使用非对称校准；1v1/2v2 与特殊舞台继续沿公共脚底线。
double battleStageStatusVerticalFraction(
  int teamSide,
  int slotIndex,
  int teamSize,
) {
  if (teamSize != 3) return 0.865;
  const left = [0.724, 0.703, 0.901];
  const right = [0.745, 0.789, 0.868];
  final slot = slotIndex.clamp(0, 2);
  return (teamSide == 0 ? left : right)[slot];
}

double battleStageBottomOverflowFraction(
  int teamSide,
  int slotIndex,
  int teamSize, {
  BattleStageLayoutMode mode = BattleStageLayoutMode.standard,
}) {
  if (mode == BattleStageLayoutMode.standard &&
      teamSize == 3 &&
      teamSide == 0 &&
      slotIndex == 0) {
    return 0.06;
  }
  return 0;
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
