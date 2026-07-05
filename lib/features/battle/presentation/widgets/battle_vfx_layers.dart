import 'package:flutter/material.dart';

import '../battle_effect_sprite.dart';
import '../battle_vfx_entries.dart';
import '../projectile_trail.dart';

// ─── 弹道层（P0-2 Task7）────────────────────────────────────────────────────

/// 把活跃弹道的战场比例坐标解析为像素并渲染（叠在 BattleField 上方）。
/// 纯表现层：只读 [TrailEntry] 几何，由 AnimationController 驱动。
class ProjectileLayer extends StatelessWidget {
  final List<TrailEntry> trails;
  const ProjectileLayer({super.key, required this.trails});

  @override
  Widget build(BuildContext context) {
    if (trails.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            for (final t in trails)
              ProjectileTrail(
                key: ValueKey(t.id),
                animation: t.ctrl,
                color: t.color,
                strokeWidth: t.strokeWidth,
                start: Offset(t.startFrac.dx * w, t.startFrac.dy * h),
                end: Offset(t.endFrac.dx * w, t.endFrac.dy * h),
              ),
          ],
        );
      },
    );
  }
}

/// Phase 4 拖招引导线层:从技能按钮锚点到当前指针的流派色笔触线(实时跟手)。
/// 纯表现层,IgnorePointer 不拦手势(手势由按钮的 LongPress 识别器持有)。
class EffectLayer extends StatelessWidget {
  final List<EffectEntry> effects;
  const EffectLayer({super.key, required this.effects});

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final e in effects)
              Positioned(
                left: e.centerFrac.dx * w - e.size / 2,
                top: e.centerFrac.dy * h - e.size / 2,
                width: e.size,
                height: e.size,
                child: BattleEffectSprite(
                  key: ValueKey(e.id),
                  assetPath: e.assetPath,
                  animation: e.ctrl,
                  size: e.size,
                  opacity: e.opacity,
                  rotation: e.rotation,
                  mirrored: e.mirrored,
                ),
              ),
          ],
        );
      },
    );
  }
}
