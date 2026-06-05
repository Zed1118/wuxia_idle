import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';

/// 木牌按钮（UI kit · demo `.wbtn`）：替黄描边 Material 按钮。
///
/// 木纹渐变底 + 木边；[primary] 为真=绛红朱漆主行动钮。[disabled] 半透 0.4 拦点击。
class PlaqueButton extends StatelessWidget {
  const PlaqueButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final gradient = primary
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8A2B21), Color(0xFF6F201A)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCDB585), Color(0xFFB89A63)],
          );
    final fg = primary ? const Color(0xFFF3E2C0) : const Color(0xFF3A2C14);
    final borderColor = primary ? const Color(0xFF491510) : WuxiaUi.woodDark;
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: WuxiaUi.borderWidth),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
