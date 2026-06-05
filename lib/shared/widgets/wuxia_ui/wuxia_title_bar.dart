import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';

/// 宣纸顶栏（UI kit · demo `.titlebar`）：替 Material AppBar。
///
/// 纸色渐变底 + 墨色底边 + 卷轴题字标题；[onBack] 非空显绛红返回钮，
/// [showSeal] 为真右侧贴朱印。实现 [PreferredSizeWidget] 可直接挂 Scaffold.appBar。
class WuxiaTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const WuxiaTitleBar({
    super.key,
    required this.title,
    this.onBack,
    this.showSeal = true,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showSeal;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFE3C7), Color(0xFFE0CEA6)],
        ),
        border: Border(bottom: BorderSide(color: WuxiaUi.ink, width: 2)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            InkWell(
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.subdirectory_arrow_left,
                  color: WuxiaUi.jiang,
                  size: 22,
                ),
              ),
            ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
          ),
          if (showSeal)
            SizedBox(
              width: 30,
              height: 30,
              child: Image.asset(
                WuxiaUi.sealRed,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
