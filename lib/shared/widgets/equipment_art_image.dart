import 'package:flutter/material.dart';

import '../theme/wuxia_tokens.dart';
import 'asset_fallback.dart';

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
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WuxiaUi.paper.withValues(alpha: backgroundOpacity),
        ),
        child: Padding(
          padding: padding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Image.asset(
                imagePath,
                fit: fit,
                // 源图 1024² 装备图被网格 ~80px 格全分辨率解码=4MB/张纹理,
                // 切换到图标密集页(仓库)时几十张同解致光栅丢帧(实测 raster 65ms)。
                // 按实际渲染宽×DPR 限制解码分辨率,量化到 64px 桶避免
                // ItemSlot 按压 padding 4↔5px 抖动引发每帧重解码。详情大图
                // 自动取更大 cacheWidth 保清晰,网格小图标解码量降数十倍。
                cacheWidth: _decodeCacheWidth(constraints.maxWidth, dpr),
                errorBuilder: wuxiaAssetErrorBuilder(() => fallback),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 按渲染宽×DPR 求解码宽,量化到 64px 桶;无界约束返回 null(不限制)。
  static int? _decodeCacheWidth(double maxWidth, double dpr) {
    if (!maxWidth.isFinite || maxWidth <= 0) return null;
    final physical = maxWidth * dpr;
    return (physical / 64).ceil() * 64;
  }
}
