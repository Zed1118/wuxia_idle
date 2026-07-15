import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_stage_geometry.dart';

void main() {
  group('battleStageAnchor', () {
    test('3v3 主位靠近中场，两后位形成斜向阵列', () {
      final leftMain = battleStageAnchor(0, 0, 3);
      final leftRearTop = battleStageAnchor(0, 1, 3);
      final leftRearBottom = battleStageAnchor(0, 2, 3);

      expect(leftMain.dx, greaterThan(leftRearTop.dx));
      expect(leftMain.dx, greaterThan(leftRearBottom.dx));
      expect(leftRearTop.dy, lessThan(leftMain.dy));
      expect(leftRearBottom.dy, greaterThan(leftMain.dy));
    });

    test('右队与左队关于战场中线镜像', () {
      for (var teamSize = 1; teamSize <= 3; teamSize++) {
        for (var slot = 0; slot < teamSize; slot++) {
          final left = battleStageAnchor(0, slot, teamSize);
          final right = battleStageAnchor(1, slot, teamSize);
          expect(left.dx + right.dx, closeTo(1, 1e-9));
          expect(left.dy, closeTo(right.dy, 1e-9));
        }
      }
    });

    test('1v1 居中对峙，2v2 保持上下层次', () {
      expect(battleStageAnchor(0, 0, 1).dy, closeTo(0.52, 1e-9));
      expect(
        battleStageAnchor(0, 0, 2).dy,
        lessThan(battleStageAnchor(0, 1, 2).dy),
      );
    });
  });

  test('Boss 在相同站位比普通角色大一档', () {
    final normal = battleStageScale(0, 3);
    final boss = battleStageScale(0, 3, isBoss: true);

    expect(boss, greaterThan(normal));
    expect(boss / normal, closeTo(1.12, 1e-9));
  });
}
