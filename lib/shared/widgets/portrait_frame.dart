import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 统一立绘框(sect 成员行 / 招募 dialog / debug 列表共用 · DRY)。
///
/// [portraitPath] 为 null 时退 [SizedBox.shrink] 不占位(不破布局)。
/// 加载失败走 errorBuilder → avatarFill 底(memory feedback_image_asset_error_builder)。
class PortraitFrame extends StatelessWidget {
  const PortraitFrame({
    super.key,
    required this.portraitPath,
    required this.size,
    required this.borderColor,
  });

  final String? portraitPath;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        color: WuxiaColors.avatarFill,
      ),
      child: portraitPath == null
          ? const SizedBox.shrink()
          : Image.asset(
              portraitPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: WuxiaColors.avatarFill),
            ),
    );
  }
}
