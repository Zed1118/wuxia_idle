import 'package:flutter/material.dart';

import '../../audio/sound_manager.dart';
import '../../audio/audio_assets.dart';
import '../../theme/wuxia_tokens.dart';

/// 木牌页签（UI kit · demo `.plaque` / `.plaque.on`）：替 Material Tab。
///
/// 木纹底；[selected]=绛红朱漆烙印。单个页签，调用方用 Row/Wrap 排成页签条。
class PlaqueTab extends StatelessWidget {
  const PlaqueTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = selected
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WuxiaUi.jiang, Color(0xFF6F201A)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCDB585), Color(0xFFB89A63)],
          );
    final fg = selected ? const Color(0xFFF3E2C0) : const Color(0xFF3A2C14);
    final borderColor = selected ? const Color(0xFF491510) : WuxiaUi.woodDark;
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              SoundManager.instance.playSfx(SfxId.uiTabSwitch);
              onTap!();
            },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: WuxiaUi.borderWidth),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
