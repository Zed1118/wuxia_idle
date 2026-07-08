import 'package:flutter/material.dart';

import 'damage_popup.dart';
import 'projectile_trail_style.dart';

/// 飘字围绕受击槽位散开的锚点。
enum DamagePopupAnchor {
  upperLeft,
  upperRight,
  centerBurst,
  lowerLeft,
  lowerRight,
}

/// 单个飘字条目（id + 数据）。
class PopupEntry {
  final int id;
  final DamagePopupData data;
  final DamagePopupAnchor anchor;
  // 飘字有效时长:spawn 时按当前播放速度 clamp(≤ 拍间隔),防快档跨拍重叠。
  final int popupDurationMs;
  const PopupEntry({
    required this.id,
    required this.data,
    required this.anchor,
    required this.popupDurationMs,
  });
}

/// 单条弹道（攻击者→目标的笔触线，命令式 spawn，纯表现层）。
/// 坐标用战场比例（0..1），由 [ProjectileLayer] 在 LayoutBuilder 内解析为像素。
class TrailEntry {
  final int id;
  final AnimationController ctrl;
  final Offset startFrac;
  final Offset endFrac;
  final Color color;
  final double strokeWidth;
  final ProjectileTrailStyle style;
  bool disposed = false;
  TrailEntry({
    required this.id,
    required this.ctrl,
    required this.startFrac,
    required this.endFrac,
    required this.color,
    required this.strokeWidth,
    required this.style,
  });
}

/// 单条 MJ 战斗特效贴片。纯表现层，坐标用战场比例，动画完成后移除。
class EffectEntry {
  final int id;
  final AnimationController ctrl;
  final Offset centerFrac;
  final String assetPath;
  final double size;
  final double opacity;
  final double rotation;
  final bool mirrored;
  bool disposed = false;

  EffectEntry({
    required this.id,
    required this.ctrl,
    required this.centerFrac,
    required this.assetPath,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.mirrored,
  });
}
