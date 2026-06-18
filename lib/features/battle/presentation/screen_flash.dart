import 'package:flutter/material.dart';

/// 批次 2.4 全屏轻闪。命令式 flash(strength, color)，~120ms 淡出。
/// 放在场景层之上、题字 overlay 之下。纯表现层（不写 BattleState）。
class ScreenFlashOverlay extends StatefulWidget {
  const ScreenFlashOverlay({super.key});

  @override
  State<ScreenFlashOverlay> createState() => ScreenFlashOverlayState();
}

class ScreenFlashOverlayState extends State<ScreenFlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _strength = 0.0;
  Color _color = Colors.white;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _strength = 0.0);
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void flash(double strength, {Color color = Colors.white}) {
    if (!mounted) return;
    setState(() {
      _strength = strength;
      _color = color;
    });
    _ctrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_strength <= 0.0) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final a = (1.0 - _ctrl.value) * _strength;
          return ColoredBox(color: _color.withValues(alpha: a));
        },
      ),
    );
  }
}
