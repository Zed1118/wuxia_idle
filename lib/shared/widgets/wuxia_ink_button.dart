import 'package:flutter/material.dart';

import '../audio/sound_manager.dart';
import '../audio/audio_assets.dart';
import '../theme/colors.dart';
import 'wuxia_image.dart';
import 'wuxia_ui/wuxia_ui.dart';

/// 水墨入口按钮（Phase A 出版美术 · 从 `main_menu` 的 `_MenuButton` 抽出共用）。
///
/// 行为与原 `_MenuButton` 等价：panel 底 + border + 标题 + hint 双行；
/// `disabled` 时半透明（0.4）且拦截点击。`locked` 为真时在右侧显锁印图标
/// （§5.7 未解锁系统克制提示），通常与 `disabled` 同时为真。
/// 视觉精修（木牌/卷轴质感）留后续迭代（spec A5）。
class WuxiaInkButton extends StatefulWidget {
  const WuxiaInkButton({
    super.key,
    required this.label,
    required this.hint,
    required this.onTap,
    this.icon,
    this.thumbnailPath,
    this.status,
    this.disabled = false,
    this.locked = false,
    this.autofocus = false,
  });

  final String label;
  final String hint;
  final IconData? icon;
  final String? thumbnailPath;
  final String? status;
  final VoidCallback? onTap;
  final bool disabled;
  final bool autofocus;

  /// 锁态:右侧显锁印图标（§5.7 未解锁系统）。不影响点击/透明（由 [disabled] 控）。
  final bool locked;

  static const double minHeight = 82;

  @override
  State<WuxiaInkButton> createState() => _WuxiaInkButtonState();
}

class _WuxiaInkButtonState extends State<WuxiaInkButton> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => !widget.disabled && widget.onTap != null;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _activate() {
    if (!_enabled) return;
    SoundManager.instance.playSfx(SfxId.uiTap);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      hint: widget.hint,
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
            opacity: widget.disabled ? 0.4 : 1.0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _enabled ? (_) => _setPressed(true) : null,
              onTapUp: _enabled ? (_) => _setPressed(false) : null,
              onTapCancel: _enabled ? () => _setPressed(false) : null,
              onTap: _enabled ? _activate : null,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: WuxiaInkButton.minHeight,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xE6D9C396),
                      Color(0xE0B9915D),
                      Color(0xE0695130),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: WuxiaUi.ink.withValues(alpha: 0.72),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x5C000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Color(0x1AF3E2C0),
                      blurRadius: 10,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.16,
                          child: WuxiaImage(
                            WuxiaUi.paperBg,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: widget.thumbnailPath == null ? 7 : 96,
                          color: WuxiaUi.ink.withValues(alpha: 0.42),
                          child: widget.thumbnailPath == null
                              ? null
                              : _InkButtonThumbnail(
                                  widget.thumbnailPath!,
                                  icon: widget.icon,
                                ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: WuxiaUi.paper.withValues(alpha: 0.34),
                              ),
                              bottom: BorderSide(
                                color: WuxiaUi.ink.withValues(alpha: 0.24),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          widget.thumbnailPath != null
                              ? 108
                              : (widget.icon == null ? 22 : 16),
                          14,
                          16,
                          14,
                        ),
                        child: Row(
                          children: [
                            if (widget.thumbnailPath == null &&
                                widget.icon != null) ...[
                              _InkButtonIcon(widget.icon!),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: WuxiaUi.ink,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      if (widget.status != null) ...[
                                        const SizedBox(width: 8),
                                        _InkButtonStatusChip(widget.status!),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    height: 30,
                                    child: Text(
                                      widget.hint,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: WuxiaUi.ink.withValues(
                                          alpha: 0.72,
                                        ),
                                        fontSize: 12,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.locked)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: WuxiaColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _pressed
                                ? 1
                                : _hovered
                                ? 0.55
                                : 0,
                            duration: const Duration(milliseconds: 100),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _pressed
                                    ? WuxiaUi.ink.withValues(alpha: 0.12)
                                    : WuxiaUi.paper.withValues(alpha: 0.10),
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
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: WuxiaUi.gold,
                                  width: 2,
                                ),
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
      ),
    );
  }
}

class _InkButtonIcon extends StatelessWidget {
  const _InkButtonIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: WuxiaUi.ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: WuxiaUi.paper.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Icon(icon, size: 21, color: WuxiaUi.ink.withValues(alpha: 0.82)),
    );
  }
}

class _InkButtonThumbnail extends StatelessWidget {
  const _InkButtonThumbnail(this.path, {this.icon});

  final String path;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WuxiaImage(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                WuxiaUi.ink.withValues(alpha: 0.08),
                WuxiaUi.ink.withValues(alpha: 0.34),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 1,
            color: WuxiaUi.paper.withValues(alpha: 0.32),
          ),
        ),
        if (icon != null)
          Center(
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WuxiaUi.ink.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: WuxiaUi.paper.withValues(alpha: 0.38),
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: WuxiaUi.paper.withValues(alpha: 0.92),
              ),
            ),
          ),
      ],
    );
  }
}

class _InkButtonStatusChip extends StatelessWidget {
  const _InkButtonStatusChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 116),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: WuxiaUi.ink.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.28)),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: WuxiaUi.ink.withValues(alpha: 0.82),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
