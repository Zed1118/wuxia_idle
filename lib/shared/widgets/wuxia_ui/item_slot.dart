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
class ItemSlot extends StatelessWidget {
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
    this.statusText,
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
  final String? statusText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final frameColor = highTier ? WuxiaUi.gold : WuxiaUi.ink;
    final glyph = EquipGlyph(tierColor: tierColor, slot: equipmentSlot);
    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(5),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: WuxiaUi.slotFill,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: frameColor, width: 2),
                boxShadow: highTier
                    ? const [BoxShadow(color: Color(0x66B08A47), blurRadius: 8)]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: imagePath == null
                        ? glyph
                        : EquipmentArtImage(
                            imagePath: imagePath!,
                            fallback: glyph,
                          ),
                  ),
                  if (leadingBadgeIcon != null)
                    Positioned(
                      top: 2,
                      left: 2,
                      child: _SlotIconBadge(
                        icon: leadingBadgeIcon!,
                        color: leadingBadgeColor ?? WuxiaUi.gold,
                      ),
                    ),
                  if (enhanceLevel > 0 || trailingBadgeIcon != null)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (enhanceLevel > 0)
                            SealBadge(text: '+$enhanceLevel'),
                          if (trailingBadgeIcon != null) ...[
                            if (enhanceLevel > 0) const SizedBox(height: 2),
                            _SlotIconBadge(
                              icon: trailingBadgeIcon!,
                              color: trailingBadgeColor ?? WuxiaUi.jiang,
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (statusText != null)
                    Positioned(
                      right: 3,
                      bottom: 3,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: size - 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: WuxiaUi.ink.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: WuxiaUi.paper.withValues(alpha: 0.45),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          statusText!,
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
                  if (locked)
                    Positioned.fill(
                      child: ColoredBox(
                        color: const Color(0x9E282218),
                        child: Center(
                          child: Text(
                            lockText,
                            style: const TextStyle(
                              color: WuxiaUi.paper,
                              fontSize: 13,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highTier ? WuxiaUi.gold : WuxiaUi.ink,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotIconBadge extends StatelessWidget {
  const _SlotIconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.75), width: 0.8),
      ),
      child: Icon(icon, size: 13, color: color),
    );
  }
}
