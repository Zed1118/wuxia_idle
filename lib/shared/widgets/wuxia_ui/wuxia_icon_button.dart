import 'package:flutter/material.dart';

import '../../audio/audio_assets.dart';
import '../../audio/sound_manager.dart';
import '../../theme/colors.dart';
import '../../theme/wuxia_tokens.dart';

/// 水墨图标按钮：小图标、固定桌面热区、无 Material 水波纹。
class WuxiaIconButton extends StatefulWidget {
  const WuxiaIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.destructive = false,
    this.autofocus = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool autofocus;

  static const double size = 44;
  static const double iconSize = 20;

  @override
  State<WuxiaIconButton> createState() => _WuxiaIconButtonState();
}

class _WuxiaIconButtonState extends State<WuxiaIconButton> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _activate() {
    if (!_enabled) return;
    SoundManager.instance.playSfx(SfxId.uiTap);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.destructive ? WuxiaColors.danger : WuxiaColors.textMuted;
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: widget.tooltip,
        child: FocusableActionDetector(
          enabled: _enabled,
          autofocus: widget.autofocus,
          mouseCursor: _enabled
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
          child: MouseRegion(
            onEnter: _enabled ? (_) => setState(() => _hovered = true) : null,
            onExit: _enabled ? (_) => setState(() => _hovered = false) : null,
            child: Opacity(
              opacity: _enabled ? 1 : 0.38,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _enabled ? (_) => _setPressed(true) : null,
                onTapUp: _enabled ? (_) => _setPressed(false) : null,
                onTapCancel: _enabled ? () => _setPressed(false) : null,
                onTap: _enabled ? _activate : null,
                child: Stack(
                  children: [
                    Container(
                      width: WuxiaIconButton.size,
                      height: WuxiaIconButton.size,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: WuxiaUi.paper.withValues(
                          alpha: _hovered ? 0.18 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: WuxiaUi.ink.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        size: WuxiaIconButton.iconSize,
                        color: fg,
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _pressed ? 1 : 0,
                          duration: const Duration(milliseconds: 90),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: WuxiaUi.ink.withValues(alpha: 0.12),
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
        ),
      ),
    );
  }
}
