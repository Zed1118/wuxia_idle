import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';

/// 主菜单门派名横幅（纯展示）。sectName 由父层从 activeSave 取。
class SectBanner extends StatelessWidget {
  const SectBanner({required this.sectName, super.key});

  final String sectName;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      sectName,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: WuxiaColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    ),
  );
}
