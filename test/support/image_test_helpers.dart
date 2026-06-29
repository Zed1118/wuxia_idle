import 'package:flutter/material.dart';

/// 取 Image provider 底层 asset 名。装备/资源图经 `WuxiaImage` 的 cacheWidth
/// 优化后,provider 是 `ResizeImage` 包 `AssetImage`,直接 `as AssetImage` 会失败;
/// 此 helper 穿透 ResizeImage 取真实 assetName,供 widget 测断言用。
String? assetNameOf(ImageProvider provider) {
  final p = provider is ResizeImage ? provider.imageProvider : provider;
  return p is AssetImage ? p.assetName : null;
}

/// 判断某 Image 的 provider(穿透 ResizeImage)最终是否指向给定 asset。
bool imageIsAsset(Image image, String assetName) =>
    assetNameOf(image.image) == assetName;
