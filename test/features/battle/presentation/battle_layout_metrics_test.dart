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
            inInclusiveRange(0.15, 0.17),
          );
          expect(
            metrics.skillRailWidth / viewport.width,
            inInclusiveRange(0.51, 0.55),
          );
          expect(
            metrics.pouchRailWidth / viewport.width,
            inInclusiveRange(0.19, 0.21),
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

    test('1672×941 黄金样板分界落在 y=700±1', () {
      final metrics = BattleLayoutMetrics.resolve(const Size(1672, 941));

      expect(metrics.headerHeight, 60);
      expect(
        metrics.headerHeight + metrics.battlefieldHeight,
        inInclusiveRange(699, 701),
      );
      expect(metrics.commandDeskHeight, inInclusiveRange(240, 242));
    });

    test('矮视口为脚底放大立绘预留顶部安全距，黄金视口不偏移', () {
      expect(
        BattleLayoutMetrics.resolve(const Size(1280, 720)).stageTopSafetyInset,
        40,
      );
      expect(
        BattleLayoutMetrics.resolve(const Size(1440, 900)).stageTopSafetyInset,
        0,
      );
      expect(
        BattleLayoutMetrics.resolve(const Size(1672, 941)).stageTopSafetyInset,
        0,
      );
    });
  });
}
