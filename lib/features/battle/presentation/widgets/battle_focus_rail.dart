import 'package:flutter/material.dart';

/// 执招者名帖的统一墨框，内容与点击语义由调用方提供。
class BattleFocusRailSurface extends StatelessWidget {
  const BattleFocusRailSurface({
    super.key,
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('battle_desk_focus_region'),
      width: width,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: const Color(0xB3131210),
        border: Border.all(color: const Color(0xFF6D5940)),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
      ),
      child: child,
    );
  }
}
