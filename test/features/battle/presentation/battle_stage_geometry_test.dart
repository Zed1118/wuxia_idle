import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_stage_geometry.dart';

void main() {
  group('battleStageAnchor', () {
    test('3v3 首席靠近中场，其余两席以非对称纵深展开', () {
      final leftMain = battleStageAnchor(0, 0, 3);
      final leftSecond = battleStageAnchor(0, 1, 3);
      final leftThird = battleStageAnchor(0, 2, 3);

      expect(leftMain.dx, greaterThan(leftSecond.dx));
      expect(leftSecond.dx, greaterThan(leftThird.dx));
      expect(
        leftMain.dx - leftSecond.dx,
        isNot(closeTo(leftSecond.dx - leftThird.dx, 1e-9)),
      );
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

    test('1v1/2v2 靠近交锋区且保持前低后高层次', () {
      for (var teamSize = 1; teamSize <= 3; teamSize++) {
        final leftMain = battleStageAnchor(0, 0, teamSize);
        final rightMain = battleStageAnchor(1, 0, teamSize);
        expect(rightMain.dx - leftMain.dx, inInclusiveRange(0.20, 0.28));
      }
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

  test('1v1/2v2 自动放大主体但不反转三人阵列景深', () {
    expect(battleStageScale(0, 1), greaterThan(battleStageScale(0, 2)));
    expect(battleStageScale(0, 2), greaterThan(battleStageScale(0, 3)));
    expect(battleStageScale(0, 3), greaterThan(battleStageScale(1, 3)));
    expect(battleStageScale(1, 3), greaterThan(battleStageScale(2, 3)));
  });

  test('Boss 在相同站位面积比进入 1.25～1.45 目标带', () {
    final normal = battleStageScale(0, 3);
    final boss = battleStageScale(0, 3, isBoss: true);

    expect(boss, greaterThan(normal));
    final areaRatio = (boss / normal) * (boss / normal);
    expect(areaRatio, inInclusiveRange(1.25, 1.45));
  });
}
