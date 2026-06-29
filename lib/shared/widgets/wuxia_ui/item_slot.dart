import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../theme/wuxia_tokens.dart';
import '../equipment_art_image.dart';
import '../equipment_glyph.dart';
import 'seal_badge.dart';

/// 宣纸物品格（UI kit · demo `.islot`）：替白底缩略图格。
///
/// 宣纸格底 + tier 墨框（[highTier]=金框 [WuxiaUi.gold] + 光晕）+ detail 图
/// contain + 强化朱印（[enhanceLevel]>0 → [SealBadge] +N）+ 未达境界封条
/// （[locked] → 全覆盖墨遮罩 + [lockText]）+ 名称在下。
/// 图缺失/[imagePath] null 走现有 [EquipGlyph] 占位（部位首字），守 widget 测不破布局。
class ItemSlot extends StatefulWidget {
  const ItemSlot({
    super.key,
    required this.imagePath,
    required this.name,
    required this.tierColor,
    required this.equipmentSlot,
    this.enhanceLevel = 0,
    this.locked = false,
    this.lockText = '未达境界',
    this.highTier = false,
    this.size = 96,
    this.leadingBadgeIcon,
    this.leadingBadgeColor,
    this.trailingBadgeIcon,
    this.trailingBadgeColor,
    this.leadingBadgeTooltip,
    this.trailingBadgeTooltip,
    this.statusText,
    this.tierLabel,
    this.protected = false,
    this.protectedText,
    this.protectedTooltip,
    this.selected = false,
    this.onTap,
  });

  final String? imagePath;
  final String name;
  final Color tierColor;
  final EquipmentSlot equipmentSlot;
  final int enhanceLevel;
  final bool locked;
  final String lockText;
  final bool highTier;
  final double size;
  final IconData? leadingBadgeIcon;
  final Color? leadingBadgeColor;
  final IconData? trailingBadgeIcon;
  final Color? trailingBadgeColor;
  final String? leadingBadgeTooltip;
  final String? trailingBadgeTooltip;
  final String? statusText;
  final String? tierLabel;
  final bool protected;
  final String? protectedText;
  final String? protectedTooltip;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<ItemSlot> createState() => _ItemSlotState();
}

class _ItemSlotState extends State<ItemSlot> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tierAccent = widget.highTier ? WuxiaUi.gold : widget.tierColor;
    final frameColor = widget.selected ? WuxiaUi.jiang : tierAccent;
    final frameWidth = widget.selected || _hovered ? 2.8 : 2.2;
    final glyph = EquipGlyph(
      tierColor: widget.tierColor,
      slot: widget.equipmentSlot,
    );
    final glow = <BoxShadow>[
      if (widget.highTier)
        BoxShadow(
          color: WuxiaUi.gold.withValues(alpha: _hovered ? 0.42 : 0.30),
          blurRadius: _hovered ? 14 : 9,
          spreadRadius: 0.5,
        ),
      if (widget.selected)
        BoxShadow(
          color: WuxiaUi.jiang.withValues(alpha: 0.30),
          blurRadius: 10,
          spreadRadius: 0.5,
        ),
      if (_hovered)
        BoxShadow(
          color: WuxiaUi.ink.withValues(alpha: 0.22),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
    ];
    // RepaintBoundary:格子有渐变+多重阴影+图标,页面切换动画/hover 时
    // 隔离重绘——栅格化一次后合成,不随过渡每帧重绘整片网格(144Hz 实测
    // 进仓库持续 8-11ms 光栅丢帧根因)。
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: widget.onTap,
              onHover: (value) => setState(() => _hovered = value),
              onHighlightChanged: (value) => setState(() => _pressed = value),
              borderRadius: BorderRadius.circular(5),
              child: AnimatedContainer(
                key: const ValueKey('itemSlotFrame'),
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: widget.size,
                height: widget.size,
                padding: EdgeInsets.all(_pressed ? 5 : 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WuxiaUi.paper.withValues(alpha: _hovered ? 0.92 : 0.82),
                      WuxiaUi.slotFill,
                      WuxiaUi.paper2.withValues(alpha: 0.78),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: frameColor, width: frameWidth),
                  boxShadow: glow.isEmpty ? null : glow,
                ),
                clipBehavior: Clip.antiAlias,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: WuxiaUi.slotFill.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: WuxiaUi.ink.withValues(alpha: 0.52),
                      width: 0.8,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        left: 7,
                        right: 7,
                        bottom: 18,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: WuxiaUi.woodDark.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const SizedBox(height: 3),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          7,
                          widget.tierLabel == null ? 7 : 18,
                          7,
                          widget.statusText == null ? 7 : 17,
                        ),
                        child: widget.imagePath == null
                            ? glyph
                            : EquipmentArtImage(
                                imagePath: widget.imagePath!,
                                fallback: glyph,
                              ),
                      ),
                      if (widget.tierLabel != null)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: frameColor.withValues(alpha: 0.88),
                              border: Border(
                                bottom: BorderSide(
                                  color: WuxiaUi.paper.withValues(alpha: 0.34),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Text(
                              widget.tierLabel!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: WuxiaUi.paper,
                                fontSize: 9,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (widget.leadingBadgeIcon != null)
                        Positioned(
                          top: widget.tierLabel == null ? 3 : 18,
                          left: 3,
                          child: _SlotIconBadge(
                            icon: widget.leadingBadgeIcon!,
                            color: widget.leadingBadgeColor ?? WuxiaUi.gold,
                            tooltip: widget.leadingBadgeTooltip,
                          ),
                        ),
                      if (widget.enhanceLevel > 0 ||
                          widget.trailingBadgeIcon != null)
                        Positioned(
                          top: widget.tierLabel == null ? 3 : 18,
                          right: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (widget.enhanceLevel > 0)
                                SealBadge(text: '+${widget.enhanceLevel}'),
                              if (widget.trailingBadgeIcon != null) ...[
                                if (widget.enhanceLevel > 0)
                                  const SizedBox(height: 2),
                                _SlotIconBadge(
                                  icon: widget.trailingBadgeIcon!,
                                  color:
                                      widget.trailingBadgeColor ??
                                      WuxiaUi.jiang,
                                  tooltip: widget.trailingBadgeTooltip,
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (widget.protected && widget.protectedText != null)
                        Positioned(
                          left: 3,
                          bottom: 3,
                          child: Tooltip(
                            message:
                                widget.protectedTooltip ??
                                widget.protectedText!,
                            child: SealBadge(
                              text: widget.protectedText!,
                              size: 22,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      if (widget.statusText != null)
                        Positioned(
                          right: 3,
                          bottom: 3,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: widget.protected
                                  ? widget.size - 34
                                  : widget.size - 8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: WuxiaUi.ink.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: WuxiaUi.paper.withValues(alpha: 0.48),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              widget.statusText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: WuxiaUi.paper,
                                fontSize: 9,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (_hovered && !widget.locked)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(
                              color: WuxiaUi.paper.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                      if (widget.locked)
                        Positioned.fill(
                          child: ColoredBox(
                            color: WuxiaUi.ink.withValues(alpha: 0.70),
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: WuxiaUi.jiang.withValues(alpha: 0.84),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: WuxiaUi.paper.withValues(
                                      alpha: 0.38,
                                    ),
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  widget.lockText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: WuxiaUi.paper,
                                    fontSize: 12,
                                    height: 1.15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
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
            const SizedBox(height: 5),
            Text(
              widget.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.highTier ? WuxiaUi.gold : WuxiaUi.ink,
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotIconBadge extends StatelessWidget {
  const _SlotIconBadge({required this.icon, required this.color, this.tooltip});

  final IconData icon;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.82), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: WuxiaUi.ink.withValues(alpha: 0.16),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, size: 13, color: color),
    );
    if (tooltip == null) return badge;
    return Tooltip(message: tooltip!, child: badge);
  }
}
