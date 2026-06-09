import 'package:flutter/material.dart';

import '../audio/sound_manager.dart';
import '../audio/audio_assets.dart';
import '../theme/colors.dart';
import 'wuxia_ui/wuxia_ui.dart';

/// 水墨入口按钮（Phase A 出版美术 · 从 `main_menu` 的 `_MenuButton` 抽出共用）。
///
/// 行为与原 `_MenuButton` 等价：panel 底 + border + 标题 + hint 双行；
/// `disabled` 时半透明（0.4）且拦截点击。`locked` 为真时在右侧显锁印图标
/// （§5.7 未解锁系统克制提示），通常与 `disabled` 同时为真。
/// 视觉精修（木牌/卷轴质感）留后续迭代（spec A5）。
class WuxiaInkButton extends StatelessWidget {
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
  });

  final String label;
  final String hint;
  final IconData? icon;
  final String? thumbnailPath;
  final String? status;
  final VoidCallback? onTap;
  final bool disabled;

  /// 锁态:右侧显锁印图标（§5.7 未解锁系统）。不影响点击/透明（由 [disabled] 控）。
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                SoundManager.instance.playSfx(SfxId.uiTap);
                onTap?.call();
              },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE6D9C396), Color(0xE0B9915D), Color(0xE0695130)],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.72)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 7,
                offset: Offset(0, 4),
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
                    child: Image.asset(
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
                    width: thumbnailPath == null ? 7 : 96,
                    color: WuxiaUi.ink.withValues(alpha: 0.42),
                    child: thumbnailPath == null
                        ? null
                        : _InkButtonThumbnail(thumbnailPath!, icon: icon),
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
                    thumbnailPath != null ? 108 : (icon == null ? 22 : 16),
                    14,
                    16,
                    14,
                  ),
                  child: Row(
                    children: [
                      if (thumbnailPath == null && icon != null) ...[
                        _InkButtonIcon(icon!),
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
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: WuxiaUi.ink,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (status != null) ...[
                                  const SizedBox(width: 8),
                                  _InkButtonStatusChip(status!),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              hint,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: WuxiaUi.ink.withValues(alpha: 0.72),
                                fontSize: 12,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (locked)
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
                Positioned(
                  right: 8,
                  top: 7,
                  child: SizedBox(
                    width: 15,
                    height: 15,
                    child: Image.asset(
                      WuxiaUi.sealRed,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
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
        Image.asset(
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
