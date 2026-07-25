import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('全部物品成品图使用真实透明底，不得烘入编辑器棋盘格', () async {
    final files =
        Directory('assets/images/items')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.png'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final violations = <String>[];

    expect(files, hasLength(14));
    for (final file in files) {
      final profile = await _readAlphaProfile(file);
      if (profile.width < 512 || profile.height < 512) {
        violations.add(
          '${file.path} · 分辨率 ${profile.width}×${profile.height} < 512×512',
        );
      }
      if (profile.maxCornerAlpha > 8) {
        violations.add(
          '${file.path} · 四角最大 alpha ${profile.maxCornerAlpha} > 8',
        );
      }
      if (profile.transparentRatio < 0.30) {
        violations.add(
          '${file.path} · 透明像素占比 '
          '${(profile.transparentRatio * 100).toStringAsFixed(1)}% < 30%',
        );
      }
      if (profile.visiblePixels == 0) {
        violations.add('${file.path} · 无可见主体');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: '物品图透明成品门禁失败：\n${violations.join('\n')}',
    );
  });
}

class _AlphaProfile {
  const _AlphaProfile({
    required this.width,
    required this.height,
    required this.maxCornerAlpha,
    required this.transparentRatio,
    required this.visiblePixels,
  });

  final int width;
  final int height;
  final int maxCornerAlpha;
  final double transparentRatio;
  final int visiblePixels;
}

Future<_AlphaProfile> _readAlphaProfile(File file) async {
  final codec = await ui.instantiateImageCodec(await file.readAsBytes());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) {
    image.dispose();
    codec.dispose();
    throw StateError('${file.path} 无法读取 RGBA 像素');
  }

  final rgba = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final width = image.width;
  final height = image.height;
  var transparentPixels = 0;
  var visiblePixels = 0;
  for (var i = 3; i < rgba.length; i += 4) {
    if (rgba[i] <= 8) {
      transparentPixels++;
    } else {
      visiblePixels++;
    }
  }

  int alphaAt(int x, int y) => rgba[(y * width + x) * 4 + 3];
  final maxCornerAlpha = [
    alphaAt(0, 0),
    alphaAt(width - 1, 0),
    alphaAt(0, height - 1),
    alphaAt(width - 1, height - 1),
  ].reduce((a, b) => a > b ? a : b);

  image.dispose();
  codec.dispose();
  return _AlphaProfile(
    width: width,
    height: height,
    maxCornerAlpha: maxCornerAlpha,
    transparentRatio: transparentPixels / (width * height),
    visiblePixels: visiblePixels,
  );
}
