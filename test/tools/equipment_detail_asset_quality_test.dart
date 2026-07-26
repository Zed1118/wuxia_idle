import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../support/test_data.dart';

const _dedicatedDetailPaths = <String>[
  'assets/equipment/weapon_haojiahuo_suo_mai_nang_detail.png',
  'assets/equipment/armor_haojiahuo_zhen_yue_tie_yi_detail.png',
  'assets/equipment/accessory_haojiahuo_she_hun_ling_detail.png',
];
const _perceptualDuplicateAllowlistPath =
    'test/fixtures/known_equipment_detail_perceptual_duplicates.txt';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  test('装备详情素材不少于 1024 方图，且 icon/detail 不得逐字节重复', () async {
    final duplicatePairs = <String>[];
    final undersized = <String>[];

    for (final def in GameRepository.instance.equipmentDefs.values) {
      final detailPath = def.detailPath;
      if (detailPath == null) continue;

      final iconBytes = File(def.iconPath).readAsBytesSync();
      final detailBytes = File(detailPath).readAsBytesSync();
      if (_bytesEqual(iconBytes, detailBytes)) {
        duplicatePairs.add(def.id);
      }

      final image = await _decode(detailPath);
      if (image.width < 1024 || image.height < 1024) {
        undersized.add('${def.id}: ${image.width}×${image.height}');
      }
    }

    expect(
      duplicatePairs,
      isEmpty,
      reason:
          '以下装备的 icon/detail 完全重复，详情页没有独立构图：\n'
          '${duplicatePairs.join('\n')}',
    );
    expect(
      undersized,
      isEmpty,
      reason: '以下详情素材低于 1024×1024：\n${undersized.join('\n')}',
    );
  });

  test('icon/detail 感知特征不得近似相同，防止改格式后绕过重复门禁', () async {
    final nearDuplicates = <String, String>{};

    for (final def in GameRepository.instance.equipmentDefs.values) {
      final detailPath = def.detailPath;
      if (detailPath == null) continue;
      final iconHash = await _differenceHash(def.iconPath);
      final detailHash = await _differenceHash(detailPath);
      final distance = _hammingDistance(iconHash, detailHash);
      final pixelDifference = await _thumbnailDifference(
        def.iconPath,
        detailPath,
      );
      if (distance <= 3 && pixelDifference <= 0.035) {
        nearDuplicates[def.id] =
            'dHash=$distance, pixel=${pixelDifference.toStringAsFixed(4)}';
      }
    }

    final allowlist = _loadIdAllowlist(_perceptualDuplicateAllowlistPath);
    final offenders = nearDuplicates.keys.toSet().difference(allowlist).toList()
      ..sort();
    final stale = allowlist.difference(nearDuplicates.keys.toSet()).toList()
      ..sort();
    expect(
      offenders,
      isEmpty,
      reason:
          '以下 icon/detail 构图过于接近且未登记'
          '（dHash ≤ 3 且缩略图差异 ≤ 3.5%）：\n'
          '${offenders.map((id) => '$id: ${nearDuplicates[id]}').join('\n')}',
    );
    expect(
      stale,
      isEmpty,
      reason: '以下近似重复基线已修复，请从 allowlist 清账：\n${stale.join('\n')}',
    );
  });

  test('新增专用详情图具备透明安全边、合理主体占比与明暗层次', () async {
    final failures = <String>[];

    for (final path in _dedicatedDetailPaths) {
      final image = await _decode(path, width: 256, height: 256);
      final metrics = _detailMetrics(image);
      if (metrics.cornerMaxAlpha > 8) {
        failures.add('$path: 角点不透明 alpha=${metrics.cornerMaxAlpha}');
      }
      if (metrics.visibleCoverage < 0.22 || metrics.visibleCoverage > 0.58) {
        failures.add(
          '$path: 主体占比 ${metrics.visibleCoverage.toStringAsFixed(3)}',
        );
      }
      if (metrics.luminanceSpread < 0.18) {
        failures.add(
          '$path: 明暗层次 ${metrics.luminanceSpread.toStringAsFixed(3)}',
        );
      }
      if (metrics.chromaGreenRatio > 0.006) {
        failures.add(
          '$path: 疑似色键残边 ${metrics.chromaGreenRatio.toStringAsFixed(4)}',
        );
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}

Future<_DecodedImage> _decode(String path, {int? width, int? height}) async {
  final codec = await ui.instantiateImageCodec(
    File(path).readAsBytesSync(),
    targetWidth: width,
    targetHeight: height,
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  final decoded = _DecodedImage(
    width: image.width,
    height: image.height,
    rgba: Uint8List.fromList(bytes),
  );
  image.dispose();
  codec.dispose();
  return decoded;
}

Future<int> _differenceHash(String path) async {
  final image = await _decode(path, width: 9, height: 8);
  var hash = 0;
  var bit = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width - 1; x++) {
      final left = _paperCompositeLuminance(image, x, y);
      final right = _paperCompositeLuminance(image, x + 1, y);
      if (left > right) hash |= 1 << bit;
      bit++;
    }
  }
  return hash;
}

int _paperCompositeLuminance(_DecodedImage image, int x, int y) {
  final offset = (y * image.width + x) * 4;
  final alpha = image.rgba[offset + 3] / 255;
  const paper = 232;
  final red = image.rgba[offset] * alpha + paper * (1 - alpha);
  final green = image.rgba[offset + 1] * alpha + paper * (1 - alpha);
  final blue = image.rgba[offset + 2] * alpha + paper * (1 - alpha);
  return (red * 299 + green * 587 + blue * 114).round();
}

Future<double> _thumbnailDifference(String leftPath, String rightPath) async {
  final left = await _decode(leftPath, width: 32, height: 32);
  final right = await _decode(rightPath, width: 32, height: 32);
  var difference = 0.0;
  for (var offset = 0; offset < left.rgba.length; offset += 4) {
    final leftAlpha = left.rgba[offset + 3] / 255;
    final rightAlpha = right.rgba[offset + 3] / 255;
    for (var channel = 0; channel < 3; channel++) {
      final leftValue =
          left.rgba[offset + channel] * leftAlpha + 232 * (1 - leftAlpha);
      final rightValue =
          right.rgba[offset + channel] * rightAlpha + 232 * (1 - rightAlpha);
      difference += (leftValue - rightValue).abs() / 255;
    }
  }
  return difference / (32 * 32 * 3);
}

_DetailMetrics _detailMetrics(_DecodedImage image) {
  var visible = 0;
  var opaque = 0;
  var chromaGreen = 0;
  final luminances = <double>[];
  var cornerMaxAlpha = 0;
  final cornerOffsets = <int>[
    3,
    (image.width - 1) * 4 + 3,
    ((image.height - 1) * image.width) * 4 + 3,
    ((image.height * image.width) - 1) * 4 + 3,
  ];
  for (final offset in cornerOffsets) {
    cornerMaxAlpha = cornerMaxAlpha < image.rgba[offset]
        ? image.rgba[offset]
        : cornerMaxAlpha;
  }

  for (var offset = 0; offset < image.rgba.length; offset += 4) {
    final red = image.rgba[offset];
    final green = image.rgba[offset + 1];
    final blue = image.rgba[offset + 2];
    final alpha = image.rgba[offset + 3];
    if (alpha > 24) visible++;
    if (alpha > 200) {
      opaque++;
      luminances.add((red * 299 + green * 587 + blue * 114) / 255000);
      if (green > 150 && green > red * 1.8 && green > blue * 1.4) {
        chromaGreen++;
      }
    }
  }

  luminances.sort();
  final low = luminances[(luminances.length * 0.1).floor()];
  final high = luminances[(luminances.length * 0.9).floor()];
  return _DetailMetrics(
    cornerMaxAlpha: cornerMaxAlpha,
    visibleCoverage: visible / (image.width * image.height),
    luminanceSpread: high - low,
    chromaGreenRatio: opaque == 0 ? 0 : chromaGreen / opaque,
  );
}

int _hammingDistance(int left, int right) {
  var value = left ^ right;
  var count = 0;
  while (value != 0) {
    value &= value - 1;
    count++;
  }
  return count;
}

bool _bytesEqual(Uint8List left, Uint8List right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

Set<String> _loadIdAllowlist(String path) {
  return File(path)
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}

class _DecodedImage {
  const _DecodedImage({
    required this.width,
    required this.height,
    required this.rgba,
  });

  final int width;
  final int height;
  final Uint8List rgba;
}

class _DetailMetrics {
  const _DetailMetrics({
    required this.cornerMaxAlpha,
    required this.visibleCoverage,
    required this.luminanceSpread,
    required this.chromaGreenRatio,
  });

  final int cornerMaxAlpha;
  final double visibleCoverage;
  final double luminanceSpread;
  final double chromaGreenRatio;
}
