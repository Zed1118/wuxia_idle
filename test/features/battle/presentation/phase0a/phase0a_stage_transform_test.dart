import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_stage.dart';

Phase0aActor _actor(String id, double x, double y) => Phase0aActor(
  id: id,
  side: Phase0aSide.enemy,
  position: ArenaVector(x, y),
  facing: ArenaVector.zero,
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 0,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

void main() {
  const viewports = [Size(1280, 720), Size(1440, 900)];

  group('Phase0aStage 世界→屏幕变换', () {
    for (final viewport in viewports) {
      test('世界四角映射后落在 safeRect 内 (${viewport.width}x${viewport.height})', () {
        final stage = Phase0aStage(viewport: viewport);
        final corners = [
          stage.worldMin,
          ArenaVector(stage.worldMax.x, stage.worldMin.y),
          ArenaVector(stage.worldMin.x, stage.worldMax.y),
          stage.worldMax,
        ];
        for (final corner in corners) {
          final screen = stage.worldToScreen(corner);
          expect(
            stage.safeRect.contains(screen),
            isTrue,
            reason: 'corner $corner -> $screen 应在 ${stage.safeRect} 内',
          );
        }
      });
    }

    test('world y 越大,screen y 与 depthScale 越大', () {
      for (final viewport in viewports) {
        final stage = Phase0aStage(viewport: viewport);
        const x = 100.0;
        const ys = [0.0, 50.0, 100.0, 200.0];
        double? prevScreenY;
        double? prevScale;
        for (final y in ys) {
          final screen = stage.worldToScreen(ArenaVector(x, y));
          final scale = stage.depthScale(y);
          if (prevScreenY != null) {
            expect(screen.dy, greaterThan(prevScreenY));
            expect(scale, greaterThan(prevScale!));
          }
          prevScreenY = screen.dy;
          prevScale = scale;
        }
      }
    });

    test('x 顺序保持:世界 x 越大屏幕 x 越大', () {
      for (final viewport in viewports) {
        final stage = Phase0aStage(viewport: viewport);
        const y = 120.0;
        const xs = [-200.0, -50.0, 0.0, 77.0, 300.0];
        double? prevScreenX;
        for (final x in xs) {
          final screen = stage.worldToScreen(ArenaVector(x, y));
          if (prevScreenX != null) {
            expect(screen.dx, greaterThan(prevScreenX));
          }
          prevScreenX = screen.dx;
        }
      }
    });
  });

  group('Phase0aStage 排序', () {
    List<Phase0aActor> actors() => [
      _actor('b', 0, 10),
      _actor('a', 0, 10),
      _actor('c', 0, 5),
      _actor('d', 0, 20),
    ];

    test('按 y 升序、y 相同按 id 稳定排序', () {
      final stage = Phase0aStage(viewport: viewports.first);
      final sorted = stage.sortActors(actors());
      expect(sorted.map((a) => a.id).toList(), ['c', 'a', 'b', 'd']);
    });

    test('相同输入结果确定:两次排序逐元素一致', () {
      final stage = Phase0aStage(viewport: viewports.first);
      final first = stage.sortActors(actors());
      final second = stage.sortActors(actors());
      expect(first.map((a) => a.id), second.map((a) => a.id));
    });
  });
}
