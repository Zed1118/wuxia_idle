import 'package:flutter/material.dart';

/// 人物舞台比例锚点（0..1）。
///
/// slot 0 是靠近中场的主位，slot 1/2 是斜向展开的后位。右队只镜像
/// x 坐标，y 坐标与左队一致，保证弹道与人物锚点共用同一真相源。
Offset battleStageAnchor(int teamSide, int slotIndex, int teamSize) {
  final normalizedSize = teamSize.clamp(1, 3);
  final normalizedSlot = slotIndex.clamp(0, normalizedSize - 1);

  final left = switch (normalizedSize) {
    1 => const [Offset(0.28, 0.52)],
    2 => const [Offset(0.30, 0.34), Offset(0.22, 0.70)],
    _ => const [Offset(0.31, 0.52), Offset(0.17, 0.25), Offset(0.19, 0.77)],
  };
  final anchor = left[normalizedSlot];
  return teamSide == 0 ? anchor : Offset(1 - anchor.dx, anchor.dy);
}

/// 后位略缩小，形成前后景深度；1v1/2v2 时两人都保持主体尺寸。
double battleStageScale(int slotIndex, int teamSize) {
  if (teamSize < 3 || slotIndex == 0) return 1;
  return 0.84;
}
