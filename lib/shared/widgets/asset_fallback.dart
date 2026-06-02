import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 缺图 errorBuilder 工厂:release 只渲染 [fallback];
/// kDebugMode 在 fallback 上叠一个「缺图」角标(叠加不替换)。
/// 用于 sized-fallback 站点(头像/立绘框/装备详情/章节封面)——
/// 空框才显得像坏图;场景背景的隐形 fallback 不接(by-design 不显坏)。
ImageErrorWidgetBuilder wuxiaAssetErrorBuilder(Widget Function() fallback) {
  return (context, error, stackTrace) {
    final fb = fallback();
    if (!kDebugMode) return fb;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        fb,
        const Positioned(top: 0, right: 0, child: _MissingAssetBadge()),
      ],
    );
  };
}

class _MissingAssetBadge extends StatelessWidget {
  const _MissingAssetBadge();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        color: WuxiaColors.hpLow,
        child: const Text(
          '缺图',
          style: TextStyle(fontSize: 8, color: Colors.white, height: 1.0),
        ),
      ),
    );
  }
}
