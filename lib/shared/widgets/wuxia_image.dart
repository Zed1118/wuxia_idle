import 'package:flutter/material.dart';

/// 资源图统一解码层:按实际渲染尺寸 × DPR 限制解码分辨率(`cacheWidth`),
/// 避免大源图(如 1024² 装备图 / 1952×608 心法 banner)被小格全分辨率解码——
/// 图标密集页切换时几十张同解致光栅丢帧(实测仓库 raster 65ms / 心法 75ms 尖峰)。
///
/// 安全性:量化到 64px 桶,小幅约束抖动不触发重解码;无界约束返回 null(不限制);
/// `cacheWidth ≥ 源宽` 时引擎按源宽解码(ResizeImage allowUpscaling=false),
/// 故对全屏背景(源 ≤ 显示)无副作用、零画质损失。替换 `Image.asset` 即用,
/// 参数一一对应。
class WuxiaImage extends StatelessWidget {
  const WuxiaImage(
    this.assetPath, {
    super.key,
    this.fit,
    this.errorBuilder,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode,
  });

  final String assetPath;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;
  final Color? color;
  final BlendMode? colorBlendMode;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    // 有显式宽 → 直接据其算 cacheWidth(免 LayoutBuilder,不改 intrinsic 布局)。
    if (width != null && width!.isFinite) {
      return _image(imageDecodeCacheWidth(width!, dpr));
    }
    // 否则按布局约束宽决定;无界(maxWidth=∞)→ 不限制(返回 null)。
    return LayoutBuilder(
      builder: (context, constraints) =>
          _image(imageDecodeCacheWidth(constraints.maxWidth, dpr)),
    );
  }

  Widget _image(int? cacheW) {
    return Image.asset(
      assetPath,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      cacheWidth: cacheW,
      errorBuilder: errorBuilder,
    );
  }
}

/// 渲染宽 × DPR → 解码宽,量化到 64px 桶;无界/非正返回 null(不限制)。
int? imageDecodeCacheWidth(double renderWidth, double dpr) {
  if (!renderWidth.isFinite || renderWidth <= 0) return null;
  return (renderWidth * dpr / 64).ceil() * 64;
}
