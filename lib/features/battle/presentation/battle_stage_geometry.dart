import 'package:flutter/material.dart';

import 'battle_layout_tokens.dart';

enum BattleStageLayoutMode { standard, innerDemon, lightFoot, massBattle }

/// 人物舞台比例锚点（0..1）。
///
/// slot 0 是靠近中场的主位，slot 1/2 是斜向展开的后位。右队只镜像
/// x 坐标，y 坐标与左队一致，保证弹道与人物锚点共用同一真相源。
Offset battleStageAnchor(
  int teamSide,
  int slotIndex,
  int teamSize, {
  BattleStageLayoutMode mode = BattleStageLayoutMode.standard,
}) {
  final normalizedSize = teamSize.clamp(1, 3);
  final normalizedSlot = slotIndex.clamp(0, normalizedSize - 1);

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
          1 => const [Offset(0.27, 0.53)],
          2 => const [Offset(0.19, 0.58), Offset(0.36, 0.38)],
          _ => const [
            Offset(0.35, 0.50),
            Offset(0.15, 0.62),
            Offset(0.06, 0.36),
          ],
        };
  final anchor = left[normalizedSlot];
  return teamSide == 0 ? anchor : Offset(1 - anchor.dx, anchor.dy);
}

/// 后位略缩小，形成前后景深度；1v1/2v2 时两人都保持主体尺寸。
double battleStageScale(int slotIndex, int teamSize, {bool isBoss = false}) {
  final depthScale = teamSize < 3
      ? 1.0
      : switch (slotIndex) {
          0 => 1.18,
          1 => 0.98,
          _ => 0.86,
        };
  return depthScale * (isBoss ? BattleLayoutTokens.bossStageScale : 1);
}
