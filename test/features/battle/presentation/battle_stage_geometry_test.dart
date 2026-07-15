import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_stage_geometry.dart';

void main() {
  group('battleStageAnchor', () {
    test('3v3 我方主位压低前景，两名弟子向中场抬高展开', () {
      final leftMain = battleStageAnchor(0, 0, 3);
      final leftRearTop = battleStageAnchor(0, 1, 3);
      final leftRearBottom = battleStageAnchor(0, 2, 3);

      expect(leftMain.dx, lessThan(leftRearTop.dx));
      expect(leftRearTop.dx, lessThan(leftRearBottom.dx));
      expect(leftRearTop.dy, lessThan(leftMain.dy));
      expect(leftRearBottom.dy, lessThan(leftRearTop.dy));
    });

    test('1v1/2v2 保持镜像，3v3 敌方主位前压形成非对称对峙', () {
      for (var teamSize = 1; teamSize <= 2; teamSize++) {
        for (var slot = 0; slot < teamSize; slot++) {
          final left = battleStageAnchor(0, slot, teamSize);
          final right = battleStageAnchor(1, slot, teamSize);
          expect(left.dx + right.dx, closeTo(1, 1e-9));
          expect(left.dy, closeTo(right.dy, 1e-9));
        }
      }
      final rightMain = battleStageAnchor(1, 0, 3);
      final rightRear = battleStageAnchor(1, 2, 3);
      expect(rightMain.dx, lessThan(rightRear.dx));
      expect(rightMain.dy, lessThan(rightRear.dy));
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
