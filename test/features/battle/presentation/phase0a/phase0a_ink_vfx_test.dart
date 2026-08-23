import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart';

void main() {
  test('水墨 painter 帧参数从起始到中间到末段可观察变化', () {
    final startReveal = Phase0aPresentationTokens.vfxReveal(0);
    final midReveal = Phase0aPresentationTokens.vfxReveal(0.5);
    final endReveal = Phase0aPresentationTokens.vfxReveal(1);
    final startFade = Phase0aPresentationTokens.vfxFade(0);
    final midFade = Phase0aPresentationTokens.vfxFade(0.5);
    final endFade = Phase0aPresentationTokens.vfxFade(1);

    expect(startReveal, 0);
    expect(midReveal, 0.5);
    expect(endReveal, 1);
    expect(startFade, 1);
    expect(midFade, 0.5);
    expect(endFade, 0);
    expect(startReveal < midReveal && midReveal < endReveal, isTrue);
    expect(startFade > midFade && midFade > endFade, isTrue);
  });

  test('水墨层固定绘制上限不随敌人数量增长', () {
    expect(Phase0aPresentationTokens.vfxInkSplatCount, 6);
    expect(Phase0aPresentationTokens.vfxResidualStrokeCount, 2);
    expect(Phase0aPresentationTokens.vfxInkSplatCount, lessThanOrEqualTo(8));
    expect(Phase0aPresentationTokens.vfxNormalDefeatSplatCount, 12);
    expect(Phase0aPresentationTokens.vfxEliteDefeatSplatCount, 24);
    expect(
      Phase0aPresentationTokens.vfxEliteDefeatSplatCount,
      lessThanOrEqualTo(24),
    );
  });

  test('主笔锋 alpha 在起始/中间/末段单调淡出', () {
    final start = Phase0aPresentationTokens.vfxStrokeAlpha(0);
    final middle = Phase0aPresentationTokens.vfxStrokeAlpha(0.5);
    final end = Phase0aPresentationTokens.vfxStrokeAlpha(1);

    expect(start, 1);
    expect(middle, 0.5);
    expect(end, 0);
    expect(start >= middle && middle >= end, isTrue);
  });
}
