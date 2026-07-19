import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_layout_tokens.dart';

void main() {
  group('BattleLayoutMetrics', () {
    for (final viewport in const [Size(1280, 720), Size(1440, 900)]) {
      test(
        '${viewport.width.toInt()}×${viewport.height.toInt()} 三段比例落在目标带',
        () {
          final metrics = BattleLayoutMetrics.resolve(viewport);

          expect(
            metrics.headerHeight / viewport.height,
            inInclusiveRange(0.06, 0.07),
          );
          expect(
            metrics.battlefieldHeight / viewport.height,
            inInclusiveRange(0.67, 0.69),
          );
          expect(
            metrics.commandDeskHeight / viewport.height,
            inInclusiveRange(0.24, 0.26),
          );
          expect(
            metrics.headerHeight +
                metrics.battlefieldHeight +
                metrics.commandDeskHeight,
            closeTo(viewport.height, 0.01),
          );
        },
      );

      test(
        '${viewport.width.toInt()}×${viewport.height.toInt()} 自动与点选案台同权重',
        () {
          final metrics = BattleLayoutMetrics.resolve(viewport);

          expect(metrics.autoRotationDeskHeight, metrics.commandDeskHeight);
          expect(
            metrics.autoRotationDeskHeight / viewport.height,
            inInclusiveRange(0.24, 0.26),
          );
        },
      );

      test(
        '${viewport.width.toInt()}×${viewport.height.toInt()} 案台三段宽度落在目标带',
        () {
          final metrics = BattleLayoutMetrics.resolve(viewport);

          expect(
            metrics.focusRailWidth / viewport.width,
            inInclusiveRange(0.18, 0.20),
          );
          expect(
            metrics.skillRailWidth / viewport.width,
            inInclusiveRange(0.58, 0.62),
          );
          expect(
            metrics.pouchRailWidth / viewport.width,
            inInclusiveRange(0.20, 0.22),
          );
        },
      );
    }

    test('Windows 1080p 三档显示缩放保持三段闭合与案台横向可用', () {
      for (final scale in const [1.0, 1.25, 1.5]) {
        final viewport = const Size(1920, 1080) / scale;
        final metrics = BattleLayoutMetrics.resolve(viewport);

        expect(
          metrics.headerHeight,
          inInclusiveRange(
            BattleLayoutTokens.headerMinHeight,
            BattleLayoutTokens.headerMaxHeight,
          ),
        );
        expect(
          metrics.commandDeskHeight,
          inInclusiveRange(
            BattleLayoutTokens.commandDeskMinHeight,
            BattleLayoutTokens.commandDeskMaxHeight,
          ),
        );
        expect(metrics.battlefieldHeight, greaterThan(0));
        expect(
          metrics.headerHeight +
              metrics.battlefieldHeight +
              metrics.commandDeskHeight,
          closeTo(viewport.height, 0.01),
        );
        expect(metrics.skillRailWidth, greaterThan(0));
        expect(
          metrics.focusRailWidth +
              metrics.skillRailWidth +
              metrics.pouchRailWidth,
          lessThan(viewport.width),
        );
      }
    });
  });
}
