import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_stage_geometry.dart';

void main() {
  group('battleStageAnchor', () {
    test('3v3 首席靠近中场，其余两席向外展开', () {
      final leftMain = battleStageAnchor(0, 0, 3);
      final leftSecond = battleStageAnchor(0, 1, 3);
      final leftThird = battleStageAnchor(0, 2, 3);

      expect(leftMain.dx, greaterThan(leftSecond.dx));
      expect(leftSecond.dx, greaterThan(leftThird.dx));
    });

    test('1v1/2v2/3v3 左右同序槽位严格镜像', () {
      for (var teamSize = 1; teamSize <= 3; teamSize++) {
        for (var slot = 0; slot < teamSize; slot++) {
          final left = battleStageAnchor(0, slot, teamSize);
          final right = battleStageAnchor(1, slot, teamSize);
          expect(left.dx + right.dx, closeTo(1, 1e-9));
          expect(left.dy, closeTo(right.dy, 1e-9));
        }
      }
    });

    test('1v1 居中对峙，2v2 保持前低后高层次', () {
      expect(battleStageAnchor(0, 0, 1).dy, closeTo(0.53, 1e-9));
      expect(
        battleStageAnchor(0, 0, 2).dy,
        greaterThan(battleStageAnchor(0, 1, 2).dy),
      );
    });

    test('轻功舞台扩大上下错层与向中央位移距离', () {
      final standardTop = battleStageAnchor(0, 1, 3);
      final lightFootTop = battleStageAnchor(
        0,
        1,
        3,
        mode: BattleStageLayoutMode.lightFoot,
      );
      final standardBottom = battleStageAnchor(0, 2, 3);
      final lightFootBottom = battleStageAnchor(
        0,
        2,
        3,
        mode: BattleStageLayoutMode.lightFoot,
      );

      expect(lightFootTop.dx, lessThan(standardTop.dx));
      expect(lightFootTop.dy, lessThan(standardTop.dy));
      expect(lightFootBottom.dy, greaterThan(standardBottom.dy));
    });
  });

  test('Boss 在相同站位比普通角色大一档', () {
    final normal = battleStageScale(0, 3);
    final boss = battleStageScale(0, 3, isBoss: true);

    expect(boss, greaterThan(normal));
    expect(boss / normal, closeTo(1.22, 1e-9));
  });
}
