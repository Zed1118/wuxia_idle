import 'package:flutter/material.dart';

import '../theme/wuxia_tokens.dart';
import 'asset_fallback.dart';
import 'wuxia_image.dart';

/// 装备图渲染在宣纸面板上(G2.2 抠白底)。
///
/// 装备图已抠白底透明:透明成品浮在面板上,无矩形浅底块色差;
/// 整幅水墨场景图(背景即画面)保留不透明,在详情 hero 里自然渲染成装裱画
/// —— alpha 通道天然路由两类,无需额外标记。旧 `BlendMode.multiply` 染底
/// hack 已去除(白底染 paper2 不透明矩形与面板半透底色差是 G2.2 病根)。
class EquipmentArtImage extends StatelessWidget {
  const EquipmentArtImage({
    super.key,
    required this.imagePath,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 3,
    this.backgroundOpacity = 0.08,
  });

  final String imagePath;
  final Widget fallback;
  final BoxFit fit;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double backgroundOpacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WuxiaUi.paper.withValues(alpha: backgroundOpacity),
        ),
        child: Padding(
          padding: padding,
          // 经 WuxiaImage 按渲染尺寸限制解码(网格小图标降数十倍解码量,
          // 详情大图自动取更大 cacheWidth 保清晰)。见 wuxia_image.dart。
          child: WuxiaImage(
            imagePath,
            fit: fit,
            errorBuilder: wuxiaAssetErrorBuilder(() => fallback),
          ),
        ),
      ),
    );
  }
}
