import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'asset_fallback.dart';

/// 统一立绘框(sect 成员行 / 招募 dialog / debug 列表共用 · DRY)。
///
/// [portraitPath] 为 null 时:
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
    this.fit = BoxFit.cover,
  });

  final String? portraitPath;
  final double size;
  final Color borderColor;
  final BoxFit fit;

  /// null 立绘时的首字水墨占位文本(通常传角色名)。为 null 则不占位。
  final String? placeholderText;

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
          : Image(
              image: ExactAssetImage(
                portraitPath!,
                bundle: DefaultAssetBundle.of(context),
              ),
              fit: fit,
              errorBuilder: wuxiaAssetErrorBuilder(
                () => Container(color: WuxiaColors.avatarFill),
              ),
            ),
    );
  }

  Widget _placeholder() {
    final text = placeholderText;
    if (text == null || text.characters.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      text.characters.first,
      style: TextStyle(
        fontSize: size * 0.42,
        color: WuxiaColors.textPrimary,
        fontWeight: FontWeight.bold,
        height: 1,
      ),
    );
  }
}
