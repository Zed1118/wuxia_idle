import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../theme/wuxia_tokens.dart';
import '../asset_fallback.dart';
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
                    ? const [
                        BoxShadow(
                          color: Color(0x66B08A47),
                          blurRadius: 8,
                        ),
                      ]
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
                        : Image.asset(
                            imagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: wuxiaAssetErrorBuilder(() => glyph),
                          ),
                  ),
                  if (enhanceLevel > 0)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: SealBadge(text: '+$enhanceLevel'),
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
