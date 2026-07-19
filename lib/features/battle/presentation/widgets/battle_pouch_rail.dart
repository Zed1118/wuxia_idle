import 'package:flutter/material.dart';

/// 战备行囊的独立装帧，避免与纸签共享按钮外观。
class BattlePouchRailSurface extends StatelessWidget {
  const BattlePouchRailSurface({
    super.key,
    required this.width,
    required this.compact,
    required this.child,
  });

  final double width;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('battle_desk_pouch_region'),
      width: width,
      padding: compact
          ? const EdgeInsets.fromLTRB(14, 6, 14, 6)
          : const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xB3131210),
        border: Border.all(color: const Color(0xFF6D5940)),
      ),
      child: child,
    );
  }
}
