import 'package:flutter/material.dart';

import '../../audio/audio_assets.dart';
import '../../audio/sound_manager.dart';
import '../../theme/wuxia_tokens.dart';

/// 木牌页签（UI kit · demo `.plaque` / `.plaque.on`）：替 Material Tab。
///
/// 木纹底；[selected]=绛红朱漆烙印。单个页签，调用方用 Row/Wrap 排成页签条。
class PlaqueTab extends StatefulWidget {
  const PlaqueTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.autofocus = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool autofocus;

  static const double minHeight = 40;
  static const double minWidth = 72;

  @override
  State<PlaqueTab> createState() => _PlaqueTabState();
}

class _PlaqueTabState extends State<PlaqueTab> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _activate() {
    if (widget.onTap == null) return;
    SoundManager.instance.playSfx(SfxId.uiTabSwitch);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.selected
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
    final fg = widget.selected
        ? const Color(0xFFF3E2C0)
        : const Color(0xFF3A2C14);
    final borderColor = widget.selected
        ? const Color(0xFF491510)
        : WuxiaUi.woodDark;
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        autofocus: widget.autofocus,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: Opacity(
          opacity: enabled ? 1 : 0.72,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            onTap: enabled ? _activate : null,
            child: Stack(
              children: [
                Container(
                  constraints: const BoxConstraints(
                    minWidth: PlaqueTab.minWidth,
                    minHeight: PlaqueTab.minHeight,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _pressed ? 1 : 0,
                      duration: const Duration(milliseconds: 90),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_focused)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: WuxiaUi.gold, width: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
