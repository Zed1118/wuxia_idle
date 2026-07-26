import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/wuxia_tokens.dart';
import '../utils/asset_framing.dart';
import 'asset_fallback.dart';
import 'wuxia_image.dart';

/// 统一立绘框(sect 成员行 / 招募 dialog / debug 列表共用 · DRY)。
///
/// [portraitPath] 为 null 时:
///   - 给了 [placeholderShapePath] → 以透明站姿 alpha 绘制纯墨身份剪影，并以
///     姓名首字作小印；不展示该站姿原人物的肤色、衣纹或五官；
///   - 给了 [placeholderText](角色名)→ 居中首字水墨题字占位(替空框,沿
///     battle CharacterAvatar 首字降级体例,守 legacy / 未绑定立绘角色);
///   - 否则 → [SizedBox.shrink] 不占位(匿名场景,不破布局)。
/// 加载失败走 errorBuilder → avatarFill 底(memory feedback_image_asset_error_builder)。
class PortraitFrame extends StatelessWidget {
  const PortraitFrame({
    super.key,
    required this.portraitPath,
    required this.size,
    required this.borderColor,
    this.placeholderText,
    this.placeholderShapePath,
    this.fit = BoxFit.cover,
    this.alignment,
  });

  final String? portraitPath;
  final double size;
  final Color borderColor;
  final BoxFit fit;
  final AlignmentGeometry? alignment;

  /// null 立绘时的首字水墨占位文本(通常传角色名)。为 null 则不占位。
  final String? placeholderText;

  /// null/坏图时可选的透明站姿外形。仅消费 alpha 形状并统一染墨，不冒充肖像。
  final String? placeholderShapePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        color: WuxiaColors.avatarFill,
      ),
      alignment: Alignment.center,
      child: portraitPath == null
          ? _placeholder()
          : WuxiaImage(
              portraitPath!,
              fit: fit,
              alignment:
                  alignment ?? assetFramingForPortrait(portraitPath!).alignment,
              errorBuilder: wuxiaAssetErrorBuilder(
                () => Container(
                  color: WuxiaColors.avatarFill,
                  alignment: Alignment.center,
                  child: _placeholder(),
                ),
              ),
            ),
    );
  }

  Widget _placeholder() {
    final text = placeholderText;
    if (text == null || text.characters.isEmpty) {
      return const SizedBox.shrink();
    }
    final firstGlyph = text.characters.first;
    final shapePath = placeholderShapePath;
    if (shapePath != null && shapePath.isNotEmpty) {
      return _InkSilhouettePortrait(
        shapePath: shapePath,
        size: size,
        accent: borderColor,
        firstGlyph: firstGlyph,
      );
    }
    return _PortraitGlyph(firstGlyph: firstGlyph, size: size);
  }
}

class _InkSilhouettePortrait extends StatelessWidget {
  const _InkSilhouettePortrait({
    required this.shapePath,
    required this.size,
    required this.accent,
    required this.firstGlyph,
  });

  final String shapePath;
  final double size;
  final Color accent;
  final String firstGlyph;

  @override
  Widget build(BuildContext context) {
    final sealSize = size * 0.34;
    return ClipRect(
      child: Stack(
        key: const ValueKey('portraitFrame.inkSilhouette'),
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: WuxiaUi.paper2),
          WuxiaImage(
            shapePath,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            color: WuxiaUi.ink2.withValues(alpha: 0.84),
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: wuxiaAssetErrorBuilder(
              () => _PortraitGlyph(firstGlyph: firstGlyph, size: size),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: ExcludeSemantics(
              child: Container(
                width: sealSize,
                height: sealSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WuxiaUi.jiang.withValues(alpha: 0.84),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.82),
                    width: 1,
                  ),
                ),
                child: Text(
                  firstGlyph,
                  style: TextStyle(
                    color: WuxiaUi.paper,
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitGlyph extends StatelessWidget {
  const _PortraitGlyph({required this.firstGlyph, required this.size});

  final String firstGlyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      firstGlyph,
      style: TextStyle(
        fontSize: size * 0.42,
        color: WuxiaColors.textPrimary,
        fontWeight: FontWeight.bold,
        height: 1,
      ),
    );
  }
}
