import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_stage_geometry.dart';

double _renderedAlphaArea({
  required int alphaBboxArea,
  required int sourceHeight,
  required double stageScale,
  required double opticalScale,
}) {
  // 当前战场 BoxFit.contain 在四张验收立绘上均由高度约束；公共的
  // portraitHeight 系数会在 Boss/玩家比值中约掉。
  return alphaBboxArea /
      (sourceHeight * sourceHeight) *
      stageScale *
      stageScale *
      opticalScale *
      opticalScale;
}

void main() {
  group('battleStageAnchor', () {
    test('3v3 复刻样板：我方主位在左前景，敌方主位在右中场', () {
      final leftMain = battleStageAnchor(0, 0, 3);
      final leftSecond = battleStageAnchor(0, 1, 3);
      final leftThird = battleStageAnchor(0, 2, 3);
      final rightMain = battleStageAnchor(1, 0, 3);
      final rightSecond = battleStageAnchor(1, 1, 3);
      final rightThird = battleStageAnchor(1, 2, 3);

      expect(leftMain.dx, lessThan(leftSecond.dx));
      expect(leftSecond.dx, lessThan(leftThird.dx));
      expect(rightMain.dx, lessThan(rightSecond.dx));
      expect(rightSecond.dx, lessThan(rightThird.dx));
      expect(leftMain, const Offset(0.11, 0.772));
      expect(leftSecond, const Offset(0.241, 0.592));
      expect(leftThird, const Offset(0.372, 0.436));
      expect(rightMain, const Offset(0.669, 0.521));
      expect(rightSecond, const Offset(0.79, 0.601));
      expect(rightThird, const Offset(0.908, 0.615));
    });

    test('1v1/2v2 左右同序槽位严格镜像', () {
      for (var teamSize = 1; teamSize <= 2; teamSize++) {
        for (var slot = 0; slot < teamSize; slot++) {
          final left = battleStageAnchor(0, slot, teamSize);
          final right = battleStageAnchor(1, slot, teamSize);
          expect(left.dx + right.dx, closeTo(1, 1e-9));
          expect(left.dy, closeTo(right.dy, 1e-9));
        }
      }
    });

    test('1v1/2v2 靠近交锋区且保持前低后高层次', () {
      for (var teamSize = 1; teamSize <= 2; teamSize++) {
        final leftMain = battleStageAnchor(0, 0, teamSize);
        final rightMain = battleStageAnchor(1, 0, teamSize);
        expect(rightMain.dx - leftMain.dx, inInclusiveRange(0.20, 0.28));
      }
      expect(
        battleStageAnchor(0, 0, 2).dy,
        greaterThan(battleStageAnchor(0, 1, 2).dy),
      );
    });

    test('轻功舞台保持比标准舞台更大的上下错层', () {
      final standard = [
        for (var slot = 0; slot < 3; slot++) battleStageAnchor(0, slot, 3).dy,
      ];
      final lightFoot = [
        for (var slot = 0; slot < 3; slot++)
          battleStageAnchor(
            0,
            slot,
            3,
            mode: BattleStageLayoutMode.lightFoot,
          ).dy,
      ];

      final standardSpan =
          standard.reduce((a, b) => a > b ? a : b) -
          standard.reduce((a, b) => a < b ? a : b);
      final lightFootSpan =
          lightFoot.reduce((a, b) => a > b ? a : b) -
          lightFoot.reduce((a, b) => a < b ? a : b);
      expect(lightFootSpan, greaterThan(standardSpan));
    });
  });

  test('3v3 样板状态签独立压在人物下裳,不跟随透明画布脚底漂移', () {
    expect(battleStageStatusVerticalFraction(0, 0, 3), 0.724);
    expect(battleStageStatusVerticalFraction(0, 1, 3), 0.703);
    expect(battleStageStatusVerticalFraction(0, 2, 3), 0.901);
    expect(battleStageStatusVerticalFraction(1, 0, 3), 0.745);
    expect(battleStageStatusVerticalFraction(1, 1, 3), 0.789);
    expect(battleStageStatusVerticalFraction(1, 2, 3), 0.868);
    expect(battleStageStatusVerticalFraction(0, 0, 2), 0.865);
  });

  test('样板左前景主位允许袍角越过槽位底线,其他站位不越界', () {
    expect(battleStageBottomOverflowFraction(0, 0, 3), 0.06);
    expect(battleStageBottomOverflowFraction(0, 1, 3), 0);
    expect(battleStageBottomOverflowFraction(1, 0, 3), 0);
    expect(
      battleStageBottomOverflowFraction(
        0,
        0,
        3,
        mode: BattleStageLayoutMode.lightFoot,
      ),
      0,
    );
  });

  test('1v1/2v2 自动放大主体但不反转三人阵列景深', () {
    expect(battleStageScale(0, 1), greaterThan(battleStageScale(0, 2)));
    expect(battleStageScale(0, 2), greaterThan(battleStageScale(0, 3)));
    expect(battleStageScale(0, 3), greaterThan(battleStageScale(1, 3)));
    expect(battleStageScale(1, 3), greaterThan(battleStageScale(2, 3)));
  });

  test('撑伞 Boss alpha 包围盒面积比进入 1.25～1.45 目标带', () {
    // alpha >16/255 的源图实测值：[bbox area, source height, optical scale]。
    // 三名我方按实际 3v3 景深；Boss 按 battle_boss_phase 的 1 人右队。
    final playerAreas = <double>[
      _renderedAlphaArea(
        alphaBboxArea: 1332687,
        sourceHeight: 1672,
        stageScale: battleStageScale(0, 3),
        opticalScale: 1.055,
      ),
      _renderedAlphaArea(
        alphaBboxArea: 255960,
        sourceHeight: 768,
        stageScale: battleStageScale(1, 3),
        opticalScale: 1,
      ),
      _renderedAlphaArea(
        alphaBboxArea: 178210,
        sourceHeight: 768,
        stageScale: battleStageScale(2, 3),
        opticalScale: 1,
      ),
    ]..sort();
    final bossArea = _renderedAlphaArea(
      alphaBboxArea: 221010,
      sourceHeight: 768,
      stageScale: battleStageScale(0, 1, isBoss: true),
      opticalScale: 0.81,
    );
    final areaRatio = bossArea / playerAreas[1];
    expect(areaRatio, inInclusiveRange(1.25, 1.45));
  });
}
