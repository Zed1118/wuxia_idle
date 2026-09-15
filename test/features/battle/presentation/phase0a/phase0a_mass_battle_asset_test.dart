import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

import '../../../../support/test_data.dart';

void main() {
  test(
    'all production mass-battle standees decode with clear borders',
    () async {
      final repository = await loadTestGameRepository();
      final paths = <String>{};
      final stages = repository.stageDefs.values.where(
        (stage) => stage.stageType == StageType.massBattle,
      );
      expect(stages, hasLength(5));
      for (final stage in stages) {
        for (final enemy in stage.enemyTeam) {
          final portrait = enemy.iconPath;
          paths.add(portrait.replaceFirst('enemies/', 'enemies/battle_'));
        }
      }
      expect(paths, hasLength(15));
      final evidence = <Map<String, Object>>[];
      for (final path in paths.toList()..sort()) {
        // The existing files have .png names but contain WebP. Exercise the
        // same Flutter codec as Image.asset instead of trusting the extension.
        final codec = await ui.instantiateImageCodec(
          await File(path).readAsBytes(),
        );
        ui.Image? image;
        try {
          image = (await codec.getNextFrame()).image;
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final rgba = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          final width = image.width;
          final height = image.height;
          var left = width;
          var top = height;
          var right = -1;
          var bottom = -1;
          var visible = 0;
          for (var y = 0; y < height; y++) {
            for (var x = 0; x < width; x++) {
              if (rgba[(y * width + x) * 4 + 3] <= 8) continue;
              visible++;
              if (x < left) left = x;
              if (x > right) right = x;
              if (y < top) top = y;
              if (y > bottom) bottom = y;
            }
          }
          expect(visible, greaterThan(0), reason: path);
          expect(left, greaterThan(0), reason: path);
          expect(top, greaterThan(0), reason: path);
          expect(right, lessThan(width - 1), reason: path);
          expect(bottom, lessThan(height - 1), reason: path);
          evidence.add({
            'path': path,
            'width': width,
            'height': height,
            'visible_pixels': visible,
            'visible_bounds': [left, top, right, bottom],
          });
        } finally {
          image?.dispose();
          codec.dispose();
        }
      }
      // Pixels prove decode/transparency; full-body composition and readability
      // are checked in the real Host screenshots, not inferred from this ratio.
      debugPrint(jsonEncode({'mass_battle_asset_evidence': evidence}));
    },
  );
}
