import 'package:flutter/material.dart';

import '../../audio/sound_manager.dart';
import '../../audio/audio_assets.dart';
import '../../theme/wuxia_tokens.dart';

/// 木牌按钮（UI kit · demo `.wbtn`）：替黄描边 Material 按钮。
///
/// 木纹渐变底 + 木边；[primary] 为真=绛红朱漆主行动钮。[disabled] 半透 0.4 拦点击。
/// P2-6(2026-06-29 审查修复):去 Material InkWell 灰色水波纹(与木牌质感不符),
/// 改 GestureDetector + 按下暗层 overlay(`AnimatedOpacity` 暗色 scrim),点击响应不变。
class PlaqueButton extends StatefulWidget {
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
  State<PlaqueButton> createState() => _PlaqueButtonState();
}

class _PlaqueButtonState extends State<PlaqueButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.disabled;
    final gradient = widget.primary
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
    final fg =
        widget.primary ? const Color(0xFFF3E2C0) : const Color(0xFF3A2C14);
    final borderColor =
        widget.primary ? const Color(0xFF491510) : WuxiaUi.woodDark;
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => _setPressed(true),
        onTapUp: disabled ? null : (_) => _setPressed(false),
        onTapCancel: disabled ? null : () => _setPressed(false),
        onTap: disabled
            ? null
            : () {
                SoundManager.instance.playSfx(SfxId.uiTap);
                widget.onTap?.call();
              },
        child: Stack(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: borderColor,
                  width: WuxiaUi.borderWidth,
                ),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            // 按下暗层:替 InkWell 水波纹,木牌质感的「压下」反馈。
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _pressed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 90),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
