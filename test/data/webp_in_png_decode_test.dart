import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// webp-in-png 解码守卫(2026-07-02 资产瘦身批)。
///
/// 背景:资产瘦身把 210MB PNG 有损转 webp(q80)以缩小分发包,但为避免改动
/// 475 处 `.png` 引用(lib 101 + data 374)+ 漏改即运行期资产静默缺失,采用
/// **保留 .png 文件名、内容替换为 webp 编码**方案。Flutter 的 `AssetImage`
/// 读取文件 bytes 后交 skia codec,解码按内容 magic bytes 嗅探而非扩展名,
/// 故 .png 名装 webp 内容可正常解码,引用层零改动。
///
/// 本测端到端证明该机制:经 rootBundle 按 .png 路径读到 webp bytes →
/// `instantiateImageCodec` 解出正确尺寸的图像。若某日 flutter/skia 变更
/// 不再嗅探 webp,或误把某张转回真 PNG 语义,此测会红,守住方案前提。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('webp 内容的 .png asset 可经 rootBundle 加载并被 skia 解码', () async {
    final data = await rootBundle.load('assets/characters/founder.png');
    final bytes = data.buffer.asUint8List();

    // 内容确为 webp(RIFF....WEBP),证明文件名 .png 与内容格式解耦。
    expect(bytes.length, greaterThan(12));
    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');

    // skia 按内容嗅探解码,尺寸须与原图一致(896x1344)。
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 896);
    expect(frame.image.height, 1344);
  });

  test('桃花岛显式 .webp asset 可加载且尺寸保持 1456x816', () async {
    final data = await rootBundle.load('assets/maps/taohuaIsland.webp');
    final bytes = data.buffer.asUint8List();

    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 1456);
    expect(frame.image.height, 816);
  });
}
