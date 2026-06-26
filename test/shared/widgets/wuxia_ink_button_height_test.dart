import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

/// 回归锚（2026-06-26 主菜单按钮跨列/同列高度不齐）：
///
/// 原 WuxiaInkButton 高度由 hint 行数驱动（1 行 ~76 / 2 行 ~84），有无缩略图的
/// 按钮混排时高度参差。修复让 hint 恒占 2 行高度 → 所有按钮等高，无论描述长短 /
/// 有无缩略图。
void main() {
  Future<Size> heightOf(WidgetTester tester, WuxiaInkButton button) async {
    await tester.binding.setSurfaceSize(const Size(360, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [button],
          ),
        ),
      ),
    );
    return tester.getSize(find.byType(WuxiaInkButton));
  }

  testWidgets('短描述 vs 长描述按钮等高（hint 恒占 2 行）', (tester) async {
    final short = await heightOf(
      tester,
      const WuxiaInkButton(
        label: '设置',
        hint: '调整',
        icon: Icons.settings_outlined,
        onTap: null,
      ),
    );
    final long = await heightOf(
      tester,
      const WuxiaInkButton(
        label: '主线',
        hint: '闯荡江湖逐境界精进，斩妖除魔扬名立万于天下',
        icon: Icons.map_outlined,
        onTap: null,
      ),
    );
    expect(short.height, long.height,
        reason: '短/长描述按钮应等高，避免菜单参差');
  });

  testWidgets('带缩略图 vs 纯图标按钮等高', (tester) async {
    final withThumb = await heightOf(
      tester,
      const WuxiaInkButton(
        label: '主线',
        hint: '闯荡江湖',
        icon: Icons.map_outlined,
        thumbnailPath: 'assets/ui/entries/mainline.png',
        onTap: null,
      ),
    );
    final iconOnly = await heightOf(
      tester,
      const WuxiaInkButton(
        label: '商店',
        hint: '采买炼器材料',
        icon: Icons.storefront_outlined,
        onTap: null,
      ),
    );
    expect(withThumb.height, iconOnly.height,
        reason: '带缩略图与纯图标按钮应等高');
  });
}
