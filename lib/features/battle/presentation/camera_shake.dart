import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 批次 2.4 镜头轻震。命令式 shake(magnitude)，~250ms 高频衰减抖动。
/// 包战斗场景层（不含 HUD/指令台/题字）。纯表现层（不写 BattleState）。
class CameraShake extends StatefulWidget {
  final Widget child;
  const CameraShake({super.key, required this.child});

  @override
  State<CameraShake> createState() => CameraShakeState();
}

class CameraShakeState extends State<CameraShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _magnitude = 0.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void shake(double magnitude) {
    _magnitude = magnitude;
    _ctrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        if (_ctrl.value >= 1.0 || _magnitude <= 0.0) return child!;
        final decay = (1.0 - _ctrl.value);
        final dx = math.sin(_ctrl.value * math.pi * 12) * _magnitude * decay;
        final dy = math.cos(_ctrl.value * math.pi * 10) * _magnitude * decay;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: widget.child,
    );
  }
}
