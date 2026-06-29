import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/equipment_art_image.dart';

/// 性能回归:装备图须按渲染尺寸限制解码分辨率(cacheWidth),
/// 不得按 1024² 源图全解码——否则图标密集页(仓库网格)切换时几十张
/// 同时全分辨率解码上传致光栅丢帧(实测 raster 65ms 尖峰)。
void main() {
  Future<ResizeImage> pumpAndGetProvider(WidgetTester tester, double box) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: box,
              height: box,
              child: const EquipmentArtImage(
                imagePath: 'assets/equipment/weapon_x.png',
                fallback: SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
    final img = tester.widget<Image>(find.byType(Image));
    return img.image as ResizeImage;
  }

  testWidgets('小格图标按渲染尺寸解码(远小于 1024 源)', (tester) async {
    final resize = await pumpAndGetProvider(tester, 80);
    expect(resize.width, isNotNull);
    // 80 逻辑 × dpr(3.0 测试默认) = 240 → 量化 256;无论如何须 ≪ 1024。
    expect(resize.width! <= 512, isTrue,
        reason: '小格解码宽 ${resize.width} 应远小于 1024 源图');
  });

  testWidgets('大图(详情 hero)解码宽随渲染尺寸放大保清晰', (tester) async {
    final small = await pumpAndGetProvider(tester, 80);
    final large = await pumpAndGetProvider(tester, 400);
    expect(large.width! > small.width!, isTrue,
        reason: '大尺寸渲染应取更大 cacheWidth(${large.width}) > 小格(${small.width})');
  });
}
