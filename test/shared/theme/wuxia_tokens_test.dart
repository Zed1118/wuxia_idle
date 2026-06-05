import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

/// 母题 token 锁值测：锚定 demo :root CSS，防被随手改飘。
void main() {
  test('核心色锚定 demo :root', () {
    expect(WuxiaUi.ink, const Color(0xFF241F1A));
    expect(WuxiaUi.paper, const Color(0xFFE9DCC0));
    expect(WuxiaUi.qing, const Color(0xFF566B63));
    expect(WuxiaUi.jiang, const Color(0xFF8A2B21));
    expect(WuxiaUi.gold, const Color(0xFFB08A47));
  });

  test('资产路径指向真实 assets/ui', () {
    expect(WuxiaUi.paperBg, 'assets/ui/paper_bg.png');
    expect(WuxiaUi.sealRed, 'assets/ui/seal_red.png');
    expect(WuxiaUi.inkDivider, 'assets/ui/ink_divider.png');
  });
}
